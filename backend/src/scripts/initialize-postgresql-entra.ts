import { Client } from 'pg';

function required(name: string): string {
  const value = process.env[name];

  if (!value) {
    throw new Error(`Variable d'environnement manquante : ${name}`);
  }

  return value;
}

function quoteIdentifier(identifier: string): string {
  return `"${identifier.replaceAll('"', '""')}"`;
}

/**
 * Maps the Entra application group to a PostgreSQL role, then grants the
 * runtime privileges required by the backend. This is intentionally
 * idempotent: a migration job can execute it before every Prisma deployment.
 */
export async function initializePostgresqlEntra(): Promise<void> {
  const connectionString = required('DATABASE_URL');
  const groupName = required('PG_APP_GROUP_NAME');
  const groupObjectId = required('PG_APP_GROUP_OBJECT_ID');
  const quotedGroupName = quoteIdentifier(groupName);

  const client = new Client({
    connectionString,
    ssl: {
      rejectUnauthorized: true,
    },
  });

  await client.connect();

  try {
    const role = await client.query<{ exists: boolean }>(
      'SELECT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = $1) AS exists',
      [groupName],
    );

    if (!role.rows[0]?.exists) {
      await client.query(
        `SELECT * FROM pg_catalog.pgaadauth_create_principal_with_oid(
          $1, $2, 'group', false, false
        )`,
        [groupName, groupObjectId],
      );
    }

    await client.query(`GRANT CONNECT ON DATABASE postgres TO ${quotedGroupName}`);
    await client.query(`GRANT USAGE ON SCHEMA public TO ${quotedGroupName}`);
    await client.query(
      `GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO ${quotedGroupName}`,
    );
    await client.query(
      `GRANT USAGE, SELECT, UPDATE ON ALL SEQUENCES IN SCHEMA public TO ${quotedGroupName}`,
    );
    await client.query(
      `ALTER DEFAULT PRIVILEGES IN SCHEMA public
       GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO ${quotedGroupName}`,
    );
    await client.query(
      `ALTER DEFAULT PRIVILEGES IN SCHEMA public
       GRANT USAGE, SELECT, UPDATE ON SEQUENCES TO ${quotedGroupName}`,
    );
  } finally {
    await client.end();
  }
}
