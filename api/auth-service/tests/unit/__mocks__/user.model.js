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
    reset_token_expires_at: null
};

const User = {
    findByEmail: jest.fn().mockImplementation((email) => {
        if (email === mockUser.email) {
            return Promise.resolve(mockUser);
        }
        return Promise.resolve(null);
    }),

    create: jest.fn().mockImplementation((userData) => {
        return Promise.resolve({
            ...mockUser,
            ...userData
        });
    }),

    findByPk: jest.fn().mockImplementation((id) => {
        if (id === mockUser.id) {
            return Promise.resolve(mockUser);
        }
        return Promise.resolve(null);
    }),

    findOne: jest.fn().mockImplementation((options) => {
        if (options.where.verification_token === mockUser.verification_token) {
            return Promise.resolve(mockUser);
        }
        return Promise.resolve(null);
    }),

    incrementLoginAttempts: jest.fn().mockResolvedValue(true),
    resetLoginAttempts: jest.fn().mockResolvedValue(true),
    lockAccount: jest.fn().mockResolvedValue(true),

    update: jest.fn().mockImplementation((data) => {
        return Promise.resolve({
            ...mockUser,
            ...data
        });
    })
};

module.exports = User; 