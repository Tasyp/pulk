import ReactDOM from "react-dom/client";

import { initSocket } from "./lib/socket";
import App from "./app.tsx";

const socket = initSocket();

ReactDOM.createRoot(document.getElementById("app")!).render(
  <App socket={socket} />
);
