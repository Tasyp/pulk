import React from "react";
import ReactDOM from "react-dom/client";
import { setup } from "goober";

import { initSocket } from "./lib/socket";
import App from "./app.tsx";

setup(React.createElement);

const socket = initSocket();

ReactDOM.createRoot(document.getElementById("root")!).render(
  <App socket={socket} />
);
