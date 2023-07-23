import "./app.css";

import React from "react";
import { SWRConfig, SWRConfiguration } from "swr";
import { Socket } from "phoenix";

import { Router } from "./router";
import { SocketContext } from "./lib/socket";
import { PlayerProvider } from "./lib/player";

const SWR_CONFIG: SWRConfiguration = {
  fetcher: (resource, init) => fetch(resource, init).then((res) => res.json()),
};

interface Props {
  socket: Socket;
}

const App: React.FunctionComponent<Props> = ({ socket }) => {
  return (
    <SWRConfig value={SWR_CONFIG}>
      <SocketContext.Provider value={socket}>
        <PlayerProvider>
          <div className="main">
            <Router />
          </div>
        </PlayerProvider>
      </SocketContext.Provider>
    </SWRConfig>
  );
};

export default App;
