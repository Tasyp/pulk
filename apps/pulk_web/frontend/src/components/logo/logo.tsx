import classNames from "classnames";

import styles from "./logo.module.css";

interface Props {
  className?: string;
}

export const Logo: React.FunctionComponent<Props> = ({ className }) => (
  <div className={classNames(styles.logo, className)}>Pulk.io</div>
);
