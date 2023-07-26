import React from "react";
import { Route, Switch } from "wouter";

import { GameContainer, HomeContainer } from "./containers";

export const Router: React.FunctionComponent = () => {
  return (
    <Switch>
      <Route path="/">
        <HomeContainer />
      </Route>
      <Route<{ roomId: string }> path="/room/:roomId">
        {(params) => <GameContainer roomId={params.roomId} />}
      </Route>
    </Switch>
  );
};
