import { useCallback, useContext, useEffect, useMemo, useState } from "react";

import { SocketContext } from "../../lib/socket";
import {
  RoomEventType,
  getRoomChannelId,
  onRoomMessage,
  pushRoomMessage,
} from "../../lib/room";
import { Matrix } from "../../lib/matrix";
import { usePlayer } from "../../lib/player";

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
  player: { matrix: Matrix };
  otherPlayers: Map<string, Matrix>;
} => {
  const { playerId } = usePlayer();
  const [roomJoinState, setRoomJoinState] = useState<"ok" | "failed" | "init">(
    "init"
  );
  const [errorReason, setErrorReason] = useState<undefined | RoomErrorType>(
    undefined
  );
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
    () => socket.channel(getRoomChannelId(roomId), { player_id: playerId }),
    [roomId, playerId]
  );

  useEffect(() => {
    channel
      .join()
      .receive("ok", (response) => {
        setAllPlayers((allPayers) => {
          const nextPlayers = Object.entries(
            response.boards as Map<string, { matrix: Matrix }>
          ).reduce(
            (acc, [playerId, board]) => acc.set(playerId, board.matrix),
            allPayers
          );
          return new Map(nextPlayers);
        });
        setRoomJoinState("ok");
      })
      .receive("error", (response) => {
        setRoomJoinState("failed");
        setErrorReason(getRoomJoinError(response));
      });

    return () => {
      channel.leave();
    };
  }, [setRoomJoinState, setAllPlayers, setErrorReason]);

  useEffect(() => {
    const ref = onRoomMessage(
      channel,
      RoomEventType.BOARD_UPDATE,
      ({ board, player_id }) => {
        if (playerId === player_id) {
          return;
        }

        setAllPlayers((acc) => new Map(acc.set(player_id, board)));
      }
    );

    return () => {
      channel.off(RoomEventType.BOARD_UPDATE, ref);
    };
  }, [setAllPlayers, playerId]);

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
    player: {
      matrix: allPlayers.get(playerId)!,
    },
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
