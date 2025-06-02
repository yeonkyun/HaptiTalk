const mockUser = {
    id: 1,
    email: 'test@example.com',
    password_hash: '$2a$10$examplehash',
    is_verified: false,
    verification_token: 'verification-token',
    login_attempts: 0,
    locked_until: null,
    last_login: null,
    reset_token: null,
    reset_token_expires_at: null,
    validPassword: jest.fn().mockResolvedValue(true)
};

const createUserWithMethods = (data = {}) => ({
    ...mockUser,
    ...data,
    update: jest.fn().mockImplementation(function(updateData) {
        Object.assign(this, updateData);
        return Promise.resolve(this);
    })
});

const sequelize = {
    Op: {
        gt: Symbol('gt')
    }
};

const User = {
    findByEmail: jest.fn().mockImplementation((email) => {
        if (email === mockUser.email) {
            return Promise.resolve(createUserWithMethods());
        }
        return Promise.resolve(null);
    }),

    create: jest.fn().mockImplementation((userData) => {
        return Promise.resolve(createUserWithMethods(userData));
    }),

    findByPk: jest.fn().mockImplementation((id) => {
        if (id === mockUser.id) {
            return Promise.resolve(createUserWithMethods());
        }
        return Promise.resolve(null);
    }),

    findOne: jest.fn().mockImplementation((options) => {
        if (options.where.verification_token === mockUser.verification_token ||
            options.where.reset_token === 'valid-reset-token') {
            return Promise.resolve(createUserWithMethods());
        }
        return Promise.resolve(null);
    }),

    incrementLoginAttempts: jest.fn().mockResolvedValue(true),
    resetLoginAttempts: jest.fn().mockResolvedValue(true),
    lockAccount: jest.fn().mockResolvedValue(true),

    sequelize,
    Op: sequelize.Op
};

module.exports = User; 