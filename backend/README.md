# Mini Task Manager API

Backend NestJS volontairement minimal, destiné à servir de support au TP Terraform, GitHub Actions, Azure, sécurité et Docker.

## Démarrage local

1. Copier `.env.example` vers `.env` et remplacer les valeurs si besoin.
2. Démarrer PostgreSQL localement.
3. Installer les dépendances : `npm install`.
4. Générer Prisma et appliquer les migrations : `npm run prisma:generate && npm run prisma:deploy`.
5. Démarrer l'API : `npm run start:dev`.

L'API écoute sur `http://localhost:3000`.

## Endpoints

- `GET /health`
- `GET /tasks`
- `POST /tasks`
- `PATCH /tasks/:id`
- `DELETE /tasks/:id`

## Interface de démonstration

Une interface React volontairement minimale est disponible dans `frontend/`.

1. Démarrer l'API sur le port `3000`.
2. Dans `frontend/`, installer les dépendances avec `npm install` puis lancer `npm run dev`.
3. Ouvrir `http://localhost:5173`.

L'URL de l'API est configurable avec `VITE_API_URL` (voir `frontend/.env.example`).

## Conteneurisation

La conteneurisation de l’API et de PostgreSQL sera ajoutée dans le TP.
Les migrations Prisma ne devront pas être lancées au démarrage du conteneur API : elles seront exécutées par une étape contrôlée de livraison.

## Sécurité à traiter dans le TP

- Authentification des utilisateurs avec Microsoft Entra ID.
- Autorisation applicative des opérations sur les tâches.
- Secret de connexion PostgreSQL fourni à l'exécution par Key Vault et Managed Identity.
- CORS limité au domaine réel du frontend.
- Image Docker identifiée par un tag immuable dans la CI/CD.


