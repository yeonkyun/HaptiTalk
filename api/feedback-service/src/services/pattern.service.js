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

        logger.info(`햅틱 패턴 목록 조회 성공`, {
            filterCategory: category,
            filterActive: active,
            resultCount: patterns.length
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
        
        if (pattern) {
            logger.info(`햅틱 패턴 조회 성공: ${id}`, {
                patternName: pattern.name,
                category: pattern.category,
                isActive: pattern.is_active
            });
        } else {
            logger.warn(`햅틱 패턴 조회 실패 - 존재하지 않는 패턴: ${id}`);
        }
        
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

        logger.info(`햅틱 패턴 생성 성공: ${newPattern.id}`, {
            patternName: newPattern.name,
            category: newPattern.category,
            durationMs: newPattern.duration_ms
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
            logger.warn(`햅틱 패턴 업데이트 실패 - 존재하지 않는 패턴: ${id}`);
            return null;
        }

        const updatedPattern = await pattern.update({
            ...updateData,
            updated_at: new Date()
        });

        logger.info(`햅틱 패턴 업데이트 성공: ${id}`, {
            updatedFields: Object.keys(updateData),
            patternName: updatedPattern.name
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

/**
 * 햅틱 패턴 삭제
 */
const deletePattern = async (id) => {
    try {
        const pattern = await HapticPattern.findByPk(id);

        if (!pattern) {
            logger.warn(`햅틱 패턴 삭제 실패 - 존재하지 않는 패턴: ${id}`);
            return false;
        }

        await pattern.destroy();

        logger.info(`햅틱 패턴 삭제 성공: ${id}`, {
            patternName: pattern.name,
            category: pattern.category
        });

        return true;
    } catch (error) {
        logger.error(`Error in deletePattern for id ${id}:`, error);
        throw error;
    }
};

module.exports = {
    getAllPatterns,
    getPatternById,
    createPattern,
    updatePattern,
    deactivatePattern,
    deletePattern
};