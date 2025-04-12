const {Sequelize} = require('sequelize');
const logger = require('../utils/logger');

// Sequelize 인스턴스 생성
const sequelize = new Sequelize(
    process.env.POSTGRES_DB || 'haptitalk',
    process.env.POSTGRES_USER || 'postgres',
    process.env.POSTGRES_PASSWORD || 'postgres',
    {
        dialect: 'postgres',
        host: process.env.POSTGRES_HOST || 'postgres',
        port: parseInt(process.env.POSTGRES_PORT || '5432', 10),
        logging: (msg) => logger.debug(msg),
        pool: {
            max: 5,
            min: 0,
            acquire: 30000,
            idle: 10000
        }
    }
);

// 데이터베이스 연결 테스트
const testConnection = async () => {
    try {
        await sequelize.authenticate();
        logger.info('데이터베이스 연결이 성공적으로 설정되었습니다.');
        return true;
    } catch (error) {
        logger.error('데이터베이스 연결에 실패했습니다:', error);
        throw error;
    }
};

// 모델 동기화 함수 (개발 환경에서만 사용할 것)
const syncModels = async (force = false) => {
    try {
        await sequelize.sync({force});
        logger.info(`Database models synchronized ${force ? '(with force)' : ''}`);
        return true;
    } catch (error) {
        logger.error('Failed to synchronize database models:', error);
        return false;
    }
};

module.exports = {
    sequelize,
    testConnection,
    syncModels
};