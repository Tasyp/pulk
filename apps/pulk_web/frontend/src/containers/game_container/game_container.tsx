import React from "react";
import classNames from "classnames";

import { TetrisField } from "../tetris_field";
import { BoardSnapshotView } from "../../components";
import { Board, BoardSnapshot, BoardUpdate } from "../../lib/board";

import styles from "./game_container.module.css";

interface Props {
  player: Board;
  otherPlayers: Map<string, BoardSnapshot>;
  setBoard: (update: BoardUpdate) => void;
}

export const GameContainer: React.FunctionComponent<Props> = ({
  player,
  otherPlayers,
  setBoard,
}) => {
  return (
    <div className={styles.container}>
      <div className={styles.fields}>
        <div className={classNames(styles.playersColumn, styles.column)}>
          <TetrisField board={player} setBoard={setBoard} />
        </div>
        <div className={classNames(styles.competitorsColumn, styles.column)}>
          {Array.from(otherPlayers.entries()).map(([playerId, snapshot]) => (
            <div key={playerId}>
              <BoardSnapshotView snapshot={snapshot} />
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};
