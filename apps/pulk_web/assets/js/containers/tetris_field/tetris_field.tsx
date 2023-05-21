import React from "react";
import Tetris from "react-tetris";

import { GameMatrixObserver } from "./game_matrix_observer";
import { Board, BoardUpdate, composeTetrisMatrix } from "../../lib/board";

import { styled } from "goober";

const Container = styled("div")`
  display: flex;
`;

interface Props {
  board?: Board;
  setBoard: (boardUpdate: BoardUpdate) => void;
}

export const TetrisField: React.FunctionComponent<Props> = ({
  board,
  setBoard,
}) => {
  const tetrisMatrix = React.useMemo(() => {
    if (board === undefined) {
      return { matrix: undefined };
    }

    const nextMatrix = composeTetrisMatrix(board.matrix);
    return { matrix: nextMatrix };
  }, [board?.matrix]);

  return (
    <Tetris
      key={JSON.stringify(tetrisMatrix.matrix)}
      matrix={tetrisMatrix.matrix}
      keyboardControls={{
        // Default values shown here. These will be used if no
        // `keyboardControls` prop is provided.
        down: "MOVE_DOWN",
        left: "MOVE_LEFT",
        right: "MOVE_RIGHT",
        space: "HARD_DROP",
        z: "FLIP_COUNTERCLOCKWISE",
        x: "FLIP_CLOCKWISE",
        up: "FLIP_CLOCKWISE",
        p: "TOGGLE_PAUSE",
        c: "HOLD",
        shift: "HOLD",
      }}
    >
      {({ Gameboard, state, controller }) => (
        <Container>
          <GameMatrixObserver setBoard={setBoard} />
          <Gameboard />
          {/* <PieceQueue /> */}
          {state === "LOST" && (
            <div>
              <h2>Game Over</h2>
              <button onClick={controller.restart}>New game</button>
            </div>
          )}
        </Container>
      )}
    </Tetris>
  );
};
