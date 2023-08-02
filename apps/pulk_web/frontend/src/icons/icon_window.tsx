import React from "react";

interface Props {
  color?: string;
  size?: number;
}

export const IconWindow: React.FunctionComponent<Props> = ({
  color = "#000",
  size = 8,
}) => {
  return (
    <svg
      xmlns="http://www.w3.org/2000/svg"
      width={size}
      height={size * 1.125}
      fill="none"
      viewBox="0 0 8 9"
    >
      <path
        fill={color}
        fillRule="evenodd"
        d="M8 .5H0v8h8v-8zm-.889 1.778H.89V7.61H7.11V2.278z"
        clipRule="evenodd"
      ></path>
    </svg>
  );
};
