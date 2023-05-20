import "../css/app.css";

import "phoenix_html";
import React from "react";
import { createRoot } from "react-dom/client";
import { setup } from "goober";
import { initSocket } from "./lib/socket";

import App from ".";

const socket = initSocket();

setup(React.createElement);

const container = document.getElementById("app");
const root = createRoot(container!);
root.render(<App socket={socket} />);
