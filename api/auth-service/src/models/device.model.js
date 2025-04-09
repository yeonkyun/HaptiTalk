const {DataTypes, Op} = require('sequelize');
const {sequelize} = require('../config/database');
const User = require('./user.model');

const Device = sequelize.define('Device', {
    id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true
    },
    user_id: {
        type: DataTypes.UUID,
        allowNull: false,
        references: {
            model: User,
            key: 'id'
        }
    },
    device_type: {
        type: DataTypes.STRING(50),
        allowNull: false,
        validate: {
            isIn: [['mobile', 'watch', 'tablet']]
        }
    },
    device_token: {
        type: DataTypes.STRING(255),
        allowNull: true
    },
    device_name: {
        type: DataTypes.STRING(100),
        allowNull: true
    },
    device_model: {
        type: DataTypes.STRING(100),
        allowNull: true
    },
    os_version: {
        type: DataTypes.STRING(50),
        allowNull: true
    },
    app_version: {
        type: DataTypes.STRING(50),
        allowNull: true
    },
    is_watch: {
        type: DataTypes.BOOLEAN,
        defaultValue: false,
        allowNull: false
    },
    paired_device_id: {
        type: DataTypes.UUID,
        allowNull: true,
        references: {
            model: 'devices',
            key: 'id'
        }
    },
    last_active: {
        type: DataTypes.DATE,
        defaultValue: DataTypes.NOW,
        allowNull: false
    }
}, {
    tableName: 'devices',
    timestamps: true,
    underscored: true,
    indexes: [
        {
            fields: ['user_id']
        },
        {
            unique: true,
            fields: ['user_id', 'device_token'],
            where: {
                device_token: {
                    [Op.ne]: null
                }
            }
        }
    ]
});

// Relations
User.hasMany(Device, {foreignKey: 'user_id', as: 'devices'});
Device.belongsTo(User, {foreignKey: 'user_id'});

// Self-referencing for watch pairing
Device.belongsTo(Device, {foreignKey: 'paired_device_id', as: 'pairedDevice'});
Device.hasOne(Device, {foreignKey: 'paired_device_id', as: 'watchDevice'});

// Instance methods
Device.prototype.updateLastActive = async function () {
    this.last_active = new Date();
    return await this.save();
};

// Static methods
Device.findByUserDeviceToken = async function (userId, deviceToken) {
    return await Device.findOne({
        where: {
            user_id: userId,
            device_token: deviceToken
        }
    });
};

Device.findAllByUser = async function (userId) {
    return await Device.findAll({
        where: {
            user_id: userId
        }
    });
};

Device.findWatchesForDevice = async function (deviceId) {
    return await Device.findAll({
        where: {
            paired_device_id: deviceId,
            is_watch: true
        }
    });
};

module.exports = Device;