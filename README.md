# TaskManager — Portfolio Cloud & DevOps sur Azure

Projet volontairement minimaliste de gestion de tâches. L’objectif principal n’est pas l’application elle-même, mais la mise en pratique de compétences Cloud, DevOps et Infrastructure as Code.

L’application permet d’ajouter et de supprimer des tâches.

> **Disclaimer —** Le frontend, le backend et la base de données servent de support à l’infrastructure ; ils ont été générés avec l’aide d’IA. La documentation a également été produite avec l’aide d’IA et relue sous contrôle humain.

## Sommaire

- [Objectifs](#objectifs)
- [Architecture cible](#architecture-cible)
- [Architecture et choix de conception](#architecture-et-choix-de-conception)
- [Stack technique](#stack-technique)
- [Prérequis et démarrage](#prérequis-et-démarrage)
- [Terraform](#terraform)
- [Branches](#branches)
- [CI/CD](#cicd)
- [Sécurité](#sécurité)

## Objectifs

- Provisionner une infrastructure Azure avec Terraform.
- Séparer le bootstrap de sécurité de l’infrastructure applicative.
- Utiliser GitHub Actions pour la CI/CD.
- Authentifier GitHub auprès d’Azure avec OIDC, sans secret Azure longue durée.
- Appliquer le principe du moindre privilège avec Azure RBAC.
- Conteneuriser et valider le backend avant publication.
- Protéger `main` : une modification ne doit être mergée qu’après validation des checks CI.

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

## Architecture et choix de conception

![Schéma de l’architecture Azure et des flux CI/CD](docs/images/architecture-azure.png)

Ce schéma documente les choix d’architecture mis en œuvre et les responsabilités de chaque composant :

- **Périmètre régional** : les composants applicatifs et réseau sont regroupés en `France Central`. La zone DNS privée est une ressource globale liée au VNet. Azure Static Web Apps diffuse les fichiers statiques globalement, même si la ressource nécessite une localisation Azure prise en charge lors de sa création.
- **Réseau** : la Container App est intégrée au subnet `10.0.0.0/27`. PostgreSQL se trouve dans le subnet délégué `10.0.0.32/28`, sans accès public. L’API joint la base par son nom DNS privé via TCP `5432` chiffré avec TLS.
- **Séparation des identités** : `taskmanager_ci_planner` produit les plans en lecture seule ; `taskmanager_ci_deployer` déploie depuis `main`, pousse l’image vers ACR et accède au state Blob dans les limites de ses rôles RBAC.
- **CI/CD sans secret longue durée** : GitHub échange un jeton OIDC contre une identité Entra fédérée. Les permissions Azure, notamment `Reader`, `Contributor`, `AcrPush` et `Storage Blob Data Contributor`, sont accordées séparément et au périmètre le plus restreint utile.
- **Observabilité et secrets** : Log Analytics centralise les logs de la plateforme ; Key Vault est prévu pour les secrets applicatifs. Une identité managée runtime distincte sera attribuée à la Container App pour accéder à ces services, sans utiliser l’identité CI.

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

<p align="center">
  <img src="https://cdn.simpleicons.org/react/61DAFB" alt="React" title="React" height="48" />
  <img src="https://cdn.simpleicons.org/nestjs/E0234E" alt="NestJS" title="NestJS" height="48" />
  <img src="https://cdn.simpleicons.org/postgresql/4169E1" alt="PostgreSQL" title="PostgreSQL" height="48" />
  <img src="https://cdn.simpleicons.org/prisma/2D3748" alt="Prisma" title="Prisma" height="48" />
  <img src="https://cdn.simpleicons.org/docker/2496ED" alt="Docker" title="Docker" height="48" />
  <img src="https://cdn.simpleicons.org/github/181717" alt="GitHub" title="GitHub" height="48" />
  <img src="https://cdn.simpleicons.org/githubactions/2088FF" alt="GitHub Actions" title="GitHub Actions" height="48" />
  <img src="https://cdn.simpleicons.org/terraform/7B42BC" alt="Terraform" title="Terraform" height="48" />
  <img src="https://cdn.jsdelivr.net/gh/devicons/devicon@latest/icons/azure/azure-original.svg" alt="Microsoft Azure" title="Microsoft Azure" height="48" />
</p>

## Prérequis et démarrage

### Outils du poste

| Outil | Usage dans le projet | Requis |
|---|---|---|
| Git | Cloner le dépôt, créer des branches et pousser le code | Oui |
| Node.js 20 LTS et npm | Installer et exécuter les builds/tests React, NestJS et Prisma | Oui |
| Docker Desktop avec Docker Compose | Construire l’image du backend et lancer la base PostgreSQL locale | Oui pour Docker / le développement local complet |
| Terraform | Provisionner et vérifier l’infrastructure Azure | Oui pour l’infrastructure |
| Azure CLI (`az`) | Connexion Entra ID locale et enregistrement des Resource Providers | Oui pour le bootstrap et le diagnostic local |
| `act` | Rejouer localement certains jobs GitHub Actions | Optionnel |

NestJS, React, Vite, Prisma et TypeScript sont installés comme dépendances du projet avec `npm ci` : aucune installation globale de ces frameworks n’est nécessaire.

### Accès nécessaires

- Un compte GitHub et un dépôt où GitHub Actions est activé.
- Une souscription Azure et un compte Entra ID autorisé à créer les ressources du bootstrap.
- Pour créer les attributions RBAC, le compte qui exécute le bootstrap doit disposer des droits de gestion d’accès au périmètre concerné (par exemple `Owner` ou `User Access Administrator`), en plus des droits de création de ressources.
- Les trois identifiants non secrets de l’identité CI (`client ID`, `tenant ID`, `subscription ID`) sont configurés dans les secrets GitHub. Aucun `client secret` Azure ni clé de Storage Account ne doit être ajouté à GitHub.

### Resource Providers Azure à enregistrer

L’enregistrement s’effectue au niveau de la souscription. Il peut être fait une fois avant le premier déploiement :

```bash
az provider register --namespace <namespace> --wait
```

| Namespace | Utilisé pour |
|---|---|
| `Microsoft.App` | Azure Container Apps et Container Apps Environment |
| `Microsoft.ContainerRegistry` | Azure Container Registry |
| `Microsoft.DBforPostgreSQL` | PostgreSQL Flexible Server |
| `Microsoft.KeyVault` | Azure Key Vault |
| `Microsoft.ManagedIdentity` | User Assigned Managed Identities et fédération GitHub OIDC |
| `Microsoft.Network` | VNet, subnets, délégation PostgreSQL et liens DNS privés |
| `Microsoft.OperationalInsights` | Log Analytics Workspace |
| `Microsoft.Storage` | Storage Account et conteneur Blob du state Terraform |
| `Microsoft.Web` | Azure Static Web Apps |

> Un nom mal orthographié, par exemple `Microsft.Network`, ne peut pas être enregistré. `Microsoft.App` est important : il correspond au service Azure Container Apps.

### Parcours recommandé : du clonage au déploiement

1. Cloner le dépôt et configurer l’identité Git locale avec l’adresse `noreply` du compte GitHub utilisé.
2. Installer les dépendances applicatives avec `npm ci` dans `backend/` puis dans `frontend/`.
3. Vérifier localement le backend (`npm run build`, `npm test`) et le frontend (`npm run build`). Pour une base locale, Docker Compose démarre PostgreSQL ; les valeurs de développement restent locales et ne doivent jamais devenir des secrets de production.
4. Installer Docker Desktop, Terraform et Azure CLI, puis se connecter localement avec `az login`.
5. Enregistrer les Resource Providers listés ci-dessus, puis exécuter le bootstrap Terraform avec un compte humain autorisé. Il crée le backend distant, les identités managées, les fédérations OIDC et le RBAC.
6. Migrer une seule fois le state du bootstrap vers Azure Blob, puis initialiser `terraform/prod` avec ce backend distant.
7. Configurer les secrets GitHub nécessaires à l’authentification OIDC et pousser les changements sur `dev`. Les builds/tests s’exécutent, puis une Pull Request vers `main` produit un plan Terraform.
8. Après les checks et le merge vers `main`, le workflow de déploiement exécute le plan puis applique ce plan exact avec l’identité CI de déploiement.

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
