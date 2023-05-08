import React, { useContext, useRef } from "react";
import { Context as TetrixContext } from "react-tetris/lib/context";
import { viewMatrix } from "react-tetris/lib/models/Game";

import { Matrix, composeMatrix } from "../../lib/matrix";

interface Props {
  setMatrix: (matrix: Matrix) => void;
}

export const GameMatrixObserver: React.FunctionComponent<Props> = ({
  setMatrix,
}) => {
  const prevMatrix = useRef<string | undefined>(undefined);
  const game = useContext(TetrixContext);
  const matrix = viewMatrix(game);

  React.useEffect(() => {
    const jsonMatrix = JSON.stringify(matrix);
    if (jsonMatrix == prevMatrix.current) {
      return;
    }

    prevMatrix.current = jsonMatrix;
    setMatrix(composeMatrix(matrix));
  }, [matrix]);

  return <></>;
};
