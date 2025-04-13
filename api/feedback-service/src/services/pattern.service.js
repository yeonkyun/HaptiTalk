const HapticPattern = require('../models/pattern.model');
const logger = require('../utils/logger');

/**
 * 모든 햅틱 패턴 조회
 */
const getAllPatterns = async ({category, active}) => {
    try {
        const query = {};

        if (category) {
            query.category = category;
        }

        if (active !== undefined) {
            query.is_active = active === 'true';
        }

        const patterns = await HapticPattern.findAll({
            where: query,
            order: [['category', 'ASC'], ['name', 'ASC']]
        });

        return patterns;
    } catch (error) {
        logger.error('Error in getAllPatterns:', error);
        throw error;
    }
};

/**
 * 특정 햅틱 패턴 조회
 */
const getPatternById = async (id) => {
    try {
        const pattern = await HapticPattern.findByPk(id);
        return pattern;
    } catch (error) {
        logger.error(`Error in getPatternById for id ${id}:`, error);
        throw error;
    }
};

/**
 * 새로운 햅틱 패턴 생성
 */
const createPattern = async (patternData) => {
    try {
        const newPattern = await HapticPattern.create({
            ...patternData,
            created_at: new Date(),
            updated_at: new Date()
        });

        return newPattern;
    } catch (error) {
        logger.error('Error in createPattern:', error);
        throw error;
    }
};

/**
 * 햅틱 패턴 업데이트
 */
const updatePattern = async (id, updateData) => {
    try {
        const pattern = await HapticPattern.findByPk(id);

        if (!pattern) {
            return null;
        }

        const updatedPattern = await pattern.update({
            ...updateData,
            updated_at: new Date()
        });

        return updatedPattern;
    } catch (error) {
        logger.error(`Error in updatePattern for id ${id}:`, error);
        throw error;
    }
};

/**
 * 햅틱 패턴 비활성화
 */
const deactivatePattern = async (id) => {
    try {
        const pattern = await HapticPattern.findByPk(id);

        if (!pattern) {
            return null;
        }

        await pattern.update({
            is_active: false,
            updated_at: new Date()
        });

        return true;
    } catch (error) {
        logger.error(`Error in deactivatePattern for id ${id}:`, error);
        throw error;
    }
};

module.exports = {
    getAllPatterns,
    getPatternById,
    createPattern,
    updatePattern,
    deactivatePattern
};