import classNames from "classnames";

import { IconCross, IconMinimize, IconWindow } from "../../icons";
import styles from "./modal.module.css";
import { Frame } from "react95";

interface Props {
  title?: React.ReactNode;
  icon?: React.ReactNode;
  children?: React.ReactNode;
  subnote?: React.ReactNode;
  className?: string;
  controls?: "all" | "only-close";
}

export const Modal: React.FunctionComponent<Props> = ({
  icon,
  title,
  children,
  subnote,
  className,
  controls = "all",
}) => (
  <div className={classNames(styles.modal, className)}>
    <div className={styles.header}>
      <div className={styles.title}>
        {icon}
        <span>{title}</span>
      </div>
      <div className={styles.controls}>
        {controls === "all" ? (
          <>
            <IconButton align="end">
              <IconMinimize />
            </IconButton>
            <IconButton align="center">
              <IconWindow />
            </IconButton>
            <IconButton align="center">
              <IconCross />
            </IconButton>
          </>
        ) : (
          <IconButton align="center">
            <IconCross />
          </IconButton>
        )}
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
