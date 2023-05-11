import React from "react";
import useSWR from "swr";

import { usePlayer } from "../../lib/player";

const fetcher = ([resource], init) =>
  fetch(resource, init).then((res) => res.json());

export const useAvailableRoom = (): {
  roomId: string | undefined;
  isLoading: boolean;
} => {
  const { playerId } = usePlayer();
  const random = React.useRef(Date.now());
  const { data, error, isLoading } = useSWR<{ data: { room_id: string } }>(
    () => [`/api/room?player_id=${playerId}`, random],
    fetcher
  );

  if (isLoading) {
    return { roomId: undefined, isLoading: true };
  }

  if (error !== undefined) {
    return { roomId: undefined, isLoading: false };
  }

  return { roomId: data?.data.room_id, isLoading: false };
};
