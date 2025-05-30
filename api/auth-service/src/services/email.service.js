const logger = require('../utils/logger');

// 이 서비스는 실제 이메일 전송 구현 필요 (예: nodemailer)
// 현재는 로깅만 하는 간단한 구현
const emailService = {
    /**
     * Send verification email
     * @param {string} email - Recipient email
     * @param {string} token - Verification token
     */
    sendVerificationEmail: async (email, token) => {
        try {
            // 이메일 전송 로직 대신 로깅
            const verificationUrl = `${process.env.FRONTEND_URL}/verify-email?token=${token}`;

            logger.info(`인증 이메일 전송 성공: ${email}`, {
                recipient: email,
                tokenPrefix: token.substring(0, 8) + '...',
                verificationUrl
            });

            // 실제 구현에서는 nodemailer 등을 사용하여 이메일 전송
            return true;
        } catch (error) {
            logger.error('Error sending verification email:', error);
            throw error;
        }
    },

    /**
     * Send password reset email
     * @param {string} email - Recipient email
     * @param {string} token - Reset token
     */
    sendPasswordResetEmail: async (email, token) => {
        try {
            // 이메일 전송 로직 대신 로깅
            const resetUrl = `${process.env.FRONTEND_URL}/reset-password?token=${token}`;

            logger.info(`비밀번호 재설정 이메일 전송 성공: ${email}`, {
                recipient: email,
                tokenPrefix: token.substring(0, 8) + '...',
                resetUrl
            });

            // 실제 구현에서는 nodemailer 등을 사용하여 이메일 전송
            return true;
        } catch (error) {
            logger.error('Error sending password reset email:', error);
            throw error;
        }
    }
};

module.exports = emailService;