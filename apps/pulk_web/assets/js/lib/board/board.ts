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
  activePiece: PositionedPiece | null;
  pieceInHold: Piece | null;
};

export type BoardSnapshot = {
  matrix: Matrix;
  activePiece: PositionedPiece | null;
};
