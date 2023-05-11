import React, { useContext } from "react";

export const PlayerContext = React.createContext({
  playerId: "",
});

export const usePlayer = () => {
  const player = useContext(PlayerContext);
  return player;
};
