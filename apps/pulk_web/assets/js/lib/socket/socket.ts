import { Socket } from "phoenix";

export const initSocket = (): Socket => {
  const socket = new Socket("/socket");
  socket.connect();
  return socket;
};
