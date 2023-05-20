import React, { useContext, useRef } from "react";
import { Context as TetrixContext } from "react-tetris/lib/context";
import { Coords, PositionedPiece } from "react-tetris/lib/models/Matrix";
import { getBlocks } from "react-tetris/lib/models/Piece";

import { BoardUpdate, composeMatrix } from "../../lib/board";
import { notNil } from "../../lib/utils";

interface Props {
  setBoard: (boardUpdate: BoardUpdate) => void;
}

export const GameMatrixObserver: React.FunctionComponent<Props> = ({
  setBoard,
}) => {
  const prevState = useRef<string | undefined>(undefined);
  const game = useContext(TetrixContext);

  React.useEffect(() => {
    const jsonState = JSON.stringify({
      matrix: game.matrix,
      heldPiece: game.heldPiece,
      piece: game.piece,
    });

    if (jsonState == prevState.current) {
      return;
    }

    prevState.current = jsonState;

    setBoard({
      matrix: composeMatrix(game.matrix),
      activePiece: {
        piece: game.piece.piece,
        coordinates: getPieceCoordinates(game.piece),
      },
      pieceInHold: game.heldPiece?.piece ?? null,
    });
  }, [game]);

  return <></>;
};

const getPieceCoordinates = ({
  piece,
  position,
  rotation,
}: PositionedPiece) => {
  const block = getBlocks(piece)[rotation];

  const filledCells = block
    .reduce<Array<Coords | null>>(
      (output, row, y) =>
        output.concat(
          row.map((cell, x) =>
            cell ? { x: x + position.x, y: y + position.y } : null
          )
        ),
      []
    )
    .filter(notNil);

  return filledCells.map(({ x, y }) => [x, y] as [number, number]);
};
