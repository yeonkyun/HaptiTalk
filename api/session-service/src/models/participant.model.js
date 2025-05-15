const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

/**
 * 세션 참가자 모델
 * 세션에 참여하는 참가자 정보를 저장
 */
const Participant = sequelize.define('participants', {
    id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true
    },
    session_id: {
        type: DataTypes.UUID,
        allowNull: false,
        references: {
            model: 'sessions',
            key: 'id'
        }
    },
    user_id: {
        type: DataTypes.UUID,
        allowNull: false
    },
    status: {
        type: DataTypes.ENUM('invited', 'joined', 'left'),
        defaultValue: 'invited',
        allowNull: false
    },
    joined_at: {
        type: DataTypes.DATE,
        allowNull: true
    },
    left_at: {
        type: DataTypes.DATE,
        allowNull: true
    },
    created_at: {
        type: DataTypes.DATE,
        defaultValue: DataTypes.NOW,
        allowNull: false
    },
    updated_at: {
        type: DataTypes.DATE,
        defaultValue: DataTypes.NOW,
        allowNull: false
    }
}, {
    tableName: 'participants',
    timestamps: true,
    underscored: true,
    createdAt: 'created_at',
    updatedAt: 'updated_at'
});

module.exports = { Participant }; 