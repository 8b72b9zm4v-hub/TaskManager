import { execFileSync } from 'node:child_process';
import { configureEntraDatabaseUrl } from '../database/entra-database-url';
import { initializePostgresqlEntra } from './initialize-postgresql-entra';

async function main(): Promise<void> {
  await configureEntraDatabaseUrl();
  await initializePostgresqlEntra();

  execFileSync('npx', ['--no-install', 'prisma', 'migrate', 'deploy'], {
    env: process.env,
    stdio: 'inherit',
  });
}

void main();
