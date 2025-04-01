import { InteractivePieceType, InteractivePieceTypes } from "../board";

export const getRandomPieceType = (): InteractivePieceType => {
  return InteractivePieceTypes[
    Math.floor(Math.random() * InteractivePieceTypes.length)
  ];
};
