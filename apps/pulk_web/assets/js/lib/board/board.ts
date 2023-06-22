import { PieceUpdate } from "../room";

export type Piece = "" | "I" | "O" | "T" | "S" | "Z" | "J" | "L" | "X";

export type Matrix = Piece[][];

export type PositionedPiece = {
  piece: Piece;
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
  pieceInHold: Piece | null;
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
