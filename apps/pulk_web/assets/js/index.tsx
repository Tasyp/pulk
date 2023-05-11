import React from "react";
import { SWRConfig } from "swr";
import { styled } from "goober";
import { Socket } from "phoenix";

import { Router } from "./router";
import { SocketContext } from "./lib/socket";
import { PlayerProvider } from "./lib/player";

const Container = styled("div")`
  height: 100%;
  width: 100%;
  margin: 0;
  padding: 0;
`;

export const SWR_CONFIG = {
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
          <Container>
            <Router />
          </Container>
        </PlayerProvider>
      </SocketContext.Provider>
    </SWRConfig>
  );
};

export default App;
