import { InteractivePieceType, InteractivePieceTypes } from "../board";
import { PIECE_SHAPES } from "./shapes";
import { getRandomPieceType } from "./utils";

export type GridPiece = {
  piece: InteractivePieceType;
  position: {
    col: number;
    row: number;
    rotation: number;
  };
};

type GridBox = { isOccupied: boolean; piece: InteractivePieceType | null };
type Grid = GridBox[][];

const getEmptyGrid = (rows: number, cols: number): Grid => {
  return Array(rows)
    .fill(null)
    .map(() =>
      Array(cols)
        .fill(null)
        .map(() => ({ isOccupied: false, piece: null })),
    );
};

const SAFE_EDGE_BUFFER = 4;
const getStartingPointCoordinates = (
  rows: number,
  cols: number,
  startPoint: PatternStartPoint,
) => {
  switch (startPoint) {
    case PatternStartPoint.TOP_LEFT:
      return { row: 0, col: 0 };
    case PatternStartPoint.TOP_RIGHT:
      return { row: 0, col: cols - SAFE_EDGE_BUFFER };
    case PatternStartPoint.BOTTOM_LEFT:
      return { row: rows - SAFE_EDGE_BUFFER, col: 0 };
    case PatternStartPoint.BOTTOM_RIGHT:
      return { row: rows - SAFE_EDGE_BUFFER, col: cols - SAFE_EDGE_BUFFER };
    case PatternStartPoint.TOP_CENTER:
      return { row: 0, col: Math.floor(cols / 2) - 1 };
    case PatternStartPoint.BOTTOM_CENTER:
      return { row: rows - SAFE_EDGE_BUFFER, col: Math.floor(cols / 2) - 1 };
  }
};

export const rotatePieceShape = (
  piece: InteractivePieceType,
  rotation: number,
): number[][] => {
  const shape = PIECE_SHAPES[piece];
  const size = shape.length;
  const rotated = Array(size)
    .fill(0)
    .map(() => Array(size).fill(0));

  for (let i = 0; i < size; i++) {
    for (let j = 0; j < shape[i].length; j++) {
      switch (rotation) {
        case 1: // 90 degrees
          rotated[j][size - 1 - i] = shape[i][j];
          break;
        case 2: // 180 degrees
          rotated[size - 1 - i][size - 1 - j] = shape[i][j];
          break;
        case 3: // 270 degrees
          rotated[size - 1 - j][i] = shape[i][j];
          break;
        default: // 0 degrees
          rotated[i][j] = shape[i][j];
      }
    }
  }
  return rotated;
};

export enum PatternStartPoint {
  TOP_LEFT = "top_left",
  TOP_RIGHT = "top_right",
  BOTTOM_LEFT = "bottom_left",
  BOTTOM_RIGHT = "bottom_right",
  TOP_CENTER = "top_center",
  BOTTOM_CENTER = "bottom_center",
}

const PIECE_PATTERN_GRID_ATTEMPTS = InteractivePieceTypes.length * 4;
const TARGET_GRID_FILL = 0.1;
const AVERAGE_PIECE_SIZE = 4;
export const getPiecePatternGrid = (
  rows: number,
  cols: number,
  startPoint: PatternStartPoint,
) => {
  const pieces: GridPiece[] = [];

  const grid = getEmptyGrid(rows, cols);

  const placePiece = (
    piece: InteractivePieceType,
    row: number,
    col: number,
    rotation: number,
  ) => {
    pieces.push({ piece, position: { row, col, rotation } });
    const rotatedShape = rotatePieceShape(piece, rotation);
    rotatedShape.forEach((shapeRow, i) => {
      shapeRow.forEach((cell, j) => {
        if (cell) {
          grid[row + i][col + j] = { isOccupied: true, piece: piece };
        }
      });
    });
  };

  const startingPoint = getStartingPointCoordinates(rows, cols, startPoint);

  let attempts = 0;
  while (attempts < PIECE_PATTERN_GRID_ATTEMPTS) {
    const piece = getRandomPieceType();
    const rotation = Math.floor(Math.random() * 4);
    if (
      isValidPosition(
        grid,
        piece,
        { rows, cols },
        { row: startingPoint.row, col: startingPoint.col },
        rotation,
        getIsGridEmpty(pieces),
      )
    ) {
      placePiece(piece, startingPoint.row, startingPoint.col, rotation);
      break;
    }
    attempts++;
  }

  const totalArea = rows * cols;
  const targetArea = totalArea * TARGET_GRID_FILL;
  const targetPieces = Math.floor(targetArea / AVERAGE_PIECE_SIZE);

  let failedAttempts = 0;
  const maxFailedAttempts = 1000;
  while (pieces.length < targetPieces && failedAttempts < maxFailedAttempts) {
    const existingPiece = pieces[Math.floor(Math.random() * pieces.length)];

    const directions = [
      [-1, 0],
      [1, 0],
      [0, -1],
      [0, 1],
    ];
    let placed = false;

    for (const [dRow, dCol] of directions) {
      let attempts = 0;
      while (attempts < PIECE_PATTERN_GRID_ATTEMPTS) {
        const piece = getRandomPieceType();
        const rotation = Math.floor(Math.random() * 4);
        const rotatedShape = rotatePieceShape(piece, rotation);
        const newRow = existingPiece.position.row + dRow * rotatedShape.length;
        const newCol =
          existingPiece.position.col + dCol * rotatedShape[0].length;

        if (
          isValidPosition(
            grid,
            piece,
            { rows, cols },
            { row: newRow, col: newCol },
            rotation,
            getIsGridEmpty(pieces),
          )
        ) {
          placePiece(piece, newRow, newCol, rotation);
          placed = true;
          break;
        }
        attempts++;
      }
      if (placed) break;
    }

    if (!placed) failedAttempts++;
  }

  return pieces;
};

const isValidPosition = (
  grid: Grid,
  piece: InteractivePieceType,
  gridSize: { rows: number; cols: number },
  position: { row: number; col: number },
  rotation: number,
  isGridEmpty: boolean,
) => {
  if (position.row < 0 || position.col < 0) return false;

  const rotatedShape = rotatePieceShape(piece, rotation);
  if (
    position.row + rotatedShape.length > gridSize.rows ||
    position.col + rotatedShape[0].length > gridSize.cols
  ) {
    return false;
  }

  let hasAdjacent = false;
  for (let i = 0; i < rotatedShape.length; i++) {
    for (let j = 0; j < rotatedShape[i].length; j++) {
      if (rotatedShape[i][j]) {
        if (grid[position.row + i][position.col + j].isOccupied) return false;

        const adjacentPositions = [
          [position.row + i - 1, position.col + j],
          [position.row + i + 1, position.col + j],
          [position.row + i, position.col + j - 1],
          [position.row + i, position.col + j + 1],
        ];

        for (const [adjRow, adjCol] of adjacentPositions) {
          if (
            adjRow >= 0 &&
            adjRow < gridSize.rows &&
            adjCol >= 0 &&
            adjCol < gridSize.cols
          ) {
            if (grid[adjRow][adjCol].isOccupied) {
              hasAdjacent = true;
              if (grid[adjRow][adjCol].piece === piece) {
                return false;
              }
            }
          }
        }
      }
    }
  }

  return hasAdjacent || isGridEmpty;
};

const getIsGridEmpty = (pieces: GridPiece[]) => pieces.length === 0;
