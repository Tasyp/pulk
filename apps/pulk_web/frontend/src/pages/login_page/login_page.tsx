import { Button, Select, TextInput } from "react95";

import { InputGroup, Logo, Modal } from "../../components";
import { useAvailableRoom } from "../../lib/room";

import styles from "./login_page.module.css";
import { useLocation } from "wouter";

const GAME_MODES = [
  {
    label: "40 lines",
    value: 0,
  },
];

export const LoginPage: React.FunctionComponent = () => {
  const [, navigate] = useLocation();
  const { roomId } = useAvailableRoom();

  const onClick = () => {
    navigate(`/room/${roomId}`);
  };

  return (
    <div className={styles.container}>
      <Logo className={styles.logo} />
      <Modal title="Login" subnote="0 player(s)">
        <div className={styles.intro}>
          <p className={styles.title}>Welcome to Pulk.io</p>
          <p className={styles.text}>
            It is an open-source implementation of the T-99 game. It aims to be
            a simpler alternative to the more bloated or paid options. <br />{" "}
            And In case you're wondering, Pulk means a stick in Estonian
          </p>
        </div>
        <InputGroup
          title="Username"
          subtitle="BY JOINING, YOU ACCEPT THE TERMS OF USE, PRIVACY POLICY AND RULES"
        >
          <TextInput placeholder="Enter your username" fullWidth />
        </InputGroup>
        <InputGroup title="Gamemode">
          <Select
            defaultValue={0}
            options={GAME_MODES}
            menuMaxHeight={160}
            className={styles.selectContainer}
          />
        </InputGroup>
        <div className={styles.actions}>
          <Button onClick={onClick} primary disabled={roomId === undefined}>
            LOGIN GAME
          </Button>
          <Button disabled>CREATE ROOM</Button>
        </div>
      </Modal>
    </div>
  );
};
