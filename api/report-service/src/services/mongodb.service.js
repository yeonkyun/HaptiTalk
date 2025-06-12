const mongodb = require('../config/mongodb');
const logger = require('../utils/logger');

const mongodbService = {
    getDb() {
        return mongodb.getDb();
    },

    async findById(collection, id) {
        try {
            const db = await this.getDb();
            const result = await db.collection(collection).findOne({ _id: id });
            
            logger.info(`MongoDB 문서 ID 조회 성공: ${collection}`, {
                collection,
                documentId: id,
                found: !!result
            });
            
            return result;
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

            const results = await cursor.toArray();
            
            logger.info(`MongoDB 문서 조회 성공: ${collection}`, {
                collection,
                queryKeys: Object.keys(query),
                resultCount: results.length,
                hasLimit: !!limit,
                hasSort: !!sort
            });
            
            return results;
        } catch (error) {
            logger.error(`Error finding documents: ${error.message}`);
            throw error;
        }
    },

    async insertOne(collection, document) {
        try {
            const db = await this.getDb();
            const result = await db.collection(collection).insertOne(document);
            
            logger.info(`MongoDB 문서 삽입 성공: ${collection}`, {
                collection,
                insertedId: result.insertedId,
                documentKeys: Object.keys(document)
            });
            
            return result;
        } catch (error) {
            logger.error(`Error inserting document: ${error.message}`);
            throw error;
        }
    },

    async updateOne(collection, filter, update) {
        try {
            const db = await this.getDb();
            const result = await db.collection(collection).updateOne(filter, update);
            
            logger.info(`MongoDB 문서 업데이트 성공: ${collection}`, {
                collection,
                filterKeys: Object.keys(filter),
                updateKeys: Object.keys(update),
                modifiedCount: result.modifiedCount,
                matchedCount: result.matchedCount
            });
            
            return result;
        } catch (error) {
            logger.error(`Error updating document: ${error.message}`);
            throw error;
        }
    },

    async deleteOne(collection, filter) {
        try {
            const db = await this.getDb();
            const result = await db.collection(collection).deleteOne(filter);
            
            logger.info(`MongoDB 문서 삭제 성공: ${collection}`, {
                collection,
                filterKeys: Object.keys(filter),
                deletedCount: result.deletedCount
            });
            
            return result;
        } catch (error) {
            logger.error(`Error deleting document: ${error.message}`);
            throw error;
        }
    },

    async aggregate(collection, pipeline) {
        try {
            const db = await this.getDb();
            const results = await db.collection(collection).aggregate(pipeline).toArray();
            
            logger.info(`MongoDB 집계 쿼리 성공: ${collection}`, {
                collection,
                pipelineStages: pipeline.length,
                resultCount: results.length,
                stages: pipeline.map(stage => Object.keys(stage)[0])
            });
            
            return results;
        } catch (error) {
            logger.error(`Error executing aggregate: ${error.message}`);
            throw error;
        }
    }
};

module.exports = mongodbService;