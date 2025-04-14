const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const UserFeedbackSetting = sequelize.define('UserFeedbackSetting', {
    user_id: {
        type: DataTypes.UUID,
        primaryKey: true
    },
    haptic_strength: {
        type: DataTypes.INTEGER,
        allowNull: false,
        defaultValue: 5
    },
    active_patterns: {
        type: DataTypes.ARRAY(DataTypes.STRING),
        allowNull: false,
        defaultValue: []
    },
    priority_threshold: {
        type: DataTypes.STRING(10),
        allowNull: false,
        defaultValue: 'medium'
    },
    minimum_interval_seconds: {
        type: DataTypes.INTEGER,
        allowNull: false,
        defaultValue: 10
    },
    feedback_frequency: {
        type: DataTypes.STRING(10),
        allowNull: false,
        defaultValue: 'medium'
    },
    mode_settings: {
        type: DataTypes.JSONB,
        allowNull: true
    },
    created_at: {
        type: DataTypes.DATE,
        allowNull: false,
        defaultValue: DataTypes.NOW
    },
    updated_at: {
        type: DataTypes.DATE,
        allowNull: false,
        defaultValue: DataTypes.NOW
    }
}, {
    tableName: 'user_feedback_settings',
    schema: 'public',
    timestamps: true,
    underscored: true,
    createdAt: 'created_at',
    updatedAt: 'updated_at'
});

module.exports = UserFeedbackSetting;