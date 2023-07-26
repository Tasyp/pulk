import React from "react";
import { Redirect } from "wouter";

import { useAvailableRoom } from "./hooks";
import { LoadingSpinner } from "../../components";

export const HomeContainer: React.FunctionComponent = () => {
  const { roomId } = useAvailableRoom();

  if (roomId !== undefined) {
    return <Redirect to={`/room/${roomId}`} />;
  }

  return <LoadingSpinner />;
};
