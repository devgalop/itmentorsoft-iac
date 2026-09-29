# ITMentorSoft - Infraestructura como Codigo (IaC)

Repositorio de infraestructura como codigo para **ITMentorSoft**, gestionado con Terraform sobre AWS. Este proyecto define y automatiza el aprovisionamiento de todos los recursos de nube necesarios para la plataforma, incluyendo redes, computo, bases de datos, colas de mensajes y registros de contenedores.

## Tabla de contenidos

- [Requisitos previos](#requisitos-previos)
- [Estructura del proyecto](#estructura-del-proyecto)
- [Diagrama de arquitectura](#diagrama-de-arquitectura)
- [Arquitectura base](#arquitectura-base)
- [Modulos](#modulos)
- [Comandos comunes de Terraform](#comandos-comunes-de-terraform)
- [Variables de entorno](#variables-de-entorno)
- [Consideraciones de seguridad](#consideraciones-de-seguridad)
- [Costos y optimizacion](#costos-y-optimizacion)

---

## Requisitos previos

| Herramienta       | Version requerida | Proposito                                    |
| ------------------ | ----------------- | -------------------------------------------- |
| Terraform          | `~> 6.0`          | Provisionamiento de infraestructura           |
| AWS CLI            | v2.x              | Configuracion de perfiles y credenciales      |
| Perfil AWS         | `itmentorsoft-terraform-dev` | Perfil configurado en `~/.aws/credentials` |

Configuracion del perfil AWS:

```bash
aws configure --profile itmentorsoft-terraform-dev
```

---

## Estructura del proyecto

```
itmentorsoft-iac/
├── environments/
│   └── dev.tfvars                # Variables para entorno de desarrollo
├── modules/
│   ├── api_gateway/              # API Gateway V2 (placeholder)
│   ├── cache/                    # ElastiCache Valkey
│   ├── database/                 # RDS PostgreSQL
│   ├── ecr/                      # Elastic Container Registry + OIDC
│   ├── ecs/                      # ECS Fargate + ALB + Autoscaling
│   ├── messaging/                # SQS Queues + DLQs
│   ├── network/                  # VPC, Subnets, NAT, IGW, Rutas
│   └── security/                 # Security Groups
├── docs/
│   └── ARCHITECTURE.md           # Documentacion detallada de arquitectura
├── main.tf                       # Orquestacion de modulos raiz
├── providers.tf                  # Configuracion de provider y backend
├── variables.tf                  # Variables raiz
├── .terraform.lock.hcl           # Lock file de providers
└── .gitignore
```

---

## Diagrama de arquitectura

![Diagrama de arquitectura](docs/diag_deploy_itmentorsoft.drawio.svg)

---

## Arquitectura base

La infraestructura se despliega en una sola region AWS (`us-east-1`) dentro de una VPC segmentada en tres capas de red, siguiendo el principio de menor privilegio para el trafico entre componentes.

```
+------------------------------------------------------------------+
|                     AWS us-east-1                                  |
|                                                                    |
|  +--------------------------------------------------------------+ |
|  |              VPC (192.168.0.0/24)                             | |
|  |                                                              | |
|  |  +------------------------------------------------------+   | |
|  |  |  Subnets Publicas (2x /27)                           |   | |
|  |  |  [NAT Gateway]  <-->  [Internet Gateway]             |   | |
|  |  +------------------------------------------------------+   | |
|  |                                                              | |
|  |  +------------------------------------------------------+   | |
|  |  |  Subnets de Aplicacion (4x /27) - ECS Fargate        |   | |
|  |  |  [API Service]  [Evaluator]  [Notifier]              |   | |
|  |  |       |                                              |   | |
|  |  |  [ALB interno]                                       |   | |
|  |  +------------------------------------------------------+   | |
|  |                                                              | |
|  |  +------------------------------------------------------+   | |
|  |  |  Subnets de Base de Datos (2x /27)                   |   | |
|  |  |  [PostgreSQL (RDS)]    [Valkey (ElastiCache)]        |   | |
|  |  +------------------------------------------------------+   | |
|  +--------------------------------------------------------------+ |
|                                                                    |
|  [ECR (3 repos)]        [SQS (4 colas + DLQs)]                    |
|  [EventBridge Scheduler]                                           |
+------------------------------------------------------------------+
```

**Componentes principales:**

- **Red**: VPC con subnets publicas, de aplicacion y de base de datos, separadas por tablas de rutas
- **Computo**: 3 servicios ECS Fargate (API, Evaluator, Notifier) con autoscaling
- **Datos**: PostgreSQL 18.3 en RDS + Valkey 7.2 en ElastiCache
- **Mensajeria**: 4 colas SQS con dead-letter queues para procesamiento asincrono
- **Contenedores**: 3 repositorios ECR con escaneo de imagenes y politica de ciclo de vida
- **Programador**: EventBridge Scheduler para encender/apagar RDS en horario laboral

---

## Modulos

| Modulo          | Descripcion                                              |
| --------------- | -------------------------------------------------------- |
| `network`       | VPC, subnets, Internet Gateway, NAT Gateway, tablas de rutas |
| `security`      | 5 Security Groups (ALB, VPC Link, ECS, RDS, Cache)      |
| `ecr`           | 3 repositorios ECR + rol IAM para GitHub Actions (OIDC) |
| `database`      | RDS PostgreSQL con almacenamiento gp3 y programador de inicio/parada |
| `cache`         | ElastiCache Valkey con cifrado en reposo y en transito  |
| `messaging`     | 4 colas SQS con dead-letter queues y cifrado SSE        |
| `ecs`           | Cluster Fargate, 3 servicios, ALB interno, autoscaling, CloudWatch |
| `api_gateway`   | Placeholder para API Gateway V2 (futuro)                |

---

## Comandos comunes de Terraform

### Inicializacion

```bash
terraform init
```

Inicializa el backend S3 remoto y descarga los providers necesarios. El estado se almacena de forma remota en:

- **Bucket**: `dev-bucket-itmentorsoft-iac-001`
- **Key**: `state/terraform.tfstate`
- **Cifrado**: Habilitado (SSE-S3)

### Planificar cambios

```bash
terraform plan -var-file="environments/dev.tfvars"
```

Muestra un resumen de los cambios que se aplicaran sin modificar la infraestructura. Siempre revisar el plan antes de aplicar.

### Aplicar cambios

```bash
terraform apply -var-file="environments/dev.tfvars"
```

Aplica los cambios planificados a la infraestructura. Requiere confirmacion interactiva (usar `-auto-approve` para omitir en CI/CD).

### Destruir infraestructura

```bash
terraform destroy -var-file="environments/dev.tfvars"
```

Elimina todos los recursos gestionados. **Usar con precaucion.**

### Formatear codigo

```bash
terraform fmt
terraform fmt -recursive
```

Formatea los archivos `.tf` siguiendo el estilo canonico de Terraform. `-recursive` aplica a subdirectorios (modulos).

### Validar configuracion

```bash
terraform validate
```

Verifica que la sintaxis y configuracion sean correctas sin consultar el provider.

### Workspaces (entornos)

```bash
terraform workspace list          # Listar workspaces existentes
terraform workspace new staging   # Crear nuevo workspace
terraform workspace select dev    # Cambiar a workspace dev
terraform workspace show          # Mostrar workspace activo
```

Los workspaces permiten separar el estado de Terraform por entorno (dev, staging, prod) usando la misma configuracion base.

### Consultar outputs

```bash
terraform output                  # Todos los outputs
terraform output db_address       # Output especifico
terraform output -json            # Formato JSON
```

### Inspeccionar estado

```bash
terraform state list              # Listar recursos en el estado
terraform state show <resource>   # Detalle de un recurso
terraform state mv <src> <dst>   # Mover recurso en el estado
```

### Importar recursos existentes

```bash
terraform import <resource_type>.<name> <resource_id>
```

Permite incorporar recursos creados manualmente al estado de Terraform.

---

## Variables de entorno

Las variables se definen en archivos `.tfvars` dentro del directorio `environments/`. Cada entorno tiene su propio archivo:

```
environments/
└── dev.tfvars    # Desarrollo
```

**Variables principales:**

| Variable                  | Tipo          | Descripcion                                  |
| ------------------------- | ------------- | -------------------------------------------- |
| `project`                 | `string`      | Nombre del proyecto                          |
| `owner`                   | `string`      | Propietario de los recursos                  |
| `aws_region`              | `string`      | Region AWS de despliegue                     |
| `vpc_cidr`                | `string`      | Bloque CIDR de la VPC                        |
| `availability_zones`      | `list(string)`| Zonas de disponibilidad                      |
| `public_subnets`          | `list(string)`| CIDRs de subnets publicas                    |
| `app_subnets`             | `list(string)`| CIDRs de subnets de aplicacion               |
| `db_subnets`              | `list(string)`| CIDRs de subnets de base de datos            |
| `queues`                  | `list(string)`| Nombres de colas SQS a crear                 |
| `api_port`                | `number`      | Puerto del contenedor API                    |
| `db_instance_class`       | `string`      | Clase de instancia RDS                       |
| `db_engine_version`       | `string`      | Version del motor PostgreSQL                 |
| `db_name`                 | `string`      | Nombre de la base de datos                   |
| `multi_az`                | `bool`        | RDS Multi-AZ                                 |
| `cache_node_type`         | `string`      | Tipo de nodo ElastiCache                     |
| `api_cpu` / `api_memory`  | `number`      | Recursos CPU/Memoria para el API             |
| `worker_cpu` / `worker_memory` | `number` | Recursos CPU/Memoria para workers            |
| `api_min_capacity`        | `number`      | Minimo de instancias API                     |
| `api_max_capacity`        | `number`      | Maximo de instancias API                     |
| `worker_desired_count`    | `number`      | Tareas deseadas para workers                 |

Para agregar un nuevo entorno, crear un archivo `environments/<env>.tfvars` con los valores correspondientes y usar el workspace de Terraform:

```bash
terraform workspace new <env>
terraform plan -var-file="environments/<env>.tfvars"
```

---

## Consideraciones de seguridad

- **Cifrado en reposo**: RDS (gp3 cifrado), ElastiCache (cifrado at-rest), SQS (SSE administrado por SQS), ECR (AES256), estado S3 (SSE-S3)
- **Cifrado en transito**: ElastiCache (TLS habilitado), comunicacion entre servicios via Security Groups
- **Security Groups**: Aislamiento por capas, solo el trafico necesario entre componentes (ver [ARCHITECTURE.md](docs/ARCHITECTURE.md#seguridad))
- **IAM**: Roles minimos para ECS (execution + task), integracion OIDC con GitHub Actions sin credenciales estaticas
- **Secretos**: Las credenciales de base de datos se pasan como variables de entorno a los contenedores. Considerar migrar a AWS Secrets Manager o SSM Parameter Store para produccion
- **Escaneo de imagenes**: ECR escanea imagenes automaticamente al hacer push
- **Politica de ciclo de vida**: ECR mantiene solo las 10 imagenes mas recientes

---

## Costos y optimizacion

| Estrategia                          | Detalle                                                  |
| ----------------------------------- | -------------------------------------------------------- |
| Programador RDS                     | Encendido solo Lun-Vie 4:00 PM - 8:00 PM (hora Colombia) |
| Instancias pequenas                 | `db.t4g.micro` (RDS), `cache.t4g.micro` (Valkey)        |
| Fargate bajo demanda                | Pago por uso real de CPU/Memoria                         |
| Autoscaling API                     | 2-4 tareas segun carga (target CPU 60%)                  |
| Subnets de base de datos sin NAT    | Sin costo de salida a internet para DB                   |
| ECR lifecycle policy                | Solo 10 imagenes, reduce almacenamiento                  |

**Estimacion de recursos dev:**

| Componente       | Spec                          |
| ---------------- | ----------------------------- |
| API              | 512 CPU / 1024 MiB x 2-4     |
| Evaluator        | 512 CPU / 1024 MiB x 2       |
| Notifier         | 512 CPU / 1024 MiB x 2       |
| RDS              | db.t4g.micro, 20 GB gp3       |
| ElastiCache      | cache.t4g.micro, Valkey 7.2   |

Para mas detalles sobre la arquitectura, consultar [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).
