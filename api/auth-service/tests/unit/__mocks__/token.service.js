const tokenService = {
    generateAuthTokens: jest.fn().mockResolvedValue({
        access: {
            token: 'mock-access-token',
            expires: new Date(Date.now() + 3600000)
        },
        refresh: {
            token: 'mock-refresh-token',
            expires: new Date(Date.now() + 86400000)
        }
    }),

    verifyRefreshToken: jest.fn().mockImplementation((token) => {
        if (token === 'valid-refresh-token') {
            return Promise.resolve({
                sub: 1,
                exp: Math.floor(Date.now() / 1000) + 3600
            });
        }
        return Promise.reject(new Error('Invalid token'));
    }),

    revokeAccessToken: jest.fn().mockResolvedValue(true),
    revokeRefreshToken: jest.fn().mockResolvedValue(true)
};

module.exports = tokenService; 