import { useCallback, useContext, useEffect, useMemo, useState } from "react";

import { SocketContext } from "../../lib/socket";
import {
  RoomErrorType,
  RoomIncomingEventType,
  RoomOutgoingEventType,
  getRoomChannelId,
  onRoomJoin,
  onRoomMessage,
  pushRoomMessage,
} from "../../lib/room";
import { BoardUpdate, Board, BoardSnapshot } from "../../lib/board";
import { usePlayer } from "../../lib/player";

export const useRoom = ({
  roomId,
}: {
  roomId: string;
}): {
  isLoading: boolean;
  error: RoomErrorType | undefined;
  setBoard: (boardUpdate: BoardUpdate) => void;
  player: Board | undefined;
  otherPlayers: Map<string, BoardSnapshot>;
} => {
  const { playerId } = usePlayer();
  const [roomJoinState, setRoomJoinState] = useState<"ok" | "failed" | "init">(
    "init"
  );
  const [errorReason, setErrorReason] = useState<undefined | RoomErrorType>(
    undefined
  );
  const [playerBoard, setPlayerBoard] = useState<Board | null>(null);
  const [otherPlayers, setOtherPlayers] = useState(
    new Map<string, BoardSnapshot>()
  );

  const socket = useContext(SocketContext);
  const channel = useMemo(
    () => socket.channel(getRoomChannelId(roomId), { player_id: playerId }),
    [roomId, playerId]
  );

  useEffect(() => {
    onRoomJoin(
      channel,
      (payload) => {
        setOtherPlayers(
          new Map(
            Object.entries(payload.other_snapshots).map(
              ([playerId, snapshot]) => [
                playerId,
                {
                  matrix: snapshot.matrix,
                  activePiece: snapshot.active_piece,
                  bufferZoneSize: snapshot.buffer_zone_size,
                  status: snapshot.status,
                },
              ]
            )
          )
        );

        const {
          matrix: matrix,
          active_piece: activePiece,
          piece_in_hold: pieceInHold,
          score: score,
          level: level,
          status: status,
          placement: placement,
          buffer_zone_size: bufferZoneSize,
        } = payload.player_board;

        setPlayerBoard({
          matrix,
          activePiece,
          pieceInHold,
          score,
          level,
          status,
          placement,
          bufferZoneSize,
        });
        setRoomJoinState("ok");
      },
      (error) => {
        setRoomJoinState("failed");
        setErrorReason(error);
      }
    );

    return () => {
      channel.leave();
    };
  }, [setRoomJoinState, setOtherPlayers, setErrorReason]);

  useEffect(() => {
    const snapshotRef = onRoomMessage(
      channel,
      RoomIncomingEventType.BOARD_SNAPSHOT_UPDATE,
      ({ board_snapshot, player_id }) => {
        if (playerId === player_id) {
          return;
        }

        setOtherPlayers(
          (acc) =>
            new Map(
              acc.set(player_id, {
                matrix: board_snapshot.matrix,
                activePiece: board_snapshot.active_piece,
                status: board_snapshot.status,
                bufferZoneSize: board_snapshot.buffer_zone_size,
              })
            )
        );
      }
    );

    const boardRef = onRoomMessage(
      channel,
      RoomIncomingEventType.BOARD_UPDATE,
      (response) => {
        setPlayerBoard((board) =>
          board !== null
            ? {
                ...board,
                pieceInHold: response.piece_in_hold,
                activePiece: response.active_piece,
                placement: response.placement,
                matrix: response.matrix,
                score: response.score,
                level: response.level,
                status: response.status,
              }
            : null
        );
      }
    );

    return () => {
      channel.off(RoomIncomingEventType.BOARD_SNAPSHOT_UPDATE, snapshotRef);
      channel.off(RoomIncomingEventType.BOARD_UPDATE, boardRef);
    };
  }, [setOtherPlayers, playerId]);

  const setBoard = useCallback(
    (boardUpdate: BoardUpdate): void => {
      pushRoomMessage(channel, RoomOutgoingEventType.BOARD_UPDATE, {
        active_piece_update: boardUpdate.activePieceUpdate,
      });
    },
    [channel, setPlayerBoard]
  );

  return {
    isLoading: roomJoinState === "init",
    error: roomJoinState === "failed" ? errorReason : undefined,
    setBoard,
    player: playerBoard ?? undefined,
    otherPlayers,
  };
};
