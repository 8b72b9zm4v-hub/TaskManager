# Instructions pour les agents

## Objectif du dépôt

Ce dépôt est un portfolio d'apprentissage Cloud / DevOps orienté Azure. La priorité est l'infrastructure, la sécurité et la CI/CD. Le frontend, le backend et la base de données sont des applications de support : ne pas étendre leurs fonctionnalités de manière spéculative.

## Périmètre de modification

Les modifications sont autorisées uniquement dans les périmètres suivants :

- documentation : `README.md` et `docs/` ;
- frontend : `frontend/` ;
- backend : `backend/`.

Les éléments suivants sont protégés et peuvent être consultés en lecture seule, mais ne doivent jamais être modifiés, renommés, supprimés ou générés sans l'accord explicite de l'utilisateur :

- `terraform/` ;
- `.github/workflows/` ;
- les fichiers de conteneurisation, notamment `Dockerfile*`, `compose*.yaml`, `compose*.yml` et `.dockerignore`.

Si une modification dans un périmètre protégé semble nécessaire, expliquer précisément la raison, la modification proposée et son impact, puis attendre l'accord explicite de l'utilisateur.

## Documentation

- Considérer `README.md` à la racine comme la documentation principale du projet.
- Signaler explicitement toute incohérence constatée entre `README.md`, la configuration Terraform et les workflows CI/CD.
- Lorsqu'une modification d'infrastructure, de sécurité ou de CI/CD est validée, proposer la mise à jour correspondante du README.
- Ne pas modifier la documentation sans l'accord explicite de l'utilisateur. Après une modification, indiquer précisément ce qui a été documenté.

## Sécurité et intégrité

- Ne jamais ajouter, exposer, afficher ou versionner un secret, un token, une clé d'accès Azure, un mot de passe PostgreSQL ou un fichier Terraform state.
- Ne jamais remplacer l'authentification GitHub OIDC / Entra ID par une clé de Storage Account ou un `client secret` Azure.
- Préserver les modifications existantes de l'utilisateur et signaler les fichiers modifiés non liés à la demande.
- Ne pas exécuter d'action destructive ou ayant un impact Azure, GitHub ou Git sans l'autorisation explicite de l'utilisateur.

## Mode de travail

- Lire les fichiers pertinents avant de proposer une modification.
- Limiter les changements à la demande utilisateur ; éviter les refactorisations ou ajouts non demandés.
- Expliquer clairement les hypothèses, les risques et les validations réalisées.
