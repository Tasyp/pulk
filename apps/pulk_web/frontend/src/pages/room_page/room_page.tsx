import { Button, ProgressBar } from "react95";

import { LoadingSpinner, Modal } from "../../components";
import { useRoom } from "../../containers/game_container/hooks";

import styles from "./room_page.module.css";

interface Props {
  roomId: string;
}


export const RoomPage: React.FunctionComponent<Props> = ({ roomId }) => {
  const { error, player, isLoading } = useRoom({
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
      <Modal className={styles.modal} controls="only-close">
        <div className={styles.playersModal}>
          <div className={styles.playerCountContainer}>
            <div className={styles.playersTitle}>Players waiting</div>
            <div className={styles.playerCount}>
              34/100
            </div>
          </div>
          <ProgressBar hideValue value={20} />
          <div>
            <Button>Cancel</Button>
          </div>
        </div>
      </Modal>
    </div>
  )
}
