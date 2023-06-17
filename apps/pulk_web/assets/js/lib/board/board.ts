import { PiecePositionUpdate } from "../room";

export type Piece = "" | "I" | "O" | "T" | "S" | "Z" | "J" | "L" | "X";

export type Matrix = Piece[][];

export type PositionedPiece = {
  piece: Piece;
  coordinates: [x: number, y: number][];
};

export type BoardUpdate = {
  activePieceUpdate: PiecePositionUpdate;
  pieceInHold: Piece | null;
};

export type Board = {
  matrix: Matrix;
  score: number;
  level: number;
  placement: number | null;
  status: BoardStatus;
  activePiece: PositionedPiece | null;
  pieceInHold: Piece | null;
};

export type BoardSnapshot = {
  matrix: Matrix;
  status: BoardStatus;
  activePiece: PositionedPiece | null;
};

export enum BoardStatus {
  INITIAL = "initial",
  PLAYING = "playing",
  COMPLETE = "complete",
}
