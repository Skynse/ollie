FROM node:20-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install --omit=dev

# Copy source code
COPY src ./src

# Expose the port
EXPOSE 3000

# Start the server
CMD ["npm", "start"]
