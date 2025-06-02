const swaggerJsdoc = require('swagger-jsdoc');
const swaggerUi = require('swagger-ui-express');

// Swagger 정의
const options = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'HaptiTalk 실시간 서비스 API',
      version: '0.1.0',
      description: '웹소켓 및 실시간 이벤트 처리 API',
      contact: {
        name: 'HaptiTalk 개발팀'
      },
    },
    servers: [
      {
        url: '',
        description: '실시간 서비스 API 엔드포인트'
      }
    ],
    components: {
      securitySchemes: {  
        bearerAuth: {
          type: 'http',
          scheme: 'bearer',
          bearerFormat: 'JWT'
        }
      }
    },
    security: [{
      bearerAuth: []
    }]
  },
  // API 경로 패턴
  apis: [
    './src/routes/*.js',
    './src/models/*.js',
    './src/controllers/*.js',
    './src/events/*.js'
  ]
};

const specs = swaggerJsdoc(options);

module.exports = {
  swaggerUi,
  specs
}; 