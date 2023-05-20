import React from "react";
import { getClassName } from "react-tetris/lib/models/Piece";

import { BoardSnapshot, addPiece, composeTetrisMatrix } from "../../lib/board";

interface Props {
  snapshot: BoardSnapshot;
}

export const BoardSnapshotView: React.FunctionComponent<Props> = ({
  snapshot: { matrix: inputMatrix, activePiece },
}) => {
  const matrix = composeTetrisMatrix(
    activePiece !== null ? addPiece(inputMatrix, activePiece) : inputMatrix
  );
  return (
    <table className="game-board">
      <tbody>
        {matrix.map((row, i) => {
          const blocksInRow = row.map((block, j) => {
            const classString = `game-block ${
              block ? getClassName(block) : "block-empty"
            }`;
            return <td key={j} className={classString} />;
          });

          return <tr key={i}>{blocksInRow}</tr>;
        })}
      </tbody>
    </table>
  );
};
