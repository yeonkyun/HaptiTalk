FROM node:18-alpine

WORKDIR /app

COPY api/feedback-service/package*.json ./

RUN npm install

COPY api/shared /app/api/shared

COPY api/feedback-service .

EXPOSE ${PORT}

HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD wget -qO- http://localhost:${PORT:-3003}/health || exit 1

CMD ["npm", "start"]