import React from "react";

interface Props {
  color?: string;
  size?: number;
}

export const IconCross: React.FunctionComponent<Props> = ({
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
        d="M0 .5h2v1.143h1v1.143h2V1.643h1V.5h2v1.143H7v1.143H6v1.143H5V5.07h1v1.143h1v1.143h1V8.5H6V7.357H5V6.214H3v1.143H2V8.5H0V7.357h1V6.214h1V5.071h1V3.93H2V2.786H1V1.643H0V.5z"
        clipRule="evenodd"
      ></path>
    </svg>
  );
};
