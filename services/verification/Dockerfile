FROM node:20-alpine

# Set the working directory inside the container
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy source code
COPY . .

# Build TypeScript code
RUN npm run build

# Expose port
EXPOSE 3000

# Start the application
CMD ["node", "dist/server.js"]