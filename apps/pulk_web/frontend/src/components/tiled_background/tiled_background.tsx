import React, { useEffect, useRef } from "react";
import {
  GridPiece,
  rotatePieceShape,
  getPiecePatternGrid,
  PatternStartPoint,
} from "../../lib/piece/piece_pattern_grid";
import { getSkin } from "../../lib/piece/skins/skin";

const BLOCK_SIZE = 50;
const BORDER_WIDTH = 8;
const SKIN = getSkin("w95");

export const TiledBackground: React.FunctionComponent = () => {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const piecesRef = useRef<GridPiece[]>([]);

  const drawPiece = (ctx: CanvasRenderingContext2D, gridPiece: GridPiece) => {
    if (gridPiece.piece === null) {
      return;
    }

    const pieceSkin = SKIN[gridPiece.piece];
    const rotatedShape = rotatePieceShape(
      gridPiece.piece,
      gridPiece.position.rotation,
    );
    rotatedShape.forEach((shapeRow, i) => {
      shapeRow.forEach((cell, j) => {
        if (cell) {
          const x = gridPiece.position.col * BLOCK_SIZE + j * BLOCK_SIZE;
          const y = gridPiece.position.row * BLOCK_SIZE + i * BLOCK_SIZE;

          // Calculate main fill gradient
          const fillAngleRad = (pieceSkin.color.angleInDegrees * Math.PI) / 180;
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
          fillGradient.addColorStop(0, pieceSkin.color.start);
          fillGradient.addColorStop(1, pieceSkin.color.end);
          ctx.fillStyle = fillGradient;
          ctx.fillRect(x, y, BLOCK_SIZE, BLOCK_SIZE);

          if (pieceSkin.borderColor) {
            // Calculate border gradient
            const borderAngleRad =
              (pieceSkin.borderColor.angleInDegrees * Math.PI) / 180;
            const borderDx = Math.cos(borderAngleRad) * gradientLength;
            const borderDy = Math.sin(borderAngleRad) * gradientLength;

            // Create and apply border gradient
            const borderGradient = ctx.createLinearGradient(
              x,
              y,
              x + borderDx,
              y + borderDy,
            );
            borderGradient.addColorStop(0, pieceSkin.borderColor.start);
            borderGradient.addColorStop(1, pieceSkin.borderColor.end);
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
        }
      });
    });
  };

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;

    const ctx = canvas.getContext("2d");
    if (!ctx) return;

    const resizeCanvas = () => {
      canvas.width = window.innerWidth;
      canvas.height = window.innerHeight;

      const gridSize = {
        cols: Math.floor(canvas.width / BLOCK_SIZE),
        rows: Math.floor(canvas.height / BLOCK_SIZE),
      };

      const leftTopPattern = getPiecePatternGrid(
        gridSize.rows,
        gridSize.cols,
        PatternStartPoint.TOP_LEFT,
      );
      const bottomRightPattern = getPiecePatternGrid(
        gridSize.rows,
        gridSize.cols,
        PatternStartPoint.BOTTOM_RIGHT,
      );

      piecesRef.current = [...leftTopPattern, ...bottomRightPattern];
    };

    resizeCanvas();
    window.addEventListener("resize", resizeCanvas);

    const animate = () => {
      ctx.fillStyle = "#000000";
      ctx.fillRect(0, 0, canvas.width, canvas.height);

      piecesRef.current.forEach((gridPiece) => {
        drawPiece(ctx, gridPiece);
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
