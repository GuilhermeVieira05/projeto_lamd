// NOTE: src/server.ts uses app.listen(PORT, ...) which returns an http.Server internally
// but does not expose it. To attach the WebSocket server, server.ts must be updated to
// use http.createServer(app) explicitly and pass that server to initWebSocketServer().
// Example:
//   const httpServer = http.createServer(app);
//   initWebSocketServer(httpServer);
//   httpServer.listen(PORT, () => { ... });

import { Server } from 'http';
import { WebSocketServer } from 'ws';
import { URL } from 'url';
import jwt from 'jsonwebtoken';
import { wsRegistry } from './ws.registry';

interface JwtPayload {
  sub: string;
  role: string;
  name: string;
}

export function initWebSocketServer(httpServer: Server): void {
  const wss = new WebSocketServer({ server: httpServer });

  wss.on('connection', (ws, req) => {
    const requestUrl = req.url ?? '';
    const params = new URL(requestUrl, 'ws://localhost').searchParams;
    const token = params.get('token');

    if (!token) {
      ws.close(4001, 'Missing token');
      return;
    }

    let payload: JwtPayload;

    try {
      payload = jwt.verify(token, process.env.JWT_SECRET ?? 'secret') as JwtPayload;
    } catch {
      ws.close(4001, 'Invalid token');
      return;
    }

    const userId = payload.sub;
    wsRegistry.register(userId, ws);
    console.info(`[WS] User ${userId} connected`);

    ws.on('close', () => {
      wsRegistry.unregister(userId);
      console.info(`[WS] User ${userId} disconnected`);
    });
  });
}
