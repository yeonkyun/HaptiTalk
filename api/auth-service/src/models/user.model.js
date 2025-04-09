const {DataTypes} = require('sequelize');
const bcrypt = require('bcryptjs');
const {sequelize} = require('../config/database');

const User = sequelize.define('User', {
    id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true
    },
    email: {
        type: DataTypes.STRING(255),
        allowNull: false,
        unique: true,
        validate: {
            isEmail: true
        }
    },
    password_hash: {
        type: DataTypes.STRING(255),
        allowNull: false
    },
    salt: {
        type: DataTypes.STRING(255),
        allowNull: false
    },
    last_login: {
        type: DataTypes.DATE,
        allowNull: true
    },
    is_active: {
        type: DataTypes.BOOLEAN,
        defaultValue: true,
        allowNull: false
    },
    is_verified: {
        type: DataTypes.BOOLEAN,
        defaultValue: false,
        allowNull: false
    },
    verification_token: {
        type: DataTypes.STRING(255),
        allowNull: true
    },
    reset_token: {
        type: DataTypes.STRING(255),
        allowNull: true
    },
    reset_token_expires_at: {
        type: DataTypes.DATE,
        allowNull: true
    },
    login_attempts: {
        type: DataTypes.INTEGER,
        defaultValue: 0,
        allowNull: false
    },
    locked_until: {
        type: DataTypes.DATE,
        allowNull: true
    }
}, {
    tableName: 'users',
    timestamps: true,
    underscored: true,
    indexes: [
        {
            unique: true,
            fields: ['email']
        }
    ],
    hooks: {
        beforeValidate: async (user) => {
            if (!user.salt) {
                user.salt = await bcrypt.genSalt(10);
            }
        },
        beforeCreate: async (user) => {
            user.password_hash = await bcrypt.hash(user.password_hash, user.salt);
        },
        beforeUpdate: async (user) => {
            if (user.changed('password_hash')) {
                user.salt = await bcrypt.genSalt(10);
                user.password_hash = await bcrypt.hash(user.password_hash, user.salt);
            }
        }
    }
});

// Instance methods
User.prototype.validPassword = async function (password) {
    return await bcrypt.compare(password, this.password_hash);
};

// Static methods
User.findByEmail = async function (email) {
    return await User.findOne({where: {email}});
};

User.incrementLoginAttempts = async function (userId) {
    return await User.increment('login_attempts', {where: {id: userId}});
};

User.resetLoginAttempts = async function (userId) {
    return await User.update(
        {login_attempts: 0, locked_until: null},
        {where: {id: userId}}
    );
};

User.lockAccount = async function (userId, minutes = 30) {
    const lockUntil = new Date(Date.now() + minutes * 60000); // Lock for X minutes
    return await User.update(
        {locked_until: lockUntil},
        {where: {id: userId}}
    );
};

module.exports = User;