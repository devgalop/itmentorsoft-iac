# Arquitectura Detallada - ITMentorSoft IaC

Documento de referencia tecnica de la infraestructura de ITMentorSoft en AWS. Este documento describe en detalle cada componente, su configuracion y las decisiones de diseno tomadas.

## Tabla de contenidos

- [Vision general](#vision-general)
- [Diagrama de arquitectura](#diagrama-de-arquitectura)
- [Red (Network)](#red-network)
- [Seguridad](#seguridad)
- [Capa de computo (ECS Fargate)](#capa-de-computo-ecs-fargate)
- [Capa de datos](#capa-de-datos)
- [Cola de mensajes (SQS)](#cola-de-mensajes-sqs)
- [Registro de contenedores (ECR)](#registro-de-contenedores-ecr)
- [API Gateway](#api-gateway)
- [Estrategia de despliegue](#estrategia-de-despliegue)
- [Flujo de datos](#flujo-de-datos)
- [Consideraciones de escalabilidad](#consideraciones-de-escalabilidad)
- [Optimizacion de costos](#optimizacion-de-costos)

---

## Vision general

La infraestructura de IT Mentor Soft opera en una sola region AWS (`us-east-1`) y sigue un patron de arquitectura en capas dentro de una VPC aislada. Los servicios se ejecutan en contenedores Fargate, la base de datos es PostgreSQL gestionado (RDS), el cache es Valkey (ElastiCache) y la comunicacion asincrona se realiza mediante colas SQS.

**Principios de diseno:**

- Aislamiento de red por capas (publica, aplicacion, datos)
- Minimo privilegio en Security Groups
- Cifrado en reposo y en transito
- Autoscaling basado en demanda real
- Separacion de estados por workspace de Terraform
- Costo optimizado para entorno de desarrollo

---

## Diagrama de arquitectura

```
+========================================================================+
|                          AWS us-east-1                                  |
|                                                                         |
|  +-------------------------------------------------------------------+ |
|  |                   VPC: 192.168.0.0/24                              | |
|  |                   DNS: habilitado                                  | |
|  |                                                                    | |
|  |  +-------------------------------------------------------------+  | |
|  |  |  CAPA PUBLICA - Subnets Publicas (2x /27)                   |  | |
|  |  |                                                             |  | |
|  |  |  us-east-1a: 192.168.0.0/27    us-east-1c: 192.168.0.32/27 |  | |
|  |  |                                                             |  | |
|  |  |  [Internet Gateway]  <----->  [NAT Gateway + EIP]          |  | |
|  |  |                                                             |  | |
|  |  |  Ruta: 0.0.0.0/0 --> igw-xxx                                |  | |
|  |  +-------------------------------------------------------------+  | |
|  |           |                                          |              | |
|  |           v (trafico entrante)                       v (salida)     | |
|  |  +-------------------------------------------------------------+  | |
|  |  |  CAPA DE APLICACION - Subnets App (4x /27)                  |  | |
|  |  |                                                             |  | |
|  |  |  us-east-1a: 192.168.0.64/27   us-east-1c: 192.168.0.96/27 |  | |
|  |  |  us-east-1a: 192.168.0.128/27  us-east-1c: 192.168.0.160/27|  | |
|  |  |                                                             |  | |
|  |  |  +-----------+   +-------------+   +---------------+       |  | |
|  |  |  | API Svc   |   | Evaluator   |   | Notifier Svc  |       |  | |
|  |  |  | (2-4)     |   | Svc (2)     |   | (2)           |       |  | |
|  |  |  | 512/1024  |   | 512/1024    |   | 512/1024      |       |  | |
|  |  |  +-----+-----+   +------+------+   +-------+-------+       |  | |
|  |  |        |                |                   |               |  | |
|  |  |  +-----+-----+          |                   |               |  | |
|  |  |  | ALB       |          |                   |               |  | |
|  |  |  | interno   |          |                   |               |  | |
|  |  |  | :80       |          |                   |               |  | |
|  |  |  | /health   |          |                   |               |  | |
|  |  |  +-----------+          |                   |               |  | |
|  |  |                         |                   |               |  | |
|  |  |  Ruta: 0.0.0.0/0 --> nat-xxx                                 |  | |
|  |  +-------------------------------------------------------------+  | |
|  |           |                                          |              | |
|  |           v                                          v              | |
|  |  +-------------------------------------------------------------+  | |
|  |  |  CAPA DE DATOS - Subnets DB (2x /27)                        |  | |
|  |  |                                                             |  | |
|  |  |  us-east-1a: 192.168.0.192/27  us-east-1c: 192.168.0.224/27|  | |
|  |  |                                                             |  | |
|  |  |  +-------------------+     +--------------------+           |  | |
|  |  |  | PostgreSQL (RDS)  |     | Valkey             |           |  | |
|  |  |  | :5432             |     | (ElastiCache) :6379|           |  | |
|  |  |  | db.t4g.micro      |     | cache.t4g.micro    |           |  | |
|  |  |  | gp3 20GB/100GB    |     |                    |           |  | |
|  |  |  | Cifrado: SI       |     | Cifrado: SI        |           |  | |
|  |  |  +-------------------+     +--------------------+           |  | |
|  |  |                                                             |  | |
|  |  |  Ruta: sin salida a internet                                |  | |
|  |  +-------------------------------------------------------------+  | |
|  +-------------------------------------------------------------------+ |
|                                                                          |
|  +------------------------+    +--------------------------------------+ |
|  | ECR (fuera de VPC)     |    | SQS (fuera de VPC)                   | |
|  |                        |    |                                      | |
|  | - back-api             |    | qualify -----> qualify-dlq           | |
|  | - worker-evaluator     |    | classify ----> classify-dlq          | |
|  | - worker-notificator   |    | notify ------> notify-dlq            | |
|  |                        |    | audit -------> audit-dlq             | |
|  | Lifecycle: 10 imagenes |    |                                      | |
|  | Escaneo: al push       |    | SSE: SQS-managed                     | |
|  +------------------------+    | Redrive: maxReceiveCount = 3         | |
|                                 +--------------------------------------+ |
|                                                                          |
|  +--------------------------------------------------------------------+ |
|  | EventBridge Scheduler                                              | |
|  | Start RDS: cron(0 16 ? * MON-FRI *)  -> 4:00 PM Colombia          | |
|  | Stop  RDS: cron(0 20 ? * MON-FRI *)  -> 8:00 PM Colombia          | |
|  +--------------------------------------------------------------------+ |
+========================================================================+
```

---

## Red (Network)

### Diseno de VPC

| Parametro              | Valor                  |
| ---------------------- | ---------------------- |
| CIDR                   | `192.168.0.0/24`       |
| DNS hostnames          | Habilitado             |
| DNS support            | Habilitado             |
| Region                 | `us-east-1`            |
| Zonas disponibilidad | `us-east-1a`, `us-east-1c` |

### Estrategia de subnets

La VPC se divide en tres capas con propositos especificos:

| Capa        | Subnets          | CIDRs                                   | Proposito                          |
| ----------- | ---------------- | --------------------------------------- | ---------------------------------- |
| Publica     | 2 subnets (/27)  | `192.168.0.0/27`, `192.168.0.32/27`    | NAT Gateway, Internet Gateway      |
| Aplicacion  | 4 subnets (/27)  | `192.168.0.64/27` - `192.168.0.160/27` | ECS Fargate, ALB                   |
| Datos       | 2 subnets (/27)  | `192.168.0.192/27`, `192.168.0.224/27` | RDS PostgreSQL, ElastiCache Valkey |

Cada subnet `/27` proporciona 32 direcciones IP (27 utilizables para hosts).

### Gateways

| Componente         | Ubicacion        | Funcion                                          |
| ------------------ | ---------------- | ------------------------------------------------ |
| Internet Gateway   | Subnet publica   | Acceso a internet para subnets publicas          |
| NAT Gateway + EIP  | Subnet publica   | Salida a internet para subnets privadas (app)    |

### Tablas de rutas

| Tabla de rutas    | Subnet asociada   | Ruta                           | Destino           |
| ----------------- | ----------------- | ------------------------------ | ----------------- |
| `rttpublic`       | Publicas          | `0.0.0.0/0`                    | Internet Gateway  |
| `rttprivate_app`  | Aplicacion        | `0.0.0.0/0`                    | NAT Gateway       |
| `rttprivate_db`   | Datos             | Sin ruta a internet            | Solo trafico local|

**Flujo de trafico:**

- **Entrante**: Internet -> IGW -> ALB (subnet publica/app) -> ECS Tasks
- **Saliente app**: ECS Tasks -> NAT Gateway -> Internet (para pulls de ECR, etc.)
- **Base de datos**: Sin salida a internet. Solo acepta trafico interno desde la capa de aplicacion

---

## Seguridad

### Security Groups

Cinco Security Groups controlan el trafico entre componentes:

| Security Group  | Ingress (origen)            | Puerto  | Protocolo | Proposito                          |
| --------------- | --------------------------- | ------- | --------- | ---------------------------------- |
| `alb`           | Desde `vpc_link`            | 80      | TCP       | ALB interno recibe trafico         |
| `vpc_link`      | Sin ingress (solo egress)   | -       | -         | VPC Link para API Gateway (futuro) |
| `ecs_tasks`     | Desde `alb`                 | 8000    | TCP       | Contenedores ECS (API)             |
| `rds`           | Desde `ecs_tasks`           | 5432    | TCP       | PostgreSQL                          |
| `cache`         | Desde `ecs_tasks`           | 6379    | TCP       | Valkey (ElastiCache)               |

**Diagrama de flujo de Security Groups:**

```
[VPC Link SG] --(puerto 80)--> [ALB SG] --(puerto 8000)--> [ECS Tasks SG]
                                                           /            \
                                          (puerto 5432) --/              \-- (puerto 6379)
                                                        v                  v
                                                   [RDS SG]          [Cache SG]
```

### Roles IAM

| Rol                          | Tipo            | Politicas adjuntas                            | Proposito                           |
| ---------------------------- | --------------- | --------------------------------------------- | ----------------------------------- |
| ECS Execution Role           | Service role    | `AmazonECSTaskExecutionRolePolicy`             | Pull de imagenes ECR, CloudWatch    |
| ECS Task Role                | Task role       | Politica inline para SQS (`sqs:*` en colas)   | Acceso a colas SQS desde contenedores |
| `GitHubActionsECRRole`       | OIDC            | `AmazonEC2ContainerRegistryPowerUser`          | Push de imagenes desde GitHub Actions |

**OIDC GitHub Actions:**

```hcl
# Configuracion de confianza OIDC
assume_role_policy = {
  Statement = [{
    Effect = "Allow"
    Principal = {
      Federated = "arn:aws:iam::oidc-provider/token.actions.githubusercontent.com"
    }
    Action = "sts:AssumeRoleWithWebIdentity"
    Condition = {
      StringEquals = {
        "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
      }
      StringLike = {
        "token.actions.githubusercontent.com:sub" = "repo:devgalop/*"
      }
    }
  }]
}
```

### Cifrado

| Componente      | En reposo               | En transito             |
| --------------- | ----------------------- | ----------------------- |
| RDS             | Cifrado AES-256 (gp3)  | TLS (configurable)      |
| ElastiCache     | Cifrado at-rest         | TLS habilitado          |
| SQS             | SSE (SQS-managed)       | HTTPS (API endpoint)    |
| ECR             | AES-256                 | HTTPS (pull/push)       |
| S3 (backend)    | SSE-S3                  | HTTPS                   |

### Aislamiento de red

- Las subnets de base de datos **no tienen ruta a internet** (sin NAT, sin IGW)
- Solo los Security Groups de RDS y Cache permiten trafico desde ECS Tasks
- El ALB es **interno** (no expuesto a internet directamente)
- El NAT Gateway es el unico punto de salida para las subnets de aplicacion

---

## Capa de computo (ECS Fargate)

### Cluster

| Parametro              | Valor                                    |
| ---------------------- | ---------------------------------------- |
| Nombre                 | `${workspace}-itmentorsoft`              |
| Tipo                   | Fargate                                  |
| Container Insights     | Habilitado                               |
| Red                    | `awsvpc` (ENI por tarea)                 |

### Task Definitions

Tres task definitions, una por servicio:

#### API Task Definition

| Parametro              | Valor                                    |
| ---------------------- | ---------------------------------------- |
| CPU                    | 512 unidades                             |
| Memoria                | 1024 MiB                                 |
| Red                    | awsvpc                                   |
| Puerto                 | 8000                                     |
| Log group              | `/ecs/api` (retencion 5 dias)            |

#### Evaluator Task Definition

| Parametro              | Valor                                    |
| ---------------------- | ---------------------------------------- |
| CPU                    | 512 unidades                             |
| Memoria                | 1024 MiB                                 |
| Red                    | awsvpc                                   |
| Log group              | `/ecs/evaluator` (retencion 5 dias)      |

#### Notifier Task Definition

| Parametro              | Valor                                    |
| ---------------------- | ---------------------------------------- |
| CPU                    | 512 unidades                             |
| Memoria                | 1024 MiB                                 |
| Red                    | awsvpc                                   |
| Log group              | `/ecs/notifier` (retencion 5 dias)       |

### Servicios

| Servicio     | Desired count | Min | Max | Autoscaling                  |
| ------------ | ------------- | --- | --- | ---------------------------- |
| API          | 2             | 2   | 4   | CPU target 60%               |
| Evaluator    | 2             | -   | -   | Fijo (configurable)          |
| Notifier     | 2             | -   | -   | Fijo (configurable)          |

### Application Load Balancer (ALB)

| Parametro              | Valor                                    |
| ---------------------- | ---------------------------------------- |
| Tipo                   | Interno (internal)                       |
| Esquema                | Application                              |
| Subnets                | Subnets de aplicacion                    |
| Puerto de escucha      | 80 (HTTP)                                |
| Target Group           | Health check en `/health` (HTTP)         |
| Security Group         | `alb` (ingreso desde `vpc_link`)         |

### Autoscaling (API Service)

```hcl
# Politica de escalado basada en CPU
resource "aws_appautoscaling_policy" "api_cpu" {
  target_tracking_scaling_policy_configuration {
    target_value       = 60.0    # CPU objetivo: 60%
    scale_in_cooldown  = 60      # Segundos antes de escalar hacia abajo
    scale_out_cooldown = 60      # Segundos antes de escalar hacia arriba
  }
}
```

- **Minimo**: 2 tareas (garantiza disponibilidad)
- **Maximo**: 4 tareas (limita costos)
- **Target CPU**: 60% (escala antes de llegar a saturacion)

### Variables de entorno de contenedores

Todos los servicios reciben las siguientes variables de entorno:

| Variable                  | Origen                    | Proposito                          |
| ------------------------- | ------------------------- | ---------------------------------- |
| `DB_HOST`                 | Output de RDS             | Direccion del servidor PostgreSQL  |
| `DB_PORT`                 | Output de RDS             | Puerto de PostgreSQL (5432)        |
| `DB_NAME`                 | Variable `db_name`        | Nombre de la base de datos         |
| `DB_USERNAME`             | Variable `db_username`    | Usuario de la base de datos        |
| `DB_PASSWORD`             | Variable `db_password`    | Contrasena de la base de datos     |
| `VALKEY_ENDPOINT`         | Output de ElastiCache     | Endpoint de Valkey                 |
| `EVALUATION_QUEUE_URL`    | Output de SQS             | URL de la cola `qualify`           |
| `NOTIFICATION_QUEUE_URL`  | Output de SQS             | URL de la cola `notify`            |
| `AUDIT_QUEUE_URL`         | Output de SQS             | URL de la cola `audit`             |

### CloudWatch Logs

| Log group          | Servicio     | Retencion    |
| ------------------ | ------------ | ------------ |
| `/ecs/api`         | API          | 5 dias       |
| `/ecs/evaluator`   | Evaluator    | 5 dias       |
| `/ecs/notifier`    | Notifier     | 5 dias       |

---

## Capa de datos

### RDS PostgreSQL

| Parametro              | Valor                                    |
| ---------------------- | ---------------------------------------- |
| Motor                  | PostgreSQL 18.3                          |
| Clase de instancia     | `db.t4g.micro`                           |
| Almacenamiento         | gp3, 20 GB asignado, 100 GB max          |
| Autoescalado storage   | Habilitado (20 GB -> 100 GB)             |
| Cifrado                | Habilitado (AES-256)                     |
| Multi-AZ               | Configurable (false en dev)              |
| Subnets                | Subnets de base de datos (2 AZs)         |
| Security Group         | `rds` (ingreso solo desde `ecs_tasks`)   |
| Backup retention       | 7 dias                                   |
| Deletion protection    | false                                    |
| Public accessibility   | false                                    |

**Programador de inicio/parada (EventBridge Scheduler):**

| Accion    | Horario (Colombia)        | Cron expression                | Dias                |
| --------- | ------------------------- | ------------------------------ | ------------------- |
| Start     | 4:00 PM                   | `cron(0 16 ? * MON-FRI *)`    | Lunes a Viernes     |
| Stop      | 8:00 PM                   | `cron(0 20 ? * MON-FRI *)`    | Lunes a Viernes     |

Este programador reduce costos significativamente al mantener la instancia apagada fuera del horario laboral.

### ElastiCache Valkey

| Parametro              | Valor                                    |
| ---------------------- | ---------------------------------------- |
| Motor                  | Valkey 7.2                               |
| Tipo de nodo           | `cache.t4g.micro`                        |
| Numero de nodos        | 1                                        |
| Cifrado en reposo      | Habilitado                               |
| Cifrado en transito    | Habilitado                               |
| Multi-AZ               | Configurable (false en dev)              |
| Subnets                | Subnets de base de datos                 |
| Security Group         | `cache` (ingreso solo desde `ecs_tasks`) |
| Parameter group        | `default.valkey7`                        |

---

## Cola de mensajes (SQS)

### Colas principales

| Cola         | Proposito                          | Visibility timeout | Retencion de mensajes |
| ------------ | ---------------------------------- | ------------------ | --------------------- |
| `qualify`    | Procesamiento de evaluaciones      | 120 segundos       | 345600s (4 dias)      |
| `classify`   | Clasificacion de contenido         | 120 segundos       | 345600s (4 dias)      |
| `notify`     | Envio de notificaciones            | 120 segundos       | 345600s (4 dias)      |
| `audit`      | Registro de auditoria              | 120 segundos       | 345600s (4 dias)      |

### Dead-Letter Queues (DLQ)

Cada cola principal tiene una DLQ asociada:

| DLQ             | Cola origen  | maxReceiveCount | Retencion DLQ           |
| --------------- | ------------ | --------------- | ----------------------- |
| `qualify-dlq`   | `qualify`    | 3               | 259200s (3 dias)        |
| `classify-dlq`  | `classify`   | 3               | 259200s (3 dias)        |
| `notify-dlq`    | `notify`     | 3               | 259200s (3 dias)        |
| `audit-dlq`     | `audit`      | 3               | 259200s (3 dias)        |

**Politica de redrive:**

```hcl
redrive_policy = {
  deadLetterTargetArn = aws_sqs_queue.dlq.arn
  maxReceiveCount     = 3    # Reintentos antes de enviar a DLQ
}
```

Despues de 3 intentos fallidos de procesamiento, el mensaje se mueve automaticamente a la DLQ correspondiente para revision manual o reprocesamiento posterior.

### Cifrado

Todas las colas tienen **SSE habilitado** (cifrado administrado por SQS):

```hcl
sqs_managed_sse_enabled = true
```

---

## Registro de contenedores (ECR)

### Repositorios

| Repositorio                      | Imagen de contenedor              |
| -------------------------------- | --------------------------------- |
| `itmentorsoft-back-api`          | API principal                     |
| `itmentorsoft-back-worker-evaluator` | Worker de evaluaciones        |
| `itmentorsoft-back-worker-notificator` | Worker de notificaciones    |

### Configuracion de repositorios

| Parametro              | Valor                                    |
| ---------------------- | ---------------------------------------- |
| Cifrado                | AES256                                   |
| Escaneo de imagenes    | Habilitado (scan on push)                |
| Tag mutability         | `MUTABLE`                                |
| Politica de ciclo de vida | Mantener las 10 imagenes mas recientes |

**Politica de ciclo de vida:**

```hcl
lifecycle_policy = {
  rules = [{
    rulePriority = 1
    description    = "Keep last 10 images"
    selection = {
      tagStatus   = "any"
      countType   = "imageCountMoreThan"
      countNumber = 10
    }
    action = {
      type = "expire"
    }
  }]
}
```

### Integracion GitHub Actions (OIDC)

Se crea un rol IAM `GitHubActionsECRRole` para que GitHub Actions pueda hacer push de imagenes a ECR sin credenciales estaticas:

- **Trust**: OIDC con `token.actions.githubusercontent.com`
- **Condicion**: Solo repositorios bajo `devgalop/*`
- **Politica**: `AmazonEC2ContainerRegistryPowerUser`

---

## API Gateway

**Estado actual**: Placeholder (modulo vacio).

El modulo `api_gateway` esta preparado para una futura implementacion de API Gateway V2 que actuaria como punto de entrada publico hacia el ALB interno a traves de un VPC Link. La configuracion de Security Groups ya incluye el grupo `vpc_link` y `alb` preparado para recibir trafico desde el VPC Link.

---

## Estrategia de despliegue

### Terraform Workspaces

Los entornos se separan mediante workspaces de Terraform, cada uno con su propio archivo de estado en S3:

```
Bucket: dev-bucket-itmentorsoft-iac-001
├── state/terraform.tfstate          # Workspace default
├── env:/dev/state/terraform.tfstate # Workspace dev
├── env:/staging/state/...           # Workspace staging (futuro)
└── env:/prod/state/...              # Workspace prod (futuro)
```

### Backend S3

```hcl
backend "s3" {
  bucket  = "dev-bucket-itmentorsoft-iac-001"
  key     = "state/terraform.tfstate"
  region  = "us-east-1"
  encrypt = true
  profile = "itmentorsoft-terraform-dev"
}
```

- **Bucket**: `dev-bucket-itmentorsoft-iac-001`
- **Cifrado**: SSE-S3 habilitado
- **Profile**: `itmentorsoft-terraform-dev`

### Variables por entorno

Cada entorno tiene su archivo `.tfvars` en `environments/`:

```bash
terraform plan -var-file="environments/dev.tfvars"
terraform apply -var-file="environments/dev.tfvars"
```

### Tagging comun

Todos los recursos heredan etiquetas comunes definidas en `main.tf`:

```hcl
locals {
  common_tags = {
    Environment = terraform.workspace   # dev, staging, prod
    Owner       = var.owner             # terraform-dev
    Project     = var.project           # itmentorsoft
  }
}
```

---

## Flujo de datos

### Flujo sincrono (API)

```
Cliente -> [API Gateway (futuro)] -> [VPC Link] -> [ALB :80]
    -> [ECS API Service :8000] -> [PostgreSQL :5432]
                                -> [Valkey :6379]
```

1. El cliente envia una peticion HTTP al API Gateway (futuro) o directamente al ALB
2. El VPC Link enruta el trafico al ALB interno
3. El ALB distribuye la carga entre las tareas del API Service
4. El API procesa la peticion, leyendo/escribiendo en PostgreSQL y usando Valkey como cache
5. La respuesta se devuelve al cliente a traves del ALB

### Flujo asincrono (Workers)

```
[API Service] -> [SQS qualify] -> [Evaluator Worker] -> [PostgreSQL]
             -> [SQS classify] -> [Evaluator Worker] -> [PostgreSQL]
             -> [SQS notify]  -> [Notifier Worker]  -> [PostgreSQL/Valkey]
             -> [SQS audit]   -> [Evaluator Worker] -> [PostgreSQL]
```

1. El API Service publica mensajes en las colas SQS correspondientes
2. Los workers (Evaluator, Notifier) hacen poll de sus colas asignadas
3. Los workers procesan los mensajes y persisten resultados en PostgreSQL
4. Si un mensaje falla 3 veces, se mueve a la DLQ para revision manual

### Flujo de CI/CD (GitHub Actions)

```
[GitHub Actions] -> [OIDC] -> [IAM Role] -> [ECR push]
                                              |
[ECS Service] <- [Image update] <-------------+
```

1. GitHub Actions se autentica via OIDC (sin credenciales estaticas)
2. Construye la imagen Docker y la sube al repositorio ECR correspondiente
3. ECS detecta la nueva imagen y actualiza las tareas (con la configuracion adecuada)

---

## Consideraciones de escalabilidad

### Autoscaling horizontal (API)

- El API Service escala de 2 a 4 tareas basado en uso de CPU (target 60%)
- Cooldown de 60 segundos tanto para scale-in como scale-out
- Fargate aprovisiona ENIs automaticamente para nuevas tareas

### Multi-AZ

- Las subnets de aplicacion y datos estan distribuidas en 2 AZs (`us-east-1a`, `us-east-1c`)
- RDS soporta Multi-AZ (configurable, deshabilitado en dev)
- ElastiCache soporta Multi-AZ (configurable, deshabilitado en dev)
- ECS distribuye tareas automaticamente entre AZs

### Limitaciones actuales

| Componente     | Limitacion                              | Recomendacion para prod        |
| -------------- | --------------------------------------- | ------------------------------ |
| API            | Max 4 tareas                            | Aumentar max a 10+             |
| Workers        | Count fijo                              | Agregar autoscaling por profundidad de cola |
| RDS            | db.t4g.micro                            | Escalar a db.t4g.medium/large  |
| ElastiCache    | cache.t4g.micro, 1 nodo                 | Cluster mode, multiples nodos  |
| VPC            | /24 (256 IPs)                           | Evaluar /16 para prod          |

---

## Optimizacion de costos

### Estrategias activas

| Estrategia                     | Ahorro estimado | Detalle                                         |
| ------------------------------ | --------------- | ----------------------------------------------- |
| RDS Scheduler                  | ~60-70%         | RDS apagado fuera de horario laboral (Lun-Vie 4PM-8PM Colombia) |
| Instancias pequenas (dev)      | Base            | db.t4g.micro, cache.t4g.micro                   |
| Fargate on-demand              | Variable        | Pago por segundo de CPU/Memoria usada           |
| Autoscaling API                | Dinamico        | Min 2 tareas, escala solo bajo carga            |
| Subnets DB sin NAT             | ~$32/mes        | Sin costo de NAT Gateway para trafico de DB     |
| ECR lifecycle (10 imagenes)    | Variable        | Reduce almacenamiento de imagenes antiguas      |
| CloudWatch retencion 5 dias    | Variable        | Logs no se acumulan indefinidamente             |

### Recursos dev (dimensionamiento actual)

| Recurso          | Spec                              | Notas                          |
| ---------------- | --------------------------------- | ------------------------------ |
| API              | 512 CPU / 1024 MiB x 2-4         | Autoscaling CPU 60%            |
| Evaluator        | 512 CPU / 1024 MiB x 2           | Desired fijo                   |
| Notifier         | 512 CPU / 1024 MiB x 2           | Desired fijo                   |
| RDS              | db.t4g.micro, 20 GB gp3           | Programador Lun-Vie            |
| ElastiCache      | cache.t4g.micro, Valkey 7.2       | 1 nodo                         |
| NAT Gateway      | 1                                 | Solo subnets de aplicacion     |

### Recomendaciones para produccion

1. **RDS Multi-AZ**: Habilitar para alta disponibilidad
2. **ElastiCache cluster mode**: Multiples nodos con replicas de lectura
3. **Fargate Spot**: Considerar para workers no criticos (ahorro hasta 70%)
4. **Reserved Instances**: Para RDS y ElastiCache en produccion (ahorro 30-60%)
5. **Secrets Manager**: Migrar credenciales de variables de entorno a AWS Secrets Manager
6. **VPC Flow Logs**: Habilitar para auditoria de red
7. **WAF**: Agregar Web Application Firewall delante del ALB/API Gateway
