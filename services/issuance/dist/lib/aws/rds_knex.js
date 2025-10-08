"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.createDatabaseConnection = void 0;
const knex_1 = __importDefault(require("knex"));
const createDatabaseConnection = () => {
    const config = {
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
    return (0, knex_1.default)(config);
};
exports.createDatabaseConnection = createDatabaseConnection;
//# sourceMappingURL=rds_knex.js.map