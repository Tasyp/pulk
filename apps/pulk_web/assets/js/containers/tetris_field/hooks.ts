import React from "react";
import { useHotkeys } from "react-hotkeys-hook";

import { Board, BoardUpdate } from "../../lib/board";
import { Direction, RelativeRotation, UpdateType } from "../../lib/room";

export const useKeyboard = (
  board: Board | undefined,
  setBoard: (boardUpdate: BoardUpdate) => void
) => {
  const isDownKeyPressed = React.useRef(false);
  const isSoftDropActivated = React.useRef(false);
  const softDropTimerId = React.useRef<number | undefined>(undefined);

  useHotkeys(
    "down",
    (keyboardEvent) => {
      if (board?.activePiece == undefined) {
        return;
      }

      const piece = board.activePiece.piece;

      switch (keyboardEvent.type) {
        case "keydown":
          if (isDownKeyPressed.current) {
            return;
          }

          isDownKeyPressed.current = true;

          softDropTimerId.current = setTimeout(() => {
            isSoftDropActivated.current = true;
            setBoard({
              activePieceUpdate: {
                piece,
                update_type: UpdateType.SOFT_DROP_START,
              },
            });
          }, 250);
          break;
        case "keyup":
          if (!isDownKeyPressed.current) {
            return;
          }

          isDownKeyPressed.current = false;

          if (isSoftDropActivated.current) {
            isSoftDropActivated.current = false;
            setBoard({
              activePieceUpdate: {
                piece,
                update_type: UpdateType.SOFT_DROP_STOP,
              },
            });
          } else {
            clearTimeout(softDropTimerId.current ?? undefined);

            softDropTimerId.current = undefined;
            setBoard({
              activePieceUpdate: {
                piece,
                update_type: UpdateType.SIMPLE,
                direction: Direction.DOWN,
              },
            });
          }

          break;
      }
    },
    { preventDefault: true, keydown: true, keyup: true },
    [board]
  );

  useHotkeys(
    "left",
    () => {
      if (board?.activePiece == undefined) {
        return;
      }

      setBoard({
        activePieceUpdate: {
          piece: board.activePiece.piece,
          update_type: UpdateType.SIMPLE,
          direction: Direction.LEFT,
        },
      });
    },
    { preventDefault: true, keydown: false, keyup: true },
    [board]
  );
  useHotkeys(
    "right",
    () => {
      if (board?.activePiece == undefined) {
        return;
      }

      setBoard({
        activePieceUpdate: {
          piece: board.activePiece.piece,
          update_type: UpdateType.SIMPLE,
          direction: Direction.RIGHT,
        },
      });
    },
    { preventDefault: true, keydown: false, keyup: true },
    [board]
  );
  useHotkeys(
    "space",
    () => {
      if (board?.activePiece == undefined) {
        return;
      }

      setBoard({
        activePieceUpdate: {
          piece: board.activePiece.piece,
          update_type: UpdateType.HARD_DROP,
        },
      });
    },
    { preventDefault: true, keydown: false, keyup: true },
    [board]
  );

  useHotkeys(
    "z",
    () => {
      if (board?.activePiece == undefined) {
        return;
      }

      setBoard({
        activePieceUpdate: {
          piece: board.activePiece.piece,
          update_type: UpdateType.SIMPLE,
          relative_rotation: RelativeRotation.LEFT,
        },
      });
    },
    { preventDefault: true, keydown: false, keyup: true },
    [board]
  );

  useHotkeys(
    "c",
    () => {
      if (board?.activePiece == undefined) {
        return;
      }

      setBoard({
        activePieceUpdate: {
          piece: board.activePiece.piece,
          update_type: UpdateType.HOLD,
        },
      });
    },
    { preventDefault: true, keydown: false, keyup: true },
    [board]
  );

  useHotkeys(
    "up",
    () => {
      if (board?.activePiece == undefined) {
        return;
      }

      setBoard({
        activePieceUpdate: {
          piece: board.activePiece.piece,
          update_type: UpdateType.SIMPLE,
          relative_rotation: RelativeRotation.RIGHT,
        },
      });
    },
    { preventDefault: true, keydown: false, keyup: true },
    [board]
  );
};
