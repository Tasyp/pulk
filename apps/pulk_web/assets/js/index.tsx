import React from "react";
import { GameContainer } from "./containers ";
import { styled } from "goober";

const Container = styled('div')`
  height: 100%;
  width: 100%;
  margin: 0;
  padding: 0;
`

const App: React.FunctionComponent = () => {
  return (
    <Container>
      <GameContainer />
    </Container>
  );
};

export default App;
