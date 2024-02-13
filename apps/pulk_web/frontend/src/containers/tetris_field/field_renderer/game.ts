import * as PIXI from 'pixi.js';

import Renderer from './renderer';
import { Matrix } from '../../../lib/board';

type GameConfig = {
  cols: number,
  rows: number,
  hiddenRows: number,
  blockSize: number,
};

/**
 * Represent whole game and handles state changes
 */
export default class Game {
  app: PIXI.Application;
  config: GameConfig;
  renderer: Renderer;
  sheet: PIXI.Spritesheet

  constructor(app: PIXI.Application, sheet: PIXI.Spritesheet, config: GameConfig) {
    this.app = app;
    this.config = config;
    this.sheet = sheet;

    this.renderer = new Renderer(
      this.config.rows, this.config.cols,
      this.config.hiddenRows, this.config.blockSize,
      sheet,
    );
  }

  /**
   * start game, execute after all assets are loaded
   */
  run() {
    const background = new PIXI.TilingSprite(
        this.sheet.textures["background.svg"],
        this.app.renderer.width,
        this.app.renderer.height);

    this.app.stage.addChild(background);
    this.app.stage.addChild(this.renderer);
  }

  updateFromMatrix(matrix: Matrix) {
    const board = composeBoardAccessor(matrix);
    this.renderer.updateFromBoard(board)
  }
}

const composeBoardAccessor = (matrix: Matrix) => {
  return {
    get: (row: number, column: number) => {
      return matrix[row][column]
    }
  }
}
