import React from 'react'
import { getClassName } from 'react-tetris/lib/models/Piece';

import { Matrix, composeTetrisMatrix } from '../../lib/matrix';

interface Props {
  matrix: Matrix;
}

export const BoardView: React.FunctionComponent<Props> = ({ matrix: inputMatrix }) => {
  const matrix = composeTetrisMatrix(inputMatrix);

  return (
    <table className="game-board">
      <tbody>
        {matrix.map((row, i) => {
          const blocksInRow = row.map((block, j) => {
            const classString = `game-block ${block ? getClassName(block) : 'block-empty'
              }`;
            return <td key={j} className={classString} />;
          });

          return <tr key={i}>{blocksInRow}</tr>;
        })}
      </tbody>
    </table>
  )
};
