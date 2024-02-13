import * as PIXI from "pixi.js";

import { Piece } from "../../../lib/board";

type PieceSprite = PIXI.Sprite & { pieceType: Piece };

/**
 * Render board and avtive teromino using PIXI.js
 */
export default class Renderer extends PIXI.Container {
  rows: number;
  cols: number;
  rowsOffset: number;
  blockSize: number;
  textures: Record<string, PIXI.Texture>;
  sprites: PieceSprite[][];

  /**
   * Initialize renderer
   * @param {Number} rows       Number of visible rows
   * @param {Number} cols       Number of visible columns
   * @param {Number} rowsOffset Number of rows in model to skip from rendering
   * @param {Number} blockSize  Target block size
   */
  constructor(
    rows: number,
    cols: number,
    rowsOffset: number,
    blockSize: number,
    sheet: PIXI.Spritesheet,
  ) {
    super();

    this.rows = rows;
    this.cols = cols;
    this.rowsOffset = rowsOffset;
    this.blockSize = blockSize;
    this.textures = sheet.textures;

    this.sprites = [] as PieceSprite[][];

    for (let i = 0; i < this.rows; ++i) {
      const row = [] as PieceSprite[];
      for (let j = 0; j < this.cols; ++j) {
        const spr = new PIXI.Sprite(this.textures[getTextureName("background")]) as PieceSprite;
        row.push(spr);
        spr.x = j * this.blockSize;
        spr.y = i * this.blockSize;
        spr.pieceType = "";
        this.addChild(spr);
      }
      this.sprites.push(row);
    }
  }

  updatePieceType(row: number, col: number, pieceType: Piece) {
    if (row < 0) return;
    const sprite = this.sprites[row][col];
    if (sprite.pieceType != pieceType) {
      sprite.pieceType = pieceType;
      sprite.texture = this.textures[getTextureName(pieceType)];
    }
  }

  updateFromBoard(board: { get: (row: number, column: number) => Piece }) {
    for (let i = 0; i < this.rows; ++i) {
      for (let j = 0; j < this.cols; ++j) {
        this.updatePieceType(i, j, board.get(i + this.rowsOffset, j));
      }
    }
  }
}

const getTextureName = (type: Piece | 'background') => {
  switch (type) {
    case 'background':
    case '':
      return 'background.svg';
    case 'I':
      return 'block-i.svg';
    case 'J':
      return 'block-j.png';
    case 'L':
      return 'block-l.svg';
    case 'O':
      return 'block-o.svg';
    case 'S':
      return 'block-s.svg';
    case 'T':
      return 'block-t.svg';
    case 'X':
      return 'block-garbage.svg';
    case 'Z':
      return 'block-z.svg';
  }
}
