import React, { useEffect, useRef } from "react";

interface TetrisPiece {
  shape: number[][];
  color: {
    start: string;
    end: string;
    angle: number; // Angle in degrees
  };
  borderColor: {
    start: string;
    end: string;
    angle: number;
  };
  type: string;
}

const TETRIS_PIECES: TetrisPiece[] = [
  // I piece
  {
    shape: [
      [0, 0, 0, 0],
      [1, 1, 1, 1],
      [0, 0, 0, 0],
      [0, 0, 0, 0],
    ],
    color: {
      start: "#B4FFFF",
      end: "#00FFFF",
      angle: 45,
    },
    borderColor: {
      start: "#00FFFF",
      end: "#B4FFFF",
      angle: 45,
    },
    type: "I",
  },
  // O piece
  {
    shape: [
      [1, 1],
      [1, 1],
    ],
    color: {
      start: "#FFAA00",
      end: "#FFD47E",
      angle: 45,
    },
    borderColor: {
      start: "#FFD47E",
      end: "#FFAA00",
      angle: 45,
    },
    type: "O",
  },
  // T piece
  {
    shape: [
      [0, 1, 0],
      [1, 1, 1],
      [0, 0, 0],
    ],
    color: {
      start: "#9900FF",
      end: "#CD82FF",
      angle: 45,
    },
    borderColor: {
      start: "#CD82FF",
      end: "#9900FF",
      angle: 45,
    },
    type: "T",
  },
  // S piece
  {
    shape: [
      [0, 1, 1],
      [1, 1, 0],
      [0, 0, 0],
    ],
    color: {
      start: "#FF2A00",
      end: "#FF9681",
      angle: 45,
    },
    borderColor: {
      start: "#FF9681",
      end: "#FF2A00",
      angle: 45,
    },
    type: "S",
  },
  // Z piece
  {
    shape: [
      [1, 1, 0],
      [0, 1, 1],
      [0, 0, 0],
    ],
    color: {
      start: "#00FF00",
      end: "#82FF82",
      angle: 45,
    },
    borderColor: {
      start: "#82FF82",
      end: "#00FF00",
      angle: 45,
    },
    type: "Z",
  },
  // J piece
  {
    shape: [
      [1, 0, 0],
      [1, 1, 1],
      [0, 0, 0],
    ],
    color: {
      start: "#0000FF",
      end: "#6A6AFF",
      angle: 45,
    },
    borderColor: {
      start: "#6A6AFF",
      end: "#0000FF",
      angle: 45,
    },
    type: "J",
  },
  // L piece
  {
    shape: [
      [0, 0, 1],
      [1, 1, 1],
      [0, 0, 0],
    ],
    color: {
      start: "#FF8C00",
      end: "#FFC04D",
      angle: 45,
    },
    borderColor: {
      start: "#FFC04D",
      end: "#FF8C00",
      angle: 45,
    },
    type: "L",
  },
];

const BLOCK_SIZE = 50;
const TARGET_SCREEN_FILL = 0.1;
const BORDER_WIDTH = 8; // Width of the inner border

export const TiledBackground: React.FunctionComponent = () => {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const piecesRef = useRef<
    Array<{ piece: TetrisPiece; col: number; row: number; rotation: number }>
  >([]);

  const getRandomPiece = (): TetrisPiece => {
    return TETRIS_PIECES[Math.floor(Math.random() * TETRIS_PIECES.length)];
  };

  const rotatePieceShape = (
    shape: number[][],
    rotation: number,
  ): number[][] => {
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

  const drawPiece = (
    ctx: CanvasRenderingContext2D,
    piece: TetrisPiece,
    col: number,
    row: number,
    rotation: number,
  ) => {
    const rotatedShape = rotatePieceShape(piece.shape, rotation);
    rotatedShape.forEach((shapeRow, i) => {
      shapeRow.forEach((cell, j) => {
        if (cell) {
          const x = col * BLOCK_SIZE + j * BLOCK_SIZE;
          const y = row * BLOCK_SIZE + i * BLOCK_SIZE;

          // Calculate main fill gradient
          const fillAngleRad = (piece.color.angle * Math.PI) / 180;
          const gradientLength = BLOCK_SIZE;
          const fillDx = Math.cos(fillAngleRad) * gradientLength;
          const fillDy = Math.sin(fillAngleRad) * gradientLength;

          // Draw main block fill
          const fillGradient = ctx.createLinearGradient(
            x,
            y,
            x + fillDx,
            y + fillDy,
          );
          fillGradient.addColorStop(0, piece.color.start);
          fillGradient.addColorStop(1, piece.color.end);
          ctx.fillStyle = fillGradient;
          ctx.fillRect(x, y, BLOCK_SIZE, BLOCK_SIZE);

          // Calculate border gradient
          const borderAngleRad = (piece.borderColor.angle * Math.PI) / 180;
          const borderDx = Math.cos(borderAngleRad) * gradientLength;
          const borderDy = Math.sin(borderAngleRad) * gradientLength;

          // Create and apply border gradient
          const borderGradient = ctx.createLinearGradient(
            x,
            y,
            x + borderDx,
            y + borderDy,
          );
          borderGradient.addColorStop(0, piece.borderColor.start);
          borderGradient.addColorStop(1, piece.borderColor.end);
          ctx.fillStyle = borderGradient;

          // Draw border as a single shape
          ctx.beginPath();
          // Outer rectangle
          ctx.rect(x, y, BLOCK_SIZE, BLOCK_SIZE);
          // Inner rectangle (counter-clockwise to create hole)
          ctx.rect(
            x + BORDER_WIDTH,
            y + BORDER_WIDTH,
            BLOCK_SIZE - 2 * BORDER_WIDTH,
            BLOCK_SIZE - 2 * BORDER_WIDTH,
          );
          ctx.fill("evenodd");
        }
      });
    });
  };

  const generatePieces = (
    startingPointIdx: number,
    width: number,
    height: number,
  ) => {
    const pieces: Array<{
      piece: TetrisPiece;
      col: number;
      row: number;
      rotation: number;
    }> = [];
    const gridRows = Math.floor(height / BLOCK_SIZE);
    const totalCols = Math.floor(width / BLOCK_SIZE);

    const grid = Array(gridRows)
      .fill(null)
      .map(() =>
        Array(totalCols)
          .fill(null)
          .map(() => ({ occupied: false, type: "" as string })),
      );

    const isValidPosition = (
      piece: TetrisPiece,
      row: number,
      col: number,
      rotation: number,
    ) => {
      if (row < 0 || col < 0) return false;

      const rotatedShape = rotatePieceShape(piece.shape, rotation);
      if (
        row + rotatedShape.length > gridRows ||
        col + rotatedShape[0].length > totalCols
      )
        return false;

      let hasAdjacent = false;
      for (let i = 0; i < rotatedShape.length; i++) {
        for (let j = 0; j < rotatedShape[i].length; j++) {
          if (rotatedShape[i][j]) {
            if (grid[row + i][col + j].occupied) return false;

            const adjacentPositions = [
              [row + i - 1, col + j],
              [row + i + 1, col + j],
              [row + i, col + j - 1],
              [row + i, col + j + 1],
            ];

            for (const [adjRow, adjCol] of adjacentPositions) {
              if (
                adjRow >= 0 &&
                adjRow < gridRows &&
                adjCol >= 0 &&
                adjCol < totalCols
              ) {
                if (grid[adjRow][adjCol].occupied) {
                  hasAdjacent = true;
                  if (grid[adjRow][adjCol].type === piece.type) {
                    return false;
                  }
                }
              }
            }
          }
        }
      }
      return hasAdjacent || pieces.length === 0;
    };

    const placePiece = (
      piece: TetrisPiece,
      row: number,
      col: number,
      rotation: number,
    ) => {
      pieces.push({ piece, row, col, rotation });
      const rotatedShape = rotatePieceShape(piece.shape, rotation);
      rotatedShape.forEach((shapeRow, i) => {
        shapeRow.forEach((cell, j) => {
          if (cell) {
            grid[row + i][col + j] = { occupied: true, type: piece.type };
          }
        });
      });
    };

    const startingPoints = [
      { row: 0, col: 0 },
      { row: 0, col: totalCols - 3 },
      { row: gridRows - 3, col: 0 },
      { row: gridRows - 3, col: totalCols - 3 },
      { row: 0, col: Math.floor(totalCols / 2) - 1 },
      { row: gridRows - 3, col: Math.floor(totalCols / 2) - 1 },
    ];

    const startingPoint = startingPoints[startingPointIdx];

    let attempts = 0;
    while (attempts < TETRIS_PIECES.length * 4) {
      const piece = getRandomPiece();
      const rotation = Math.floor(Math.random() * 4);
      if (
        isValidPosition(piece, startingPoint.row, startingPoint.col, rotation)
      ) {
        placePiece(piece, startingPoint.row, startingPoint.col, rotation);
        break;
      }
      attempts++;
    }

    const totalArea = gridRows * totalCols;
    const targetArea = totalArea * TARGET_SCREEN_FILL;
    const averagePieceSize = 4;
    const targetPieces = Math.floor(targetArea / averagePieceSize);

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
        while (attempts < TETRIS_PIECES.length * 4) {
          const piece = getRandomPiece();
          const rotation = Math.floor(Math.random() * 4);
          const rotatedShape = rotatePieceShape(piece.shape, rotation);
          const newRow = existingPiece.row + dRow * rotatedShape.length;
          const newCol = existingPiece.col + dCol * rotatedShape[0].length;

          if (isValidPosition(piece, newRow, newCol, rotation)) {
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

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;

    const ctx = canvas.getContext("2d");
    if (!ctx) return;

    const resizeCanvas = () => {
      canvas.width = window.innerWidth;
      canvas.height = window.innerHeight;

      const leftTopPattern = generatePieces(2, canvas.width, canvas.height);
      const bottomRightPattern = generatePieces(3, canvas.width, canvas.height);

      piecesRef.current = [...leftTopPattern, ...bottomRightPattern];
    };

    resizeCanvas();
    window.addEventListener("resize", resizeCanvas);

    const animate = () => {
      ctx.fillStyle = "#000000";
      ctx.fillRect(0, 0, canvas.width, canvas.height);

      piecesRef.current.forEach(({ piece, col, row, rotation }) => {
        drawPiece(ctx, piece, col, row, rotation);
      });

      ctx.fillStyle = "rgba(0, 0, 0, 0.5)";
      ctx.fillRect(0, 0, canvas.width, canvas.height);

      requestAnimationFrame(animate);
    };

    animate();

    return () => {
      window.removeEventListener("resize", resizeCanvas);
    };
  }, []);

  return (
    <canvas
      ref={canvasRef}
      style={{
        position: "fixed",
        top: 0,
        left: 0,
        width: "100%",
        height: "100%",
        zIndex: -1,
        pointerEvents: "none",
      }}
    />
  );
};
