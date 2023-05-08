import { useCallback, useContext, useEffect, useMemo, useState } from "react";

import { SocketContext } from "../../lib/socket";
import {
  RoomEventType,
  getRoomChannelId,
  onRoomMessage,
  pushRoomMessage,
} from "../../lib/room";
import { Matrix } from "../../lib/matrix";

export enum RoomErrorType {
  UNKNOWN_ROOM = "unknown_room",
  UNKNOWN = "room",
}

export const useRoom = ({
  roomId,
}: {
  roomId: string;
}): {
  isLoading: boolean;
  error: RoomErrorType | undefined;
  setMatrix: (matrix: Matrix) => void;
  otherPlayers: Map<string, Matrix>;
} => {
  const [roomJoinState, setRoomJoinState] = useState<"ok" | "failed" | "init">(
    "init"
  );
  const [errorReason, setErrorReason] = useState<undefined | RoomErrorType>(
    undefined
  );
  const [playerId, setPlayerId] = useState<string | undefined>(undefined);
  const [allPlayers, setAllPlayers] = useState(new Map<string, Matrix>());

  const otherPlayers = useMemo(
    () =>
      new Map(
        [...allPlayers.entries()].filter(
          ([currentPlayerId, _]) => playerId !== currentPlayerId
        )
      ),
    [allPlayers, playerId]
  );

  const socket = useContext(SocketContext);
  const channel = useMemo(
    () => socket.channel(getRoomChannelId(roomId), {}),
    [roomId]
  );

  useEffect(() => {
    channel
      .join()
      .receive("ok", (response) => {
        setPlayerId(response.player_id);
        setRoomJoinState("ok");
      })
      .receive("error", (response) => {
        setRoomJoinState("failed");
        setErrorReason(getRoomJoinError(response));
      });

    return () => {
      channel.leave();
    };
  }, [setRoomJoinState, setErrorReason, setPlayerId]);

  useEffect(() => {
    const ref = onRoomMessage(
      channel,
      RoomEventType.BOARD_UPDATE,
      ({ matrix, player_id }) => {
        setAllPlayers((acc) => new Map(acc.set(player_id, matrix)));
      }
    );

    return () => {
      channel.off(RoomEventType.BOARD_UPDATE, ref);
    };
  }, [setAllPlayers]);

  const setMatrix = useCallback(
    (matrix: Matrix): void => {
      pushRoomMessage(channel, RoomEventType.BOARD_UPDATE, { matrix });
    },
    [channel]
  );

  return {
    isLoading: roomJoinState === "init",
    error: roomJoinState === "failed" ? errorReason : undefined,
    setMatrix,
    otherPlayers,
  };
};

const getRoomJoinError = (response): RoomErrorType => {
  switch (response?.reason) {
    case "unknown_room":
      return RoomErrorType.UNKNOWN_ROOM;
    default:
      return RoomErrorType.UNKNOWN;
  }
};
