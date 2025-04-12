const httpStatus = require('http-status');
const authService = require('../../src/services/auth.service');
const User = require('./mocks/user.model');
const tokenService = require('./mocks/token.service');

jest.mock('../../src/models/user.model', () => require('./mocks/user.model'));
jest.mock('../../src/services/token.service', () => require('./mocks/token.service'));

describe('AuthService', () => {
    beforeEach(() => {
        jest.clearAllMocks();
    });

    describe('register', () => {
        it('should register a new user successfully', async () => {
            const userData = {
                email: 'newuser@example.com',
                password: 'password123'
            };

            const result = await authService.register(userData);

            expect(User.findByEmail).toHaveBeenCalledWith(userData.email);
            expect(User.create).toHaveBeenCalled();
            expect(result).toHaveProperty('id');
            expect(result).toHaveProperty('email', userData.email);
            expect(result).toHaveProperty('is_verified', false);
            expect(result).toHaveProperty('verification_token');
        });

        it('should throw error when email already exists', async () => {
            const userData = {
                email: 'test@example.com',
                password: 'password123'
            };

            await expect(authService.register(userData)).rejects.toThrow('Email already registered');
            expect(User.findByEmail).toHaveBeenCalledWith(userData.email);
        });
    });

    describe('login', () => {
        it('should login successfully with valid credentials', async () => {
            const email = 'test@example.com';
            const password = 'password123';
            const deviceInfo = { deviceId: 'test-device' };

            const mockUser = {
                id: 1,
                email,
                is_verified: false,
                validPassword: jest.fn().mockResolvedValue(true),
                update: jest.fn().mockResolvedValue(true)
            };

            User.findByEmail.mockResolvedValueOnce(mockUser);

            const result = await authService.login(email, password, deviceInfo);

            expect(User.findByEmail).toHaveBeenCalledWith(email);
            expect(mockUser.validPassword).toHaveBeenCalledWith(password);
            expect(mockUser.update).toHaveBeenCalledWith({ last_login: expect.any(Date) });
            expect(tokenService.generateAuthTokens).toHaveBeenCalled();
            expect(result).toHaveProperty('user');
            expect(result).toHaveProperty('tokens');
        });

        it('should throw error with invalid password', async () => {
            const email = 'test@example.com';
            const password = 'wrongpassword';
            const deviceInfo = { deviceId: 'test-device' };

            // Mock validPassword to return false
            User.findByEmail.mockResolvedValueOnce({
                ...User.findByEmail(),
                validPassword: jest.fn().mockResolvedValue(false)
            });

            await expect(authService.login(email, password, deviceInfo))
                .rejects.toThrow('Invalid email or password');
            expect(User.incrementLoginAttempts).toHaveBeenCalled();
        });

        it('should throw error when account is locked', async () => {
            const email = 'test@example.com';
            const password = 'password123';
            const deviceInfo = { deviceId: 'test-device' };

            // Mock locked account
            User.findByEmail.mockResolvedValueOnce({
                ...User.findByEmail(),
                locked_until: new Date(Date.now() + 3600000)
            });

            await expect(authService.login(email, password, deviceInfo))
                .rejects.toThrow('Account is locked');
        });
    });

    describe('logout', () => {
        it('should logout successfully', async () => {
            const accessToken = 'valid-access-token';
            const refreshToken = 'valid-refresh-token';

            await authService.logout(accessToken, refreshToken);

            expect(tokenService.revokeAccessToken).toHaveBeenCalledWith(accessToken);
            expect(tokenService.revokeRefreshToken).toHaveBeenCalledWith(refreshToken);
        });
    });

    describe('refreshAuth', () => {
        it('should refresh tokens successfully', async () => {
            const refreshToken = 'valid-refresh-token';

            const result = await authService.refreshAuth(refreshToken);

            expect(tokenService.verifyRefreshToken).toHaveBeenCalledWith(refreshToken);
            expect(tokenService.revokeRefreshToken).toHaveBeenCalledWith(refreshToken);
            expect(tokenService.generateAuthTokens).toHaveBeenCalled();
            expect(result).toHaveProperty('access');
            expect(result).toHaveProperty('refresh');
        });

        it('should throw error with invalid refresh token', async () => {
            const refreshToken = 'invalid-refresh-token';

            await expect(authService.refreshAuth(refreshToken))
                .rejects.toThrow('Invalid token');
        });
    });

    describe('verifyEmail', () => {
        it('should verify email successfully', async () => {
            const verificationToken = 'verification-token';

            const result = await authService.verifyEmail(verificationToken);

            expect(User.findOne).toHaveBeenCalledWith({
                where: { verification_token: verificationToken }
            });
            expect(result).toHaveProperty('is_verified', true);
        });

        it('should throw error with invalid verification token', async () => {
            const verificationToken = 'invalid-token';

            await expect(authService.verifyEmail(verificationToken))
                .rejects.toThrow('Invalid or expired verification token');
        });
    });

    describe('requestPasswordReset', () => {
        it('should request password reset successfully', async () => {
            const email = 'test@example.com';

            const result = await authService.requestPasswordReset(email);

            expect(User.findByEmail).toHaveBeenCalledWith(email);
            expect(result).toHaveProperty('email', email);
            expect(result).toHaveProperty('resetToken');
            expect(result).toHaveProperty('expiresAt');
        });

        it('should return success message for non-existent email', async () => {
            const email = 'nonexistent@example.com';

            const result = await authService.requestPasswordReset(email);

            expect(result).toHaveProperty('message');
        });
    });

    describe('resetPassword', () => {
        it('should reset password successfully', async () => {
            const resetToken = 'valid-reset-token';
            const newPassword = 'newpassword123';

            const result = await authService.resetPassword(resetToken, newPassword);

            expect(User.findOne).toHaveBeenCalled();
            expect(result).toHaveProperty('id');
            expect(result).toHaveProperty('email');
        });

        it('should throw error with invalid reset token', async () => {
            const resetToken = 'invalid-reset-token';
            const newPassword = 'newpassword123';

            await expect(authService.resetPassword(resetToken, newPassword))
                .rejects.toThrow('Invalid or expired reset token');
        });
    });
}); 