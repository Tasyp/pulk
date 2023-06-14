import React from "react";

import { Board, BoardStatus, BoardUpdate } from "../../lib/board";
import { BoardSnapshotView } from "../../components";
import { useKeyboard } from "./hooks";

interface Props {
  board?: Board;
  setBoard: (boardUpdate: BoardUpdate) => void;
}

export const TetrisField: React.FunctionComponent<Props> = ({
  board,
  setBoard,
}) => {
  useKeyboard(board, setBoard);

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

  if (board === undefined) {
    return null;
  }

  return (
    <div>
      <BoardSnapshotView snapshot={board} hasActivePiece />
    </div>
  );
};
