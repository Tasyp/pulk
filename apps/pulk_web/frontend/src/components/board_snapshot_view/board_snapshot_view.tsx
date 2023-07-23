import React from "react";
import { getClassName } from "react-tetris/lib/models/Piece";

import {
  BoardSnapshot,
  addPiece,
  composeTetrisMatrix,
  hideBufferZone,
} from "../../lib/board";

interface Props {
  snapshot: BoardSnapshot;
  hasActivePiece?: boolean;
}

export const BoardSnapshotView: React.FunctionComponent<Props> = ({
  snapshot: { matrix: inputMatrix, activePiece, bufferZoneSize },
  hasActivePiece = true,
}) => {
  const matrix = composeTetrisMatrix(
    hideBufferZone(
      hasActivePiece && activePiece !== null
        ? addPiece(inputMatrix, activePiece)
        : inputMatrix,
      bufferZoneSize
    )
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
