# TaskManager — Portfolio Cloud & DevOps sur Azure

Projet volontairement minimaliste de gestion de tâches. L’objectif principal n’est pas l’application elle-même, mais la mise en pratique de compétences Cloud, DevOps et Infrastructure as Code.

L’application permet d’ajouter et de supprimer des tâches. Le frontend, le backend et la base de données servent de support à l’infrastructure ; ils ont été générés avec l’aide d’IA.

## Objectifs

- Provisionner une infrastructure Azure avec Terraform.
- Séparer le bootstrap de sécurité de l’infrastructure applicative.
- Utiliser GitHub Actions pour la CI/CD.
- Authentifier GitHub auprès d’Azure avec OIDC, sans secret Azure longue durée.
- Appliquer le principe du moindre privilège avec Azure RBAC.
- Conteneuriser et valider le backend avant publication.
- Protéger `main` : une modification ne doit être mergée qu’après validation des checks CI.

## Stack technique

| Domaine | Technologies |
|---|---|
| Frontend | React |
| Backend | NestJS |
| Base de données | PostgreSQL Flexible Server |
| ORM | Prisma |
| Conteneurisation | Docker / Docker Compose |
| Gestion de code | Git / GitHub |
| CI/CD | GitHub Actions |
| Infrastructure as Code | Terraform |
| Cloud | Microsoft Azure |

## Architecture cible

```text
Utilisateur
    │
    ├── Azure Static Web Apps
    │       └── Frontend React
    │
    └── Azure Container Apps
            └── API NestJS
                    │
                    ├── Azure Database for PostgreSQL Flexible Server
                    ├── Azure Container Registry
                    ├── Azure Key Vault
                    └── Azure Storage Account
                            └── Terraform remote state
```

L’infrastructure réseau cible utilise un VNet dédié, un subnet pour Azure Container Apps, un subnet délégué à PostgreSQL et une zone DNS privée PostgreSQL.

## Terraform

Le projet sépare volontairement deux états Terraform :

```text
terraform/
├── bootstrap/   # Identités CI, RBAC et backend distant Terraform
└── prod/        # Infrastructure applicative Azure
```

### Bootstrap

Le bootstrap crée notamment :

- le Resource Group `TaskManager` ;
- l’identité managée `taskmanager-ci-deployer` pour les déploiements depuis `main` ;
- l’identité managée `taskmanager-ci-planner` pour les plans Terraform sur Pull Request ;
- les fédérations OIDC GitHub ;
- le Storage Account et le container Blob privé `tfstate` ;
- les rôles Azure RBAC nécessaires.

Le state Terraform est sensible. Les fichiers suivants ne doivent jamais être commités :

```text
terraform.tfstate
terraform.tfstate.backup
.terraform/
```

Les fichiers `.terraform.lock.hcl` doivent en revanche être versionnés.

### Infrastructure de production

Le dossier `terraform/prod` référence le Resource Group créé par le bootstrap avec une source de données Terraform. Il ne recrée pas ce Resource Group.

L’infrastructure déclarée comprend notamment :

- Virtual Network et subnets ;
- Azure Container Registry ;
- Log Analytics ;
- Azure Container Apps Environment et Container App ;
- Azure Static Web App ;
- PostgreSQL Flexible Server privé ;
- zone DNS privée PostgreSQL ;
- Azure Key Vault.

Le déploiement automatisé de production après merge sur `main` est en cours de mise en place.

## CI/CD

### CI sur `dev`

À chaque push sur `dev`, GitHub Actions exécute en parallèle :

- build et tests du backend NestJS ;
- build du frontend React ;
- build de l’image Docker du backend, sans push vers un registry.

### Plan Terraform sur Pull Request

Lorsqu’une Pull Request cible `main` et modifie Terraform :

- `terraform fmt -check` ;
- `terraform init` avec backend Azure Blob ;
- `terraform validate` ;
- `terraform plan`.

Le workflow Terraform utilise GitHub OIDC et Azure RBAC. Il n’utilise ni access key du Storage Account ni `client secret` Azure.

```text
Pull Request
    │
    └── GitHub OIDC token
            │
            └── Identité managée Azure planner
                    │
                    ├── Reader sur le Resource Group
                    └── Storage Blob Data Contributor sur tfstate
```

### Validation locale

La CI applicative peut être testée localement avec [act](https://github.com/nektos/act).

> `act` permet de valider les jobs Node.js et Docker localement.
> L’authentification OIDC GitHub vers Azure doit être validée sur un runner GitHub hébergé.

## Sécurité

- Aucun mot de passe PostgreSQL ne doit être stocké en clair dans Git.
- Aucun state Terraform ne doit être versionné.
- Le backend Terraform Azure Blob utilise Entra ID / RBAC.
- Les identités planner et deployer sont distinctes.
- L’identité runtime de la future Container App sera distincte des identités CI.
- Les rôles Blob sont limités au container `tfstate`.
- Les images Docker ne devront pas être déployées avec le tag `latest`.

## Branches

```text
dev
 └── CI : tests, builds, image Docker
        │
        └── Pull Request vers main
                └── Terraform plan
                        └── Merge après checks réussis
                                └── Déploiement production à venir
```

## TODO

- [ ] Ajouter le workflow de déploiement après merge sur `main`.
- [ ] Documenter les identités Azure, OIDC et les rôles RBAC.
- [ ] Documenter l’infrastructure Azure et les flux réseau.
- [ ] Documenter le pipeline CI/CD.
- [ ] Documenter les Resource Providers Azure à enregistrer selon les ressources utilisées.
- [ ] Ajouter la gestion des secrets applicatifs avec Azure Key Vault.
- [ ] Ajouter l’identité managée runtime de la Container App.
- [ ] Mettre en place le push de l’image versionnée vers Azure Container Registry.
