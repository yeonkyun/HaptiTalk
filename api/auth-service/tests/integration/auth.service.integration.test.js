const httpStatus = require('http-status');
const authService = require('../../src/services/auth.service');
const { setupTestDatabase, cleanupTestDatabase, setupRedis, cleanupRedis } = require('./setup');

describe('AuthService Integration Tests', () => {
    beforeAll(async () => {
        await setupTestDatabase();
        await setupRedis();
    }, 30000);

    afterAll(async () => {
        await cleanupTestDatabase();
        await cleanupRedis();
    }, 30000);

    describe('register', () => {
        it('should register a new user and store in database', async () => {
            const userData = {
                email: 'newuser@example.com',
                password: 'password123'
            };

            const result = await authService.register(userData);

            expect(result).toHaveProperty('id');
            expect(result).toHaveProperty('email', userData.email);
            expect(result).toHaveProperty('is_verified', false);
            expect(result).toHaveProperty('verification_token');
        });
    });

    describe('login', () => {
        it('should login successfully with valid credentials', async () => {
            const email = 'test@example.com';
            const password = 'password123';
            const deviceInfo = { deviceId: 'test-device' };

            const result = await authService.login(email, password, deviceInfo);

            expect(result).toHaveProperty('user');
            expect(result).toHaveProperty('tokens');
            expect(result.user).toHaveProperty('id');
            expect(result.user).toHaveProperty('email', email);
        });

        it('should handle invalid login attempts', async () => {
            const email = 'test@example.com';
            const wrongPassword = 'wrongpassword';
            const deviceInfo = { deviceId: 'test-device' };

            await expect(authService.login(email, wrongPassword, deviceInfo))
                .rejects.toThrow('Invalid email or password');
        });
    });

    describe('token management', () => {
        let accessToken;
        let refreshToken;

        beforeAll(async () => {
            const email = 'test@example.com';
            const password = 'password123';
            const deviceInfo = { deviceId: 'test-device' };

            const loginResult = await authService.login(email, password, deviceInfo);
            accessToken = loginResult.tokens.access.token;
            refreshToken = loginResult.tokens.refresh.token;
        });

        it('should refresh tokens successfully', async () => {
            const result = await authService.refreshAuth(refreshToken);

            expect(result).toHaveProperty('access');
            expect(result).toHaveProperty('refresh');
            expect(result.access).toHaveProperty('token');
            expect(result.refresh).toHaveProperty('token');
        });

        it('should logout successfully', async () => {
            await expect(authService.logout(accessToken, refreshToken))
                .resolves.not.toThrow();
        });
    });

    describe('password reset flow', () => {
        it('should handle password reset request and reset', async () => {
            const email = 'test@example.com';
            
            // Request password reset
            const resetRequest = await authService.requestPasswordReset(email);
            expect(resetRequest).toHaveProperty('resetToken');
            expect(resetRequest).toHaveProperty('expiresAt');

            // Reset password
            const newPassword = 'newpassword123';
            const result = await authService.resetPassword(resetRequest.resetToken, newPassword);
            
            expect(result).toHaveProperty('id');
            expect(result).toHaveProperty('email', email);

            // Verify new password works
            const deviceInfo = { deviceId: 'test-device' };
            await expect(authService.login(email, newPassword, deviceInfo))
                .resolves.toHaveProperty('user');
        });
    });

    describe('email verification', () => {
        it('should verify email successfully', async () => {
            const verificationToken = 'verification-token';
            
            const result = await authService.verifyEmail(verificationToken);
            
            expect(result).toHaveProperty('is_verified', true);
            expect(result).toHaveProperty('email');
        });
    });
}); 