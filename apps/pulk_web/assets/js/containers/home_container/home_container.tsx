import React from "react";
import { useLocation } from "wouter";

import { useAvailableRoom } from "./hooks";

export const HomeContainer: React.FunctionComponent = () => {
  const { roomId } = useAvailableRoom();
  const [_, setLocation] = useLocation();

  if (roomId !== undefined) {
    setLocation(`/room/${roomId}`);
  }

  return <div>Loading...</div>;
};
