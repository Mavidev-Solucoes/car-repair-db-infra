# car-repair-db-infra

Infraestrutura Terraform para o Amazon RDS PostgreSQL do Car Repair.

Este repositório gerencia somente o banco, o secret de credenciais e os security groups de acesso ao banco. A VPC, subnets privadas, Amazon EKS e node security group vêm do repositório `car-repair-k8s-infra`.

## Escopo

Esta stack cria:

- Amazon RDS PostgreSQL privado
- DB Subnet Group usando somente subnets privadas recebidas por input
- Security Group do RDS
- Security Group reutilizável para clientes serverless futuros
- AWS Secrets Manager para credenciais do banco
- senha do banco gerada automaticamente pelo Terraform
- monitoring/log groups e recursos operacionais do RDS

Esta stack não cria:

- VPC
- EKS
- Lambda
- Kong
- New Relic
- External Secrets Operator
- recursos Kubernetes

## Arquitetura

```text
car-repair-k8s-infra
  |
  +-- VPC
  +-- Private Subnets
  +-- EKS
       |
       | eks_node_security_group_id
       v
  RDS Security Group
       |
       v
  RDS PostgreSQL privado :5432
       |
       v
  AWS Secrets Manager
```

Futuro acesso serverless:

```text
Lambda
 |
 | database_client_security_group
 v
RDS Security Group
 |
 v
RDS PostgreSQL privado :5432
```

O RDS permite PostgreSQL `5432/tcp` somente a partir de:

- `eks_node_security_group_id`
- `database_client_security_group_id`

Não há regra `0.0.0.0/0:5432`.

## Inputs de rede

Os valores abaixo devem ser obtidos dos outputs do `car-repair-k8s-infra`:

- `vpc_id`
- `private_subnet_ids`
- `eks_node_security_group_id`

Exemplo:

```hcl
vpc_id                     = "<output vpc_id>"
private_subnet_ids          = ["<output private_subnets[0]>", "<output private_subnets[1]>"]
eks_node_security_group_id  = "<output node_security_group_id>"
```

## RDS

Garantias aplicadas:

- `publicly_accessible = false`
- porta PostgreSQL `5432`
- DB Subnet Group com `private_subnet_ids`
- storage criptografado
- dev pode ser Single-AZ para reduzir custo
- prod usa Multi-AZ
- prod usa deletion protection
- prod cria final snapshot
- prod deve manter backup por pelo menos 7 dias

## Security Groups

O Security Group do RDS recebe somente:

- ingress `5432/tcp` a partir do SG dos nodes EKS
- ingress `5432/tcp` a partir do `database_client_security_group`

O `database_client_security_group` e uma identidade de rede reutilizavel para clientes como a futura Lambda Auth. Ele nao possui ingress. O egress e restrito ao Security Group do RDS na porta `5432/tcp`.

## Secrets Manager

Convenção oficial do secret do banco:

```text
car-repair/<environment>/database
```

Exemplos:

- `car-repair/dev/database`
- `car-repair/prod/database`

Conteúdo:

```json
{
  "username": "...",
  "password": "...",
  "engine": "postgres",
  "host": "...",
  "port": 5432,
  "database": "..."
}
```

A senha e gerada automaticamente por `random_password`.

Nao salvar senha em:

- `terraform.tfvars`
- outputs
- codigo
- GitHub variables

## Backend Terraform

Este repositório usa o mesmo bucket S3 de state criado pelo bootstrap da plataforma:

```text
car-repair-k8s-infra-terraform-state
```

Keys:

- dev: `car-repair-db-infra/dev/terraform.tfstate`
- hml: `car-repair-db-infra/hml/terraform.tfstate`
- prod: `car-repair-db-infra/prod/terraform.tfstate`

Configurado com:

- `encrypt = true`
- `use_lockfile = true`
- sem DynamoDB para locking

## Ambientes

### Dev

- Single-AZ aceitável
- classe menor para custo reduzido
- Performance Insights desabilitado por padrão
- final snapshot desabilitado

### Hml

- Configuração intermediária para homologação
- Pode reutilizar sizing reduzido conforme necessidade
- final snapshot pode ser desabilitado conforme política do ambiente

### Prod

- Multi-AZ
- deletion protection habilitado
- final snapshot habilitado
- backup retention >= 7 dias
- Performance Insights habilitado por padrão

## Como executar

### Pré-requisitos

Antes do deploy, garanta que:

- o `car-repair-k8s-infra` já foi aplicado no ambiente
- os outputs `vpc_id`, `private_subnet_ids` e `eks_node_security_group_id` estão disponíveis
- o bucket S3 do backend Terraform já existe
- suas credenciais AWS estão configuradas
- o arquivo `terraform.tfvars` foi criado a partir do exemplo do ambiente

Exemplo para dev:

```bash
cp environments/dev/terraform.tfvars.example environments/dev/terraform.tfvars
```

Exemplo para hml:

```bash
cp environments/hml/terraform.tfvars.example environments/hml/terraform.tfvars
```

Exemplo para prod:

```bash
cp environments/prod/terraform.tfvars.example environments/prod/terraform.tfvars
```

Inicializar dev:

```bash
terraform -chdir=terraform init -backend-config=../environments/dev/backend.tfvars
```

Planejar dev:

```bash
terraform -chdir=terraform plan -var-file=../environments/dev/terraform.tfvars
```

Aplicar dev:

```bash
terraform -chdir=terraform apply -var-file=../environments/dev/terraform.tfvars
```

Inicializar hml:

```bash
terraform -chdir=terraform init -backend-config=../environments/hml/backend.tfvars
```

Planejar hml:

```bash
terraform -chdir=terraform plan -var-file=../environments/hml/terraform.tfvars
```

Aplicar hml:

```bash
terraform -chdir=terraform apply -var-file=../environments/hml/terraform.tfvars
```

Inicializar prod:

```bash
terraform -chdir=terraform init -backend-config=../environments/prod/backend.tfvars
```

Planejar prod:

```bash
terraform -chdir=terraform plan -var-file=../environments/prod/terraform.tfvars
```

Aplicar prod:

```bash
terraform -chdir=terraform apply -var-file=../environments/prod/terraform.tfvars
```

## Destroy

> Atenção: o destroy remove a infraestrutura do banco. Em produção, valide snapshots, retenção de backup e impacto na aplicação antes de executar.

Destroy dev:

```bash
terraform -chdir=terraform destroy -var-file=../environments/dev/terraform.tfvars
```

Destroy hml:

```bash
terraform -chdir=terraform destroy -var-file=../environments/hml/terraform.tfvars
```

Destroy prod:

```bash
terraform -chdir=terraform destroy -var-file=../environments/prod/terraform.tfvars
```

## Outputs

Outputs mantidos para integração:

- `rds_endpoint`
- `rds_port`
- `rds_arn`
- `rds_security_group_id`
- `database_client_security_group_id`
- `database_secret_arn`
- `database_secret_name`

Nenhum output revela senha ou connection string completa.

## Recuperando credenciais

```bash
aws secretsmanager get-secret-value \
  --secret-id car-repair/dev/database \
  --region us-east-1 \
  --query SecretString \
  --output text | jq .
```

Use `car-repair/prod/database` para produção.

## Dependencias operacionais

- O `car-repair-k8s-infra` deve estar aplicado antes desta stack.
- Preencher `vpc_id`, `private_subnet_ids` e `eks_node_security_group_id` com outputs reais do ambiente.
- O bucket S3 do backend deve existir antes do `terraform init`.
- A futura Lambda Auth deve reutilizar o output `database_client_security_group_id`.

## Separação entre banco e aplicação

Este repositório provisiona exclusivamente a infraestrutura de banco de dados:

- Amazon RDS PostgreSQL
- DB Subnet Group
- Security Groups de acesso ao banco
- AWS Secrets Manager para credenciais
- logs, monitoramento e alertas operacionais do RDS

Este repositório não provisiona a aplicação nem a infraestrutura de execução da aplicação. Os recursos abaixo pertencem ao repositório `car-repair-k8s-infra`:

- VPC
- subnets privadas
- Amazon EKS
- node security group
- componentes Kubernetes e serviços da aplicação

## Relacionamento com os demais repositórios

| Repositório | Responsabilidade |
|------------|------------------|
| car-repair-app | API principal |
| car-repair-auth-lambda | Emissão de JWT |
| car-repair-db-infra | Banco PostgreSQL |
| car-repair-k8s-infra | Plataforma Kubernetes |
