import React from "react";
import { useHotkeys } from "react-hotkeys-hook";

import { Board, BoardStatus, BoardUpdate } from "../../lib/board";
import { BoardSnapshotView } from "../../components";
import { Direction, UpdateType } from "../../lib/room";

interface Props {
  board?: Board;
  setBoard: (boardUpdate: BoardUpdate) => void;
}

export const TetrisField: React.FunctionComponent<Props> = ({
  board,
  setBoard,
}) => {
  if (
    board !== undefined &&
    (board?.status === BoardStatus.COMPLETE || board?.placement !== null)
  ) {
    return (
      <div>
        <p>Place: {board.placement}</p>
        <BoardSnapshotView snapshot={board} hasActivePiece={false} />
      </div>
    );
  }

  useHotkeys(
    "down",
    () => {
      if (board === undefined || board.activePiece == undefined) {
        return;
      }

      setBoard({
        activePieceUpdate: {
          piece: board.activePiece.piece,
          update_type: UpdateType.SIMPLE,
          direction: Direction.DOWN,
        },
        pieceInHold: null,
      });
    },
    { preventDefault: true },
    [board]
  );
  useHotkeys(
    "left",
    () => {
      if (board === undefined || board.activePiece == undefined) {
        return;
      }

      setBoard({
        activePieceUpdate: {
          piece: board.activePiece.piece,
          update_type: UpdateType.SIMPLE,
          direction: Direction.LEFT,
        },
        pieceInHold: null,
      });
    },
    { preventDefault: true },
    [board]
  );
  useHotkeys(
    "right",
    () => {
      if (board === undefined || board.activePiece == undefined) {
        return;
      }

      setBoard({
        activePieceUpdate: {
          piece: board.activePiece.piece,
          update_type: UpdateType.SIMPLE,
          direction: Direction.RIGHT,
        },
        pieceInHold: null,
      });
    },
    { preventDefault: true },
    [board]
  );
  useHotkeys(
    "space",
    () => {
      if (board === undefined || board.activePiece == undefined) {
        return;
      }

      setBoard({
        activePieceUpdate: {
          piece: board.activePiece.piece,
          update_type: UpdateType.HARD_DROP,
        },
        pieceInHold: null,
      });
    },
    { preventDefault: true },
    [board]
  );

  if (board === undefined) {
    return null;
  }

  return (
    <div>
      <BoardSnapshotView snapshot={board} hasActivePiece />
    </div>
  );
};
