import React from "react";
import { Socket } from "phoenix";

export const SocketContext = React.createContext<Socket>(
  new Socket("/api/socket"),
);
