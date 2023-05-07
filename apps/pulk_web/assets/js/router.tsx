import React from "react";
import { Route } from "wouter";

import { GameContainer, HomeContainer } from "./containers";

export const Router: React.FunctionComponent = () => {
  return (
    <>
      <Route path="/">
        <HomeContainer />
      </Route>
      <Route<{ roomId: string }> path="/room/:roomId">
        {(params) => <GameContainer roomId={params.roomId} />}
      </Route>
    </>
  );
};
