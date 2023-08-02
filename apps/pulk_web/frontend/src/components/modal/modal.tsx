import classNames from "classnames";

import {
  IconCross,
  IconFolderSmall,
  IconMinimize,
  IconWindow,
} from "../../icons";
import styles from "./modal.module.css";
import { Frame } from "react95";

interface Props {
  title?: React.ReactNode;
  children?: React.ReactNode;
  subnote?: React.ReactNode;
}

export const Modal: React.FunctionComponent<Props> = ({
  title,
  children,
  subnote,
}) => (
  <div className={styles.modal}>
    <div className={styles.header}>
      <div className={styles.title}>
        <IconFolderSmall />
        <span>{title}</span>
      </div>
      <div className={styles.controls}>
        <IconButton align="end">
          <IconMinimize />
        </IconButton>
        <IconButton align="center">
          <IconWindow />
        </IconButton>
        <IconButton align="center">
          <IconCross />
        </IconButton>
      </div>
    </div>
    <div className={styles.content}>
      {children}
      {subnote && (
        <div>
          <Frame className={styles.windowFrame} variant="well">
            {subnote}
          </Frame>
        </div>
      )}
    </div>
  </div>
);

const IconButton: React.FunctionComponent<{
  children?: React.ReactNode;
  align: "center" | "end";
}> = ({ children, align }) => (
  <button
    className={classNames(
      styles.iconButton,
      align === "center" ? styles.centered : styles.end,
    )}
  >
    {children}
  </button>
);
