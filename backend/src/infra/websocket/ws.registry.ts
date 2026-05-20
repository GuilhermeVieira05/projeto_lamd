import { WebSocket } from 'ws';

const registry = new Map<string, WebSocket>();

export const wsRegistry = {
  register(userId: string, ws: WebSocket): void {
    registry.set(userId, ws);
  },

  unregister(userId: string): void {
    registry.delete(userId);
  },

  send(userId: string, event: string, payload: object): void {
    const ws = registry.get(userId);
    if (ws && ws.readyState === WebSocket.OPEN) {
      ws.send(JSON.stringify({ event, payload }));
    }
  },

  get(userId: string): WebSocket | undefined {
    return registry.get(userId);
  },
};
