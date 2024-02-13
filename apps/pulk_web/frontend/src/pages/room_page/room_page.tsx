import { ProgressBar } from "react95";

import { Modal } from "../../components";
import { useRoom } from "../../containers/game_container/hooks";

import styles from "./room_page.module.css";
import { useEffect, useState } from "react";
import { GameContainer } from "../../containers";

interface Props {
  roomId: string;
}

export const RoomPage: React.FunctionComponent<Props> = ({ roomId }) => {
  const { error, player, setBoard, otherPlayers, isLoading } = useRoom({
    roomId,
  });

  if (isLoading) {
    return (
      <div className={styles.container}>
        <Modal className={styles.modal} controls="only-close">
          <div className={styles.content}>
            <div className={styles.title}>Loading...</div>
            <SyntheticProgressBar />
          </div>
        </Modal>
      </div>
    );
  }

  if (error !== undefined) {
    return (
      <Modal className={styles.modal} controls="only-close">
        <div className={styles.content}>
          <div className={styles.title}>Failed {error}</div>
        </div>
      </Modal>
    );
  }

  if (player === undefined) {
    return (
      <Modal className={styles.modal} controls="only-close">
        <div className={styles.content}>
          <div className={styles.title}>Unknown player</div>
        </div>
      </Modal>
    );
  }

  return (
    <GameContainer
      player={player}
      otherPlayers={otherPlayers}
      setBoard={setBoard}
    />
  );
};

function SyntheticProgressBar() {
  const [percent, setPercent] = useState(0);

  useEffect(() => {
    const timer = setInterval(() => {
      setPercent((previousPercent) =>
        Math.min(previousPercent + Math.random() * 10, 100),
      );
    }, 500);

    return () => {
      clearInterval(timer);
    };
  }, []);

  return <ProgressBar variant="tile" value={Math.floor(percent)} />;
}
