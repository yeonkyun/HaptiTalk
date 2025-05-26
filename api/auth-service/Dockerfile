# Base image
FROM node:18-alpine

# Set working directory
WORKDIR /app

# Install build dependencies
RUN apk update && \
    apk add --no-cache make gcc g++ python3 linux-headers

# Copy package.json and package-lock.json
COPY api/auth-service/package*.json ./

# Install dependencies
RUN npm ci --production && \
    npm install morgan prom-client

# Copy shared modules first
COPY api/shared /app/api/shared

# Copy source code
COPY api/auth-service .

# Create logs directory
RUN mkdir -p logs

# Expose port
EXPOSE 3001

# Run the application
CMD ["node", "src/app.js"]