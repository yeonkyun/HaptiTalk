const mongodb = require('../config/mongodb');
const logger = require('../utils/logger');

const mongodbService = {
    getDb() {
        return mongodb.getDb();
    },

    async findById(collection, id) {
        try {
            const db = await this.getDb();
            return db.collection(collection).findOne({ _id: id });
        } catch (error) {
            logger.error(`Error finding document by ID: ${error.message}`);
            throw error;
        }
    },

    async find(collection, query, options = {}) {
        try {
            const db = await this.getDb();
            const { limit, skip, sort, projection } = options;

            let cursor = db.collection(collection).find(query);

            if (projection) cursor = cursor.project(projection);
            if (sort) cursor = cursor.sort(sort);
            if (skip) cursor = cursor.skip(skip);
            if (limit) cursor = cursor.limit(limit);

            return cursor.toArray();
        } catch (error) {
            logger.error(`Error finding documents: ${error.message}`);
            throw error;
        }
    },

    async insertOne(collection, document) {
        try {
            const db = await this.getDb();
            return db.collection(collection).insertOne(document);
        } catch (error) {
            logger.error(`Error inserting document: ${error.message}`);
            throw error;
        }
    },

    async updateOne(collection, filter, update) {
        try {
            const db = await this.getDb();
            return db.collection(collection).updateOne(filter, update);
        } catch (error) {
            logger.error(`Error updating document: ${error.message}`);
            throw error;
        }
    },

    async deleteOne(collection, filter) {
        try {
            const db = await this.getDb();
            return db.collection(collection).deleteOne(filter);
        } catch (error) {
            logger.error(`Error deleting document: ${error.message}`);
            throw error;
        }
    },

    async aggregate(collection, pipeline) {
        try {
            const db = await this.getDb();
            return db.collection(collection).aggregate(pipeline).toArray();
        } catch (error) {
            logger.error(`Error executing aggregate: ${error.message}`);
            throw error;
        }
    }
};

module.exports = mongodbService;