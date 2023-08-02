import React from "react";

interface Props {
  color?: string;
  size?: number;
}

export const IconMinimize: React.FunctionComponent<Props> = ({
  size = 8,
  color = "#000",
}) => (
  <svg
    xmlns="http://www.w3.org/2000/svg"
    width={size}
    height={size * 0.375}
    fill="none"
    viewBox="0 0 8 3"
  >
    <path fill={color} d="M0 0.5H8V2.5H0z"></path>
  </svg>
);
