import { Socket } from "phoenix";

export const initSocket = (): Socket => {
  const socket = new Socket("/api/socket");
  socket.connect();
  return socket;
};
