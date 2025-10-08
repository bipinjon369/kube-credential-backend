import knex, { Knex } from 'knex';

export const createDatabaseConnection = (): Knex => {
  const config: Knex.Config = {
    client: 'pg',
    connection: {
      host: process.env.RDS_CLUSTER_HOST,
      port: parseInt(process.env.DB_PORT || '5432'),
      database: process.env.DB_NAME,
      user: process.env.RDS_CLUSTER_USERNAME,
      password: process.env.RDS_CLUSTER_PASSWORD,
    },
    pool: {
      min: 2,
      max: 10,
    },
    migrations: {
      tableName: 'knex_migrations',
    },
  };

  return knex(config);
};