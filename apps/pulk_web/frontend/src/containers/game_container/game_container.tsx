import React from "react";
import classNames from "classnames";

import { TetrisField } from "../tetris_field";
import { BoardSnapshotView, LoadingSpinner } from "../../components";
import { useRoom } from "./hooks";

import styles from './game_container.module.css';

interface Props {
  roomId: string;
}

export const GameContainer: React.FunctionComponent<Props> = ({ roomId }) => {
  const { setBoard, error, player, otherPlayers, isLoading } = useRoom({
    roomId,
  });

  if (isLoading) {
    return <LoadingSpinner />;
  }

  if (error !== undefined) {
    return (
      <div className={styles.container}>
        <div>Failed {error}</div>
      </div>
    );
  }

  if (player === undefined) {
    return <div className={styles.container}>Unknown player</div>;
  }

  return (
    <div className={styles.container}>
      <div className={classNames(styles.competitorsColumn, styles.left)}>
        {Array.from(otherPlayers.entries()).map(
          ([playerId, snapshot], idx) =>
            idx % 2 === 0 && (
              <div key={playerId}>
                <BoardSnapshotView snapshot={snapshot} />
              </div>
            )
        )}
      </div>
      <div className={classNames(styles.playersColumn)}>
        <div>
          state: {JSON.stringify({ ...player, matrix: undefined }, null, 2)}
        </div>
        <TetrisField board={player} setBoard={setBoard} />
      </div>
      <div className={classNames(styles.competitorsColumn, styles.right)}>
        {Array.from(otherPlayers.entries()).map(
          ([playerId, snapshot], idx) =>
            idx % 2 !== 0 && (
              <div key={playerId}>
                <BoardSnapshotView snapshot={snapshot} />
              </div>
            )
        )}
      </div>
    </div>
  );
};
