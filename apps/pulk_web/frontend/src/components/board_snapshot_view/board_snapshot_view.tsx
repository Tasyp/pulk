import React from "react";
import classNames from "classnames";
import { Matrix } from "react-tetris/lib/models/Matrix";

import styles from "./board_snapshot_view.module.css";

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
      bufferZoneSize,
    ),
  );

  return (
    <table>
      <tbody>
        {matrix.map((row, i) => (
          <tr key={i}>
            {row.map((block, j) => (
              <td
                key={j}
                className={classNames(
                  styles["game-block"],
                  getBlockClass(block),
                )}
              />
            ))}
          </tr>
        ))}
      </tbody>
    </table>
  );
};

const getBlockClass = (block: Matrix[number][number]): string => {
  switch (block) {
    case "I":
      return styles["piece-i"];
    case "J":
      return styles["piece-j"];
    case "L":
      return styles["piece-l"];
    case "O":
      return styles["piece-o"];
    case "S":
      return styles["piece-s"];
    case "T":
      return styles["piece-t"];
    case "Z":
      return styles["piece-z"];
    case "ghost":
      return styles["piece-preview"];
    default:
      return "";
  }
};
