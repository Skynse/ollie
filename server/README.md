# Ollie Real-time Server

Socket.IO server for real-time multiplayer features in Ollie (cursor positions, live updates, etc.)

## Local Development

### Prerequisites
- Node.js 20+
- npm or yarn

### Install and Run

```bash
cd server
npm install
npm run dev
```

The server will start on `http://localhost:3000`

## Docker Deployment

### Build and Run with Docker

```bash
cd server
docker build -t ollie-realtime .
docker run -p 3000:3000 ollie-realtime
```

### Using Docker Compose

```bash
cd server
docker-compose up -d
```

### Deploy to Digital Ocean

1. **Create a Docker Droplet** on Digital Ocean
2. **SSH into your droplet**
3. **Clone your repo** and navigate to the server directory
4. **Run with docker-compose**:
   ```bash
   docker-compose up -d
   ```

5. **Configure firewall** to allow port 3000 (or use nginx as reverse proxy)

## Environment Variables

- `PORT` - Server port (default: 3000)
- `NODE_ENV` - Environment (production/development)

## API Endpoints

### Health Check
```
GET /health
```

Returns server status and statistics.

## Socket.IO Events

### Client → Server

- `join-board` - Join a board room
  ```js
  { boardId, userId, userName, color }
  ```

- `cursor-move` - Update cursor position
  ```js
  { boardId, userId, userName, x, y, color }
  ```

### Server → Client

- `cursors-state` - Initial cursors when joining
  ```js
  { [userId]: { userId, userName, x, y, color }, ... }
  ```

- `cursor-update` - Another user's cursor moved
  ```js
  { userId, userName, x, y, color }
  ```

- `cursor-remove` - A user disconnected
  ```js
  { userId }
  ```
