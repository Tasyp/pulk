import { PieceUpdate } from "../room";

export const InteractivePieceTypes = [
  "I",
  "O",
  "T",
  "S",
  "Z",
  "J",
  "L",
] as const;
export type InteractivePieceType = (typeof InteractivePieceTypes)[number];
export type PieceType = "" | "X" | InteractivePieceType;

export type Matrix = PieceType[][];

export type PositionedPiece = {
  piece: PieceType;
  coordinates: [x: number, y: number][];
};

export type BoardUpdate = {
  activePieceUpdate: PieceUpdate;
};

export type Board = {
  matrix: Matrix;
  bufferZoneSize: number;
  score: number;
  level: number;
  placement: number | null;
  status: BoardStatus;
  activePiece: PositionedPiece | null;
  pieceInHold: PieceType | null;
};

export type BoardSnapshot = {
  matrix: Matrix;
  bufferZoneSize: number;
  status: BoardStatus;
  activePiece: PositionedPiece | null;
};

export enum BoardStatus {
  INITIAL = "initial",
  PLAYING = "playing",
  COMPLETE = "complete",
}
