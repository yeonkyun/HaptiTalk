const { Sequelize, DataTypes } = require('sequelize');
const sequelize = require('../config/database');

/**
 * 리포트 메타데이터 모델 (MongoDB 데이터 참조용)
 */
const Report = sequelize.define('Report', {
    id: {
        type: DataTypes.UUID,
        defaultValue: Sequelize.UUIDV4,
        primaryKey: true
    },
    user_id: {
        type: DataTypes.UUID,
        allowNull: false
    },
    session_id: {
        type: DataTypes.UUID,
        allowNull: false
    },
    session_type: {
        type: DataTypes.STRING(50),
        allowNull: false
    },
    mongo_report_id: {
        type: DataTypes.STRING,
        allowNull: false,
        comment: 'MongoDB의 리포트 ID 참조'
    },
    title: {
        type: DataTypes.STRING(200),
        allowNull: false
    },
    description: {
        type: DataTypes.TEXT,
        allowNull: true
    },
    format: {
        type: DataTypes.STRING(10),
        allowNull: false,
        defaultValue: 'json'
    },
    pdf_path: {
        type: DataTypes.STRING(255),
        allowNull: true
    },
    created_at: {
        type: DataTypes.DATE,
        allowNull: false,
        defaultValue: Sequelize.NOW
    },
    updated_at: {
        type: DataTypes.DATE,
        allowNull: false,
        defaultValue: Sequelize.NOW
    }
}, {
    tableName: 'reports',
    schema: 'public',
    timestamps: true,
    createdAt: 'created_at',
    updatedAt: 'updated_at',
    indexes: [
        {
            name: 'idx_reports_user_id',
            fields: ['user_id']
        },
        {
            name: 'idx_reports_session_id',
            fields: ['session_id']
        },
        {
            name: 'idx_reports_mongo_report_id',
            fields: ['mongo_report_id'],
            unique: true
        }
    ]
});

module.exports = Report;