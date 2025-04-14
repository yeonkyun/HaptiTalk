const express = require('express');
const {validate} = require('../middleware/validation.middleware');
const {authenticateJWT, isAdmin} = require('../middleware/auth.middleware');
const patternController = require('../controllers/pattern.controller');
const patternValidation = require('../utils/validators/pattern.validator');

const router = express.Router();

// 공개 라우트 - 인증 필요 없음
router.get('/', patternController.getAllPatterns);
router.get('/:id', patternController.getPatternById);

// 관리자 전용 라우트
router.post(
    '/',
    authenticateJWT,
    isAdmin,
    validate(patternValidation.createPattern),
    patternController.createPattern
);

router.put(
    '/:id',
    authenticateJWT,
    isAdmin,
    validate(patternValidation.updatePattern),
    patternController.updatePattern
);

router.delete(
    '/:id',
    authenticateJWT,
    isAdmin,
    patternController.deactivatePattern
);

module.exports = router;