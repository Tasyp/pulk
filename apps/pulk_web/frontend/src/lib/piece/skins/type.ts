import { PieceType } from "../../board";

type GradientColor = {
  type: "gradient";
  start: string;
  end: string;
  angleInDegrees: number;
};

// type SolidColor = {
//   type: "solid";
//   color: string;
// }

type Color = GradientColor; // SolidColor

export type PieceSkin = {
  color: Color;
  borderColor: Color | null;
};

export type Skin = Required<{
  [key in PieceType]: PieceSkin;
}>;
