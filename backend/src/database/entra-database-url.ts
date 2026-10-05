const POSTGRES_RESOURCE = 'https://ossrdbms-aad.database.windows.net';

function required(name: string): string {
  const value = process.env[name];

  if (!value) {
    throw new Error(`Variable d'environnement manquante : ${name}`);
  }

  return value;
}

/**
 * Configure DATABASE_URL for an Azure Container Apps workload using a
 * user-assigned managed identity. Locally, DATABASE_URL remains unchanged.
 */
export async function configureEntraDatabaseUrl(): Promise<void> {
  if (!process.env.IDENTITY_ENDPOINT) {
    required('DATABASE_URL');
    return;
  }

  const endpoint = required('IDENTITY_ENDPOINT');
  const identityHeader = required('IDENTITY_HEADER');
  const clientId = required('AZURE_CLIENT_ID');

  const query = new URLSearchParams({
    resource: POSTGRES_RESOURCE,
    'api-version': '2019-08-01',
    client_id: clientId,
  });

  const response = await fetch(`${endpoint}?${query.toString()}`, {
    headers: {
      'X-IDENTITY-HEADER': identityHeader,
    },
  });

  if (!response.ok) {
    throw new Error(
      `Impossible d'obtenir un jeton Entra pour PostgreSQL (${response.status}).`,
    );
  }

  const { access_token: accessToken } = (await response.json()) as {
    access_token?: string;
  };

  if (!accessToken) {
    throw new Error("La réponse de l'identité managée ne contient pas de jeton.");
  }

  const host = required('PGHOST');
  const database = required('PGDATABASE');
  const user = required('PGUSER');

  process.env.DATABASE_URL =
    `postgresql://${encodeURIComponent(user)}:${encodeURIComponent(accessToken)}` +
    `@${host}:5432/${database}?sslmode=require`;
}
