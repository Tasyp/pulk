import React from "react";
import { Route } from "wouter";

import { GameContainer } from "./containers";
import { LoginPage } from "./pages";

export const Router: React.FunctionComponent = () => {
  return (
    <>
      <Route path="/">
        <LoginPage />
      </Route>
      <Route<{ roomId: string }> path="/room/:roomId">
        {(params) => <GameContainer roomId={params.roomId} />}
      </Route>
    </>
  );
};
