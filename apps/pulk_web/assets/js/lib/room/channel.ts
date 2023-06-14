import { Channel } from "phoenix";
import { BoardStatus, Matrix, Piece } from "../board";

export type PlayerId = string;

export enum RoomErrorType {
  UNKNOWN_ROOM = "unknown_room",
  UNKNOWN = "room",
}

export type IncomingBoardSnapshot = {
  matrix: Matrix;
  status: BoardStatus;
  active_piece: {
    piece: Piece;
    coordinates: [x: number, y: number][];
  } | null;
};

export type RoomJoinPayload = {
  player_board: {
    matrix: Matrix;
    score: number;
    level: number;
    placement: number | null;
    status: BoardStatus;
    active_piece: {
      piece: Piece;
      coordinates: [x: number, y: number][];
    } | null;
    piece_in_hold: Piece | null;
  };
  other_snapshots: Record<PlayerId, IncomingBoardSnapshot>;
};

export const onRoomJoin = (
  channel: Channel,
  onSuccess: (payload: RoomJoinPayload) => void,
  onError: (error: RoomErrorType) => void
) => {
  channel
    .join()
    .receive("ok", (response) => onSuccess(response))
    .receive("error", (response) => onError(getRoomJoinError(response)));
};

const getRoomJoinError = (response): RoomErrorType => {
  switch (response?.reason) {
    case "unknown_room":
      return RoomErrorType.UNKNOWN_ROOM;
    default:
      return RoomErrorType.UNKNOWN;
  }
};

export enum RoomOutgoingEventType {
  BOARD_UPDATE = "board_update",
}

// @type direction() :: :down | :left | :right

// @type update_type() :: :simple | :soft_drop_start | :soft_drop_stop | :hard_drop

export enum UpdateType {
  SIMPLE = "simple",
  SOFT_DROP_START = "soft_drop_start",
  SOFT_DROP_STOP = "soft_drop_stop",
  HARD_DROP = "hard_drop",
}

export enum Rotation {
  SPAWN_STATE = "O", // spawn state
  CLOCKWISE = "R", // state resulting from a clockwise rotation ("right") from spawn
  COUNTER_CLOCKWISE = "L", // state resulting from a counter-clockwise ("left") rotation from spawn
  DOUBLE = "TWO", // state resulting from 2 successive rotations in either direction from spawn.
}

export enum Direction {
  DOWN = "down",
  LEFT = "left",
  RIGHT = "right",
}

export type PiecePositionUpdate =
  | {
    piece: Piece;
    update_type: UpdateType.SIMPLE;
    rotation: Rotation;
  }
  | {
    piece: Piece;
    update_type: UpdateType.SIMPLE;
    direction: Direction;
  }
  | {
    piece: Piece;
    update_type: Exclude<UpdateType, UpdateType.SIMPLE>;
  };

export type RoomOutgoingMessagePayload = {
  [RoomOutgoingEventType.BOARD_UPDATE]: {
    payload: {
      active_piece_update: PiecePositionUpdate;
      piece_in_hold: Piece | null;
    };
    success: {
      matrix: Matrix;
      active_piece: {
        piece: Piece;
        coordinates: [x: number, y: number][];
      } | null;
      piece_in_hold: Piece | null;
      score: number;
      status: BoardStatus;
      cleared_lines_count: number;
      level: number;
      placement: number;
    };
  };
};

const noOp = () => { };

export const pushRoomMessage = <T extends RoomOutgoingEventType>(
  channel: Channel,
  messageType: T,
  payload: RoomOutgoingMessagePayload[T]["payload"],
  onSuccess?: (payload: RoomOutgoingMessagePayload[T]["success"]) => void
) => {
  channel.push(messageType, payload).receive("ok", onSuccess ?? noOp);
};

export enum RoomIncomingEventType {
  BOARD_SNAPSHOT_UPDATE = "board_snapshot_update",
  BOARD_UPDATE = "board_update",
}

export type RoomIncomingMessagePayload = {
  [RoomIncomingEventType.BOARD_SNAPSHOT_UPDATE]: {
    board_snapshot: IncomingBoardSnapshot;
    player_id: string;
  };
  [RoomIncomingEventType.BOARD_UPDATE]: {
    matrix: Matrix;
    active_piece: {
      piece: Piece;
      coordinates: [x: number, y: number][];
    } | null;
    piece_in_hold: Piece | null;
    score: number;
    status: BoardStatus;
    cleared_lines_count: number;
    level: number;
    placement: number;
  };
};

export function onRoomMessage<T extends RoomIncomingEventType>(
  channel: Channel,
  messageType: T,
  callback: (payload: RoomIncomingMessagePayload[T]) => void
): number {
  return channel.on(messageType, callback);
}
