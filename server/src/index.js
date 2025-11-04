const express = require("express");
const { createServer } = require("http");
const { WebSocketServer } = require("ws");
const cors = require("cors");

const app = express();
app.use(cors());

const httpServer = createServer(app);
const wss = new WebSocketServer({ server: httpServer });

// Store active connections per board
const boardConnections = new Map();

wss.on("connection", (ws) => {
  console.log("Client connected");

  ws.isAlive = true;
  ws.on("pong", () => {
    ws.isAlive = true;
  });

  ws.on("message", (data) => {
    try {
      const message = JSON.parse(data.toString());

      switch (message.type) {
        case "join-board":
          handleJoinBoard(ws, message);
          break;

        case "cursor-move":
          handleCursorMove(ws, message);
          break;

        case "leave-board":
          handleLeaveBoard(ws);
          break;
      }
    } catch (error) {
      console.error("Error parsing message:", error);
    }
  });

  ws.on("close", () => {
    console.log("Client disconnected");
    handleLeaveBoard(ws);
  });
});

function handleJoinBoard(ws, message) {
  const { boardId, userId, userName, color } = message;

  ws.boardId = boardId;
  ws.userId = userId;
  ws.userName = userName;
  ws.userColor = color;

  console.log(`User ${userName} (${userId}) joined board ${boardId}`);

  // Initialize board connections if it doesn't exist
  if (!boardConnections.has(boardId)) {
    boardConnections.set(boardId, new Map());
  }

  // Add this connection to the board
  boardConnections.get(boardId).set(userId, ws);

  // Send current cursors in this board to the newly joined user
  const cursorsInBoard = boardConnections.get(boardId);
  const currentCursors = {};

  cursorsInBoard.forEach((conn, uid) => {
    if (uid !== userId && conn.lastCursor) {
      currentCursors[uid] = conn.lastCursor;
    }
  });

  ws.send(
    JSON.stringify({
      type: "cursors-state",
      cursors: currentCursors,
    }),
  );
}

function handleCursorMove(ws, message) {
  const { boardId, userId, userName, x, y, color } = message;

  if (!ws.boardId || ws.boardId !== boardId) {
    return; // Client must join board first
  }

  const cursorData = { userId, userName, x, y, color };
  ws.lastCursor = cursorData;

  // Broadcast to all other users in the same board
  const connectionsInBoard = boardConnections.get(boardId);
  if (connectionsInBoard) {
    connectionsInBoard.forEach((conn, uid) => {
      if (uid !== userId && conn.readyState === 1) {
        // 1 = OPEN
        conn.send(
          JSON.stringify({
            type: "cursor-update",
            cursor: cursorData,
          }),
        );
      }
    });
  }
}

function handleLeaveBoard(ws) {
  console.log(
    `handleLeaveBoard called - boardId: ${ws.boardId}, userId: ${ws.userId}`,
  );

  if (ws.boardId && ws.userId) {
    const connectionsInBoard = boardConnections.get(ws.boardId);
    if (connectionsInBoard) {
      connectionsInBoard.delete(ws.userId);
      console.log(`Removed user ${ws.userId} from board ${ws.boardId}`);

      // Notify others that this user left
      connectionsInBoard.forEach((conn) => {
        if (conn.readyState === 1) {
          console.log(`Notifying about removal of ${ws.userId}`);
          conn.send(
            JSON.stringify({
              type: "cursor-remove",
              userId: ws.userId,
            }),
          );
        }
      });

      // Clean up empty board maps
      if (connectionsInBoard.size === 0) {
        boardConnections.delete(ws.boardId);
        console.log(`Deleted empty board ${ws.boardId}`);
      }
    }
  } else {
    console.log("handleLeaveBoard: boardId or userId not set");
  }
}

// Heartbeat to detect broken connections
const interval = setInterval(() => {
  wss.clients.forEach((ws) => {
    if (ws.isAlive === false) {
      handleLeaveBoard(ws);
      return ws.terminate();
    }

    ws.isAlive = false;
    ws.ping();
  });
}, 30000);

wss.on("close", () => {
  clearInterval(interval);
});

// Health check endpoint
app.get("/health", (req, res) => {
  res.json({
    status: "ok",
    uptime: process.uptime(),
    activeBoards: boardConnections.size,
    totalConnections: wss.clients.size,
  });
});

const PORT = process.env.PORT || 3000;

httpServer.listen(PORT, () => {
  console.log(`Ollie Real-time WebSocket Server running on port ${PORT}`);
});
