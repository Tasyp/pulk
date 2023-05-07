import { Matrix as TetrisMatrix } from "react-tetris/lib/models/Matrix";

import { Matrix } from "./matrix";

export const composeTetrisMatrix = (matrix: Matrix): TetrisMatrix => {
  return matrix.map((row) =>
    row.map((value) => {
      switch (value) {
        case "":
          return null;
        default:
          return value;
      }
    })
  );
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
