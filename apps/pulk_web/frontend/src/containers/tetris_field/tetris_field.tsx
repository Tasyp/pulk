import React from "react";

import { Board, BoardUpdate } from "../../lib/board";
import { BoardSnapshotView } from "../../components";
import { useKeyboard } from "./hooks";

import blockO from "./assets/block-o.png";
import blockS from "./assets/block-s.png";
import blockI from "./assets/block-i.png";

import styles from "./tetris_field.module.css";

interface Props {
  board?: Board;
  setBoard: (boardUpdate: BoardUpdate) => void;
}

export const TetrisField: React.FunctionComponent<Props> = ({
  board,
  setBoard,
}) => {
  useKeyboard(board, setBoard);

  // if (
  //   board !== undefined &&
  //   (board?.status === BoardStatus.COMPLETE || board?.placement !== null)
  // ) {
  //   return (
  //     <div>
  //       <p>Place: {board.placement}</p>
  //       <BoardSnapshotView snapshot={board} hasActivePiece={false} />
  //     </div>
  //   );
  // }

  if (board === undefined) {
    return null;
  }

  return (
    <div className={styles.container}>
      <div className={styles.statusBar}>
        <div className={styles.queuePreview}>
          <div className={styles.blockTitle}>Next</div>
          <div>
            <img src={blockO} />
          </div>
          <div>
            <img src={blockS} />
          </div>
          <div>
            <img src={blockI} />
          </div>
        </div>
        <div className={styles.holdPiece}>
          <div className={styles.blockTitle}>Hold</div>
          <div>
            <img src={blockO} />
          </div>
        </div>
        <div className={styles.placeContainer}>
          <div className={styles.blockTitle}>Place</div>
          <div className={styles.title}>64/90</div>
          <div>
            <div className={styles.subtitle}>Score</div>
            <div className={styles.title}>53123</div>
          </div>
        </div>
      </div>
      <div className={styles.field}>
        <BoardSnapshotView snapshot={board} hasActivePiece />
      </div>
    </div>
  );
};
