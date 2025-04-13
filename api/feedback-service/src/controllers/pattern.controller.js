const httpStatus = require('http-status');
const patternService = require('../services/pattern.service');
const {formatResponse} = require('../utils/responseFormatter');

/**
 * 모든 햅틱 패턴 조회
 */
const getAllPatterns = async (req, res, next) => {
    try {
        const {category, active} = req.query;
        const patterns = await patternService.getAllPatterns({category, active});

        return res.status(httpStatus.OK).json(formatResponse(
            true,
            patterns,
            '햅틱 패턴 목록을 성공적으로 조회했습니다.'
        ));
    } catch (error) {
        next(error);
    }
};

/**
 * 특정 햅틱 패턴 조회
 */
const getPatternById = async (req, res, next) => {
    try {
        const {id} = req.params;
        const pattern = await patternService.getPatternById(id);

        if (!pattern) {
            return res.status(httpStatus.NOT_FOUND).json(formatResponse(
                false,
                null,
                '해당 ID의 햅틱 패턴을 찾을 수 없습니다.'
            ));
        }

        return res.status(httpStatus.OK).json(formatResponse(
            true,
            pattern,
            '햅틱 패턴을 성공적으로 조회했습니다.'
        ));
    } catch (error) {
        next(error);
    }
};

/**
 * 새로운 햅틱 패턴 생성 (관리자 전용)
 */
const createPattern = async (req, res, next) => {
    try {
        const newPattern = await patternService.createPattern(req.body);

        return res.status(httpStatus.CREATED).json(formatResponse(
            true,
            newPattern,
            '햅틱 패턴이 성공적으로 생성되었습니다.'
        ));
    } catch (error) {
        next(error);
    }
};

/**
 * 햅틱 패턴 업데이트 (관리자 전용)
 */
const updatePattern = async (req, res, next) => {
    try {
        const {id} = req.params;
        const updatedPattern = await patternService.updatePattern(id, req.body);

        if (!updatedPattern) {
            return res.status(httpStatus.NOT_FOUND).json(formatResponse(
                false,
                null,
                '해당 ID의 햅틱 패턴을 찾을 수 없습니다.'
            ));
        }

        return res.status(httpStatus.OK).json(formatResponse(
            true,
            updatedPattern,
            '햅틱 패턴이 성공적으로 업데이트되었습니다.'
        ));
    } catch (error) {
        next(error);
    }
};

/**
 * 햅틱 패턴 비활성화 (관리자 전용)
 */
const deactivatePattern = async (req, res, next) => {
    try {
        const {id} = req.params;
        const result = await patternService.deactivatePattern(id);

        if (!result) {
            return res.status(httpStatus.NOT_FOUND).json(formatResponse(
                false,
                null,
                '해당 ID의 햅틱 패턴을 찾을 수 없습니다.'
            ));
        }

        return res.status(httpStatus.OK).json(formatResponse(
            true,
            null,
            '햅틱 패턴이 성공적으로 비활성화되었습니다.'
        ));
    } catch (error) {
        next(error);
    }
};

module.exports = {
    getAllPatterns,
    getPatternById,
    createPattern,
    updatePattern,
    deactivatePattern
};