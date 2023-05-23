export type Piece = "" | "I" | "O" | "T" | "S" | "Z" | "J" | "L";

export type Matrix = Piece[][];

export type PositionedPiece = {
  piece: Piece;
  coordinates: [x: number, y: number][];
};

export type BoardUpdate = {
  matrix: Matrix;
  activePiece: PositionedPiece | null;
  pieceInHold: Piece | null;
};

export type Board = {
  matrix: Matrix;
  score: number;
  level: number;
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
