const {DataTypes} = require('sequelize');
const sequelize = require('../config/database');

const HapticPattern = sequelize.define('haptic_pattern', {
    id: {
        type: DataTypes.STRING(50),
        primaryKey: true
    },
    name: {
        type: DataTypes.STRING(100),
        allowNull: false
    },
    description: {
        type: DataTypes.TEXT,
        allowNull: true
    },
    pattern_data: {
        type: DataTypes.JSONB,
        allowNull: false
    },
    category: {
        type: DataTypes.STRING(50),
        allowNull: false
    },
    intensity_default: {
        type: DataTypes.INTEGER,
        allowNull: false,
        defaultValue: 5
    },
    duration_ms: {
        type: DataTypes.INTEGER,
        allowNull: false,
        defaultValue: 300
    },
    version: {
        type: DataTypes.INTEGER,
        allowNull: false,
        defaultValue: 1
    },
    is_active: {
        type: DataTypes.BOOLEAN,
        allowNull: false,
        defaultValue: true
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
    tableName: 'haptic_patterns',
    schema: 'config',
    timestamps: false,
    indexes: [
        {
            name: 'idx_haptic_patterns_category',
            fields: ['category']
        },
        {
            name: 'idx_haptic_patterns_active',
            fields: ['is_active']
        }
    ]
});

module.exports = HapticPattern;