import React from "react";
import { SWRConfig } from "swr";
import { styled } from "goober";

import { Router } from "./router";

const Container = styled("div")`
  height: 100%;
  width: 100%;
  margin: 0;
  padding: 0;
`;

const App: React.FunctionComponent = () => {
  return (
    <SWRConfig
      value={{
        fetcher: (resource, init) =>
          fetch(resource, init).then((res) => res.json()),
      }}
    >
      <Container>
        <Router />
      </Container>
    </SWRConfig>
  );
};

export default App;
