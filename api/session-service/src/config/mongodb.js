const { MongoClient } = require('mongodb');
const logger = require('../utils/logger');

const url = `mongodb://${process.env.MONGO_USER || 'tae4an'}:${process.env.MONGO_PASSWORD || 'Qpalz,woskxm1029!!'}@${process.env.MONGO_HOST || 'mongodb'}:${process.env.MONGO_PORT || 27017}/${process.env.MONGO_DB || 'haptitalk'}?authSource=admin`;

let client;
let db;

async function connectToMongoDB() {
    try {
        if (db) return db;

        logger.info('Connecting to MongoDB...');
        client = new MongoClient(url);
        await client.connect();
        db = client.db(process.env.MONGO_DB || 'haptitalk');
        logger.info('Connected to MongoDB successfully');
        return db;
    } catch (error) {
        logger.error(`MongoDB connection error: ${error.message}`);
        throw error;
    }
}

function getDB() {
    if (!db) {
        return connectToMongoDB();
    }
    return Promise.resolve(db);
}

function getCollection(collectionName) {
    return getDB().then(database => database.collection(collectionName));
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
    getDB,
    getCollection,
    closeConnection
}; 