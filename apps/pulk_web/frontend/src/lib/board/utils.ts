import { Matrix as TetrisMatrix } from "react-tetris/lib/models/Matrix";

import { Matrix, PositionedPiece } from "./board";

export const hideBufferZone = (matrix: Matrix, bufferZoneSize: number) => {
  return matrix.filter((_value, idx) => idx + 1 > bufferZoneSize);
};

export const composeTetrisMatrix = (matrix: Matrix): TetrisMatrix => {
  return matrix.map((row) =>
    row.map((value) => {
      switch (value) {
        case "":
          return null;
        case "X":
          return "ghost";
        default:
          return value;
      }
    })
  );
};

export const composeMatrix = (matrix: TetrisMatrix): Matrix => {
  return matrix.map((row) =>
    row.map((value) => {
      switch (value) {
        case "ghost":
          return "";
        case null:
          return "";
        default:
          return value;
      }
    })
  );
};

export const addPiece = (
  inputMatrix: Matrix,
  piece: PositionedPiece
): Matrix => {
  const matrix = inputMatrix.map((row) => row.map((cell) => cell));
  const nextMatrix = piece.coordinates.reduce((matrix, [x, y]) => {
    const row = matrix[y];
    row[x] = piece.piece;
    matrix[y] = row;
    return matrix;
  }, matrix);
  return nextMatrix;
};

const getEmptyLine = (count: number) => new Array(count).fill("");

export const getTestMatrix = (): Matrix => {
  return [
    getEmptyLine(5),
    getEmptyLine(5),
    getEmptyLine(5),
    getEmptyLine(5),
    getEmptyLine(5),
    getEmptyLine(5),
    [null, "I", null, null, null],
    [null, "I", null, null, null],
    [null, "I", null, null, null],
    [null, "I", null, null, null],
  ];
};
