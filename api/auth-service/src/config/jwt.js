// JWT configuration
const JWT_CONFIG = {
    ACCESS_TOKEN: {
        SECRET: process.env.JWT_ACCESS_SECRET || 'access_secret',
        EXPIRES_IN: process.env.JWT_ACCESS_EXPIRES_IN || '1h'
    },
    REFRESH_TOKEN: {
        SECRET: process.env.JWT_REFRESH_SECRET || 'refresh_secret',
        EXPIRES_IN: process.env.JWT_REFRESH_EXPIRES_IN || '30d'
    },
    SESSION_TOKEN: {
        SECRET: process.env.JWT_SESSION_SECRET || 'session_secret',
        EXPIRES_IN: process.env.JWT_SESSION_EXPIRES_IN || '24h'
    }
};

module.exports = JWT_CONFIG;