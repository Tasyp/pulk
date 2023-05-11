import React from "react";
import Tetris from "react-tetris";

import { Matrix, composeTetrisMatrix } from "../../lib/matrix";
import { GameMatrixObserver } from "./game_matrix_observer";

import { styled } from "goober";

const Container = styled("div")`
  display: flex;
`;

interface Props {
  matrix?: Matrix;
  setMatrix: (matrix: Matrix) => void;
}

export const TetrisField: React.FunctionComponent<Props> = ({
  matrix,
  setMatrix,
}) => {
  const tetrisMatrix = React.useMemo(() => {
    if (matrix === undefined) {
      return { matrix: undefined, key: "default" };
    }

    const nextMatrix = composeTetrisMatrix(matrix);
    return { matrix: nextMatrix, key: JSON.stringify(nextMatrix) };
  }, [matrix]);

  return (
    <Tetris
      key={tetrisMatrix.key}
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
          <GameMatrixObserver setMatrix={setMatrix} />
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
