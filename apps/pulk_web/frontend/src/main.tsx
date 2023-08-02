import ReactDOM from "react-dom/client";
import { ThemeProvider } from "styled-components";

// TODO: Extract components we need and drop usage of react95
import original from "react95/dist/themes/original";

import { initSocket } from "./lib/socket";
import { GlobalStyles } from "./styles.tsx";
import App from "./app.tsx";

const socket = initSocket();

ReactDOM.createRoot(document.getElementById("app")!).render(
  <>
    <GlobalStyles />
    <ThemeProvider theme={original}>
      <App socket={socket} />
    </ThemeProvider>
  </>,
);
