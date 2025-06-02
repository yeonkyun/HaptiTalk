require('dotenv').config();
const { Sequelize } = require('sequelize');
const logger = require('../utils/logger');

const sequelize = new Sequelize(
    process.env.POSTGRES_DB,
    process.env.POSTGRES_USER,
    process.env.POSTGRES_PASSWORD,
    {
        host: process.env.POSTGRES_HOST || 'postgres',
        port: process.env.POSTGRES_PORT || 5432,
        dialect: 'postgres',
        logging: (msg) => logger.debug(msg),
        pool: {
            max: 5,
            min: 0,
            acquire: 30000,
            idle: 10000
        }
    }
);

const testDatabaseConnection = async () => {
    try {
        await sequelize.authenticate();
        logger.info('PostgreSQL connection has been established successfully.');
    } catch (error) {
        logger.error('Unable to connect to PostgreSQL database:', error);
    }
};

testDatabaseConnection();

module.exports = sequelize;