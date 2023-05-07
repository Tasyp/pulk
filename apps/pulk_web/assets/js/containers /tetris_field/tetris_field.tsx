import React from 'react'
import Tetris from "react-tetris";

import { styled } from 'goober'

const Container = styled('div')`
  display: flex;
`

export const TetrisField: React.FunctionComponent = () => {
  return (
    <Tetris
      keyboardControls={{
        // Default values shown here. These will be used if no
        // `keyboardControls` prop is provided.
        down: 'MOVE_DOWN',
        left: 'MOVE_LEFT',
        right: 'MOVE_RIGHT',
        space: 'HARD_DROP',
        z: 'FLIP_COUNTERCLOCKWISE',
        x: 'FLIP_CLOCKWISE',
        up: 'FLIP_CLOCKWISE',
        p: 'TOGGLE_PAUSE',
        c: 'HOLD',
        shift: 'HOLD'
      }}
    >
      {({
        HeldPiece,
        Gameboard,
        state,
        controller
      }) => (
        <Container>
          {/* <div>
            <HeldPiece />
          </div> */}
          <Gameboard />
          {/* <PieceQueue /> */}
          {state === 'LOST' && (
            <div>
              <h2>Game Over</h2>
              <button onClick={controller.restart}>New game</button>
            </div>
          )}
        </Container>
      )}
    </Tetris>
  )
};
