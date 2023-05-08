import React from "react";
import Tetris from "react-tetris";

import { Matrix } from "../../lib/matrix";
import { GameMatrixObserver } from "./game_matrix_observer";

import { styled } from "goober";

const Container = styled("div")`
  display: flex;
`;

interface Props {
  setMatrix: (matrix: Matrix) => void;
}

export const TetrisField: React.FunctionComponent<Props> = ({ setMatrix }) => {
  return (
    <Tetris
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
