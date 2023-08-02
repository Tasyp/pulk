import classNames from "classnames";

import styles from "./input_group.module.css";

interface Props {
  title?: React.ReactNode;
  children?: React.ReactNode;
  subtitle?: React.ReactNode;
  className?: string;
}

export const InputGroup: React.FunctionComponent<Props> = ({
  title,
  subtitle,
  children,
  className,
}) => (
  <div className={classNames(styles.group, className)}>
    {title && <div className={styles.title}>{title}</div>}
    <div>{children}</div>
    {subtitle && <div className={styles.subtitle}>{subtitle}</div>}
  </div>
);
