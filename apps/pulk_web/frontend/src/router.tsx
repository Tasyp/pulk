import React from "react";
import { Route } from "wouter";

import { LoginPage, RoomPage } from "./pages";

export const Router: React.FunctionComponent = () => {
  return (
    <>
      <Route path="/">
        <LoginPage />
      </Route>
      <Route<{ roomId: string }> path="/room/:roomId">
        {(params) => <RoomPage roomId={params.roomId} />}
      </Route>
    </>
  );
};
