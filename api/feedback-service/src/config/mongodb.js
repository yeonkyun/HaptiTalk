const {MongoClient} = require('mongodb');
const logger = require('../utils/logger');

// MongoDB 연결 URL
const url = `mongodb://${process.env.MONGO_USER}:${process.env.MONGO_PASSWORD}@${process.env.MONGO_HOST}:${process.env.MONGO_PORT}/${process.env.MONGO_DB}?authSource=admin`;

let client;
let db;

// MongoDB 연결 초기화
async function connectToMongoDB() {
    try {
        client = new MongoClient(url);
        await client.connect();
        db = client.db(process.env.MONGO_DB);
        logger.info('MongoDB connection has been established successfully.');
        return db;
    } catch (error) {
        logger.error('Unable to connect to MongoDB:', error);
        throw error;
    }
}

// 데이터베이스 객체 가져오기
function getDB() {
    if (!db) {
        throw new Error('MongoDB connection not established');
    }
    return db;
}

// 콜렉션 가져오기
function getCollection(collectionName) {
    if (!db) {
        throw new Error('MongoDB connection not established');
    }
    return db.collection(collectionName);
}

// 연결 종료
async function closeConnection() {
    if (client) {
        await client.close();
        logger.info('MongoDB connection closed.');
    }
}

module.exports = {
    connectToMongoDB,
    getDB,
    getCollection,
    closeConnection
};