import { InteractivePieceType } from "../board";
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
type ProbabilityMap = number[][];

// Configuration constants
const TARGET_GRID_FILL = 0.1;
const AVERAGE_PIECE_SIZE = 4;
const MAX_PLACEMENT_ATTEMPTS = 100;
const PROBABILITY_REDUCTION_RADIUS = 3;
const PROBABILITY_REDUCTION_FACTOR = 0.3;

export enum PatternStartPoint {
  TOP_LEFT = "top_left",
  TOP_RIGHT = "top_right",
  BOTTOM_LEFT = "bottom_left",
  BOTTOM_RIGHT = "bottom_right",
  TOP_CENTER = "top_center",
  BOTTOM_CENTER = "bottom_center",
}

const getEmptyGrid = (rows: number, cols: number): Grid => {
  return Array(rows)
    .fill(null)
    .map(() =>
      Array(cols)
        .fill(null)
        .map(() => ({ isOccupied: false, piece: null })),
    );
};

const createProbabilityMap = (
  rows: number,
  cols: number,
  startPoint: PatternStartPoint,
): ProbabilityMap => {
  const map = Array(rows)
    .fill(0)
    .map(() => Array(cols).fill(0));

  // Define corner coordinates
  const corners = {
    [PatternStartPoint.TOP_LEFT]: { row: 0, col: 0 },
    [PatternStartPoint.TOP_RIGHT]: { row: 0, col: cols - 1 },
    [PatternStartPoint.BOTTOM_LEFT]: { row: rows - 1, col: 0 },
    [PatternStartPoint.BOTTOM_RIGHT]: { row: rows - 1, col: cols - 1 },
    [PatternStartPoint.TOP_CENTER]: { row: 0, col: Math.floor(cols / 2) },
    [PatternStartPoint.BOTTOM_CENTER]: {
      row: rows - 1,
      col: Math.floor(cols / 2),
    },
  };

  const corner = corners[startPoint];

  // Create probability based on distance from corner
  for (let row = 0; row < rows; row++) {
    for (let col = 0; col < cols; col++) {
      const distance = Math.sqrt(
        Math.pow(row - corner.row, 2) + Math.pow(col - corner.col, 2),
      );
      // Higher probability closer to corner, with falloff
      map[row][col] = Math.max(0, 1 - distance / Math.max(rows, cols));
    }
  }

  return map;
};

const samplePositionFromProbabilityMap = (
  probabilityMap: ProbabilityMap,
): { row: number; col: number } | null => {
  const rows = probabilityMap.length;
  const cols = probabilityMap[0].length;

  // Calculate total probability
  let totalProbability = 0;
  for (let row = 0; row < rows; row++) {
    for (let col = 0; col < cols; col++) {
      totalProbability += probabilityMap[row][col];
    }
  }

  if (totalProbability === 0) return null;

  // Sample based on probability
  let random = Math.random() * totalProbability;
  for (let row = 0; row < rows; row++) {
    for (let col = 0; col < cols; col++) {
      random -= probabilityMap[row][col];
      if (random <= 0) {
        return { row, col };
      }
    }
  }

  return null;
};

export const rotatePieceShape = (
  piece: InteractivePieceType,
  rotation: number,
): number[][] => {
  const shape = PIECE_SHAPES[piece];
  if (rotation === 0) return shape;

  const size = shape.length;
  const rotated = Array(size)
    .fill(0)
    .map(() => Array(size).fill(0));

  for (let i = 0; i < size; i++) {
    for (let j = 0; j < shape[i].length; j++) {
      if (rotation === 1) {
        rotated[j][size - 1 - i] = shape[i][j];
      } else if (rotation === 2) {
        rotated[size - 1 - i][size - 1 - j] = shape[i][j];
      } else if (rotation === 3) {
        rotated[size - 1 - j][i] = shape[i][j];
      }
    }
  }
  return rotated;
};

const canPlacePiece = (
  grid: Grid,
  piece: InteractivePieceType,
  position: { row: number; col: number },
  rotation: number,
): boolean => {
  const rotatedShape = rotatePieceShape(piece, rotation);
  const { row, col } = position;

  // Check bounds
  if (
    row < 0 ||
    col < 0 ||
    row + rotatedShape.length > grid.length ||
    col + rotatedShape[0].length > grid[0].length
  ) {
    return false;
  }

  // Check for collisions
  for (let i = 0; i < rotatedShape.length; i++) {
    for (let j = 0; j < rotatedShape[i].length; j++) {
      if (rotatedShape[i][j] && grid[row + i][col + j].isOccupied) {
        return false;
      }
    }
  }

  return true;
};

const placePiece = (
  grid: Grid,
  pieces: GridPiece[],
  piece: InteractivePieceType,
  position: { row: number; col: number },
  rotation: number,
): void => {
  pieces.push({ piece, position: { ...position, rotation } });
  const rotatedShape = rotatePieceShape(piece, rotation);

  // Mark grid as occupied
  for (let i = 0; i < rotatedShape.length; i++) {
    for (let j = 0; j < rotatedShape[i].length; j++) {
      if (rotatedShape[i][j]) {
        grid[position.row + i][position.col + j] = {
          isOccupied: true,
          piece: piece,
        };
      }
    }
  }
};

const reduceProbabilityAroundPosition = (
  probabilityMap: ProbabilityMap,
  position: { row: number; col: number },
): void => {
  const rows = probabilityMap.length;
  const cols = probabilityMap[0].length;

  for (let row = 0; row < rows; row++) {
    for (let col = 0; col < cols; col++) {
      const distance = Math.sqrt(
        Math.pow(row - position.row, 2) + Math.pow(col - position.col, 2),
      );
      if (distance <= PROBABILITY_REDUCTION_RADIUS) {
        probabilityMap[row][col] *= PROBABILITY_REDUCTION_FACTOR;
      }
    }
  }
};

export const getPiecePatternGrid = (
  rows: number,
  cols: number,
  startPoint: PatternStartPoint,
): GridPiece[] => {
  const grid = getEmptyGrid(rows, cols);
  const pieces: GridPiece[] = [];
  const probabilityMap = createProbabilityMap(rows, cols, startPoint);

  // Calculate target number of pieces
  const totalArea = rows * cols;
  const targetArea = totalArea * TARGET_GRID_FILL;
  const targetPieces = Math.floor(targetArea / AVERAGE_PIECE_SIZE);

  let attempts = 0;
  while (pieces.length < targetPieces && attempts < MAX_PLACEMENT_ATTEMPTS) {
    const position = samplePositionFromProbabilityMap(probabilityMap);
    if (!position) break; // No more valid positions

    const piece = getRandomPieceType();
    const rotation = Math.floor(Math.random() * 4);

    if (canPlacePiece(grid, piece, position, rotation)) {
      placePiece(grid, pieces, piece, position, rotation);
      reduceProbabilityAroundPosition(probabilityMap, position);
    }

    attempts++;
  }

  return pieces;
};
