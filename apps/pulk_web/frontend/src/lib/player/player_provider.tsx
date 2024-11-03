import React, { PropsWithChildren } from "react";
import useSWRImmutable from "swr/immutable";

import { PlayerContext } from "./player_context";
import { LoadingSpinner } from "../../components";
import { useCachedPlayer } from "./cached_player";

export const PlayerProvider: React.FunctionComponent<PropsWithChildren> = ({
  children,
}) => {
  const [cachedPlayerId, setCachedPlayerId] = useCachedPlayer();
  const { data, error, isLoading } = useSWRImmutable(() =>
    cachedPlayerId === undefined ? "/api/player" : null,
  );

  React.useEffect(() => {
    if (cachedPlayerId !== undefined) {
      return;
    }

    setCachedPlayerId(data?.data.player_id);
  }, [setCachedPlayerId, data, cachedPlayerId]);

  const value = React.useMemo(() => {
    if (cachedPlayerId !== undefined) {
      return { playerId: cachedPlayerId, isLoading: false };
    }

    if (isLoading) {
      return { playerId: undefined, isLoading: true };
    }

    if (error !== undefined) {
      return { playerId: undefined, isLoading: false };
    }

    return { playerId: data?.data.player_id, isLoading: false };
  }, [cachedPlayerId, isLoading, error, data]);

  if (value.isLoading) {
    return <LoadingSpinner />;
  }

  if (value.playerId === undefined) {
    return <>Cannot fetch player</>;
  }

  return (
    <PlayerContext.Provider value={value}>{children}</PlayerContext.Provider>
  );
};
