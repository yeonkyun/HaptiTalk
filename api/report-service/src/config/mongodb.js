const { MongoClient } = require('mongodb');
const logger = require('../utils/logger');

const url = `mongodb://${process.env.MONGO_USER}:${process.env.MONGO_PASSWORD}@${process.env.MONGO_HOST || 'mongodb'}:${process.env.MONGO_PORT || 27017}/${process.env.MONGO_DB}?authSource=admin`;

let client;
let db;

async function connectToMongoDB() {
    try {
        if (db) return db;

        logger.info('Connecting to MongoDB...');
        client = new MongoClient(url);
        await client.connect();
        db = client.db(process.env.MONGO_DB);
        logger.info('Connected to MongoDB successfully');
        return db;
    } catch (error) {
        logger.error(`MongoDB connection error: ${error.message}`);
        throw error;
    }
}

function getDb() {
    if (!db) {
        return connectToMongoDB();
    }
    return Promise.resolve(db);
}

function closeConnection() {
    if (client) {
        logger.info('Closing MongoDB connection');
        return client.close();
    }
    return Promise.resolve();
}

module.exports = {
    connectToMongoDB,
    getDb,
    closeConnection
};