const {DataTypes} = require('sequelize');
const {sequelize} = require('../config/database');

const Settings = sequelize.define('settings', {
    id: {
        type: DataTypes.UUID,
        primaryKey: true,
        allowNull: false,
        comment: '사용자 ID (auth.users.id 참조)'
    },
    notification_enabled: {
        type: DataTypes.BOOLEAN,
        allowNull: false,
        defaultValue: true,
        comment: '알림 활성화 여부'
    },
    haptic_strength: {
        type: DataTypes.INTEGER,
        allowNull: false,
        defaultValue: 5,
        validate: {
            min: 1,
            max: 10
        },
        comment: '햅틱 피드백 강도 (1-10)'
    },
    analysis_level: {
        type: DataTypes.STRING(20),
        allowNull: false,
        defaultValue: 'standard',
        comment: '분석 수준 (basic/standard/advanced)'
    },
    audio_retention_days: {
        type: DataTypes.INTEGER,
        allowNull: false,
        defaultValue: 7,
        comment: '오디오 녹음 보관 일수'
    },
    data_anonymization_level: {
        type: DataTypes.STRING(20),
        allowNull: false,
        defaultValue: 'standard',
        comment: '데이터 익명화 수준 (basic/standard/complete)'
    },
    default_mode: {
        type: DataTypes.STRING(20),
        allowNull: false,
        defaultValue: 'dating',
        comment: '기본 모드 (dating/interview/business/coaching)'
    },
    theme: {
        type: DataTypes.STRING(20),
        allowNull: false,
        defaultValue: 'system',
        comment: '앱 테마 (light/dark/system)'
    },
    language: {
        type: DataTypes.STRING(10),
        allowNull: false,
        defaultValue: 'ko',
        comment: '앱 언어 설정'
    },
    updated_at: {
        type: DataTypes.DATE,
        allowNull: false,
        defaultValue: DataTypes.NOW,
        comment: '설정 업데이트 시간'
    }
}, {
    tableName: 'settings',
    schema: 'users',
    timestamps: true,
    createdAt: false,
    updatedAt: 'updated_at'
});

module.exports = Settings;