const {Sequelize} = require('sequelize');
const logger = require('../utils/logger');

const sequelize = new Sequelize(
    process.env.POSTGRES_DB,
    process.env.POSTGRES_USER,
    process.env.POSTGRES_PASSWORD,
    {
        host: process.env.POSTGRES_HOST || 'postgres',
        port: process.env.POSTGRES_PORT || 5432,
        dialect: 'postgres',
        schema: 'auth', // Use auth schema
        logging: msg => logger.debug(msg),
        pool: {
            max: 10,
            min: 0,
            acquire: 30000,
            idle: 10000
        }
    }
);

module.exports = {
    sequelize
};