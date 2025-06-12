module.exports = {
    testEnvironment: 'node',
    testMatch: ['**/tests/**/*.test.js'],
    collectCoverage: true,
    coverageDirectory: 'coverage',
    coverageReporters: ['text', 'lcov'],
    coveragePathIgnorePatterns: [
        '/node_modules/',
        '/tests/'
    ],
    verbose: true,
    detectOpenHandles: true,
    forceExit: true,
    testTimeout: 30000
}; 