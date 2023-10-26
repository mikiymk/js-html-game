import { CellEmpty } from "@/components/reversi/const";
import { randomSelect } from "@/scripts/random-select";

import { invertMark } from "./game";
import { isWin, turnMark } from "./game-model";
import { Empty, Reset, winnerLines } from "./types";

import type { Accessor } from "solid-js";
import type { BoardData, Index, Mark, Player } from "./types";

const emptyFunction = <T>(_: T): void => void 0;

class ResolvablePromise<T, E = unknown> {
  #promise = new Promise<T>(emptyFunction);
  #resolve: (value: T) => void = emptyFunction;
  #reject: (reason: E) => void = emptyFunction;

  constructor() {
    this.reset();
  }

  public reset() {
    this.#promise = new Promise<T>((resolve, reject) => {
      this.#resolve = resolve;
      this.#reject = reject;
    });
  }

  public get promise() {
    return this.#promise;
  }

  public resolve(value: T) {
    this.#resolve(value);
  }

  public reject(reason: E) {
    this.#reject(reason);
  }
}

export const GameAiPromise = new ResolvablePromise<Index | typeof Reset>();
export const humanPlayer: Player = {
  async getMarkIndex(boardData: Accessor<BoardData>, _mark: Mark) {
    for (;;) {
      GameAiPromise.reset();

      const index = await GameAiPromise.promise;
      if (index === Reset) return index;
      if (boardData()[index] === Empty) return index;
    }
  },
};

export const aiPlayer = {
  getMarkIndex(getBoardData: Accessor<BoardData>, mark: Mark) {
    // 各ラインで相手が2つと空きマスの場合、空きマスを選ぶ
    const clearCells: Index[] = [];
    const interCells: Index[] = [];
    const emptyCells: Index[] = [];

    const boardData = getBoardData();

    for (const line of winnerLines) {
      const [cell1, cell2, cell3] = line.map((number) => boardData[number]);

      if (cell1 === invertMark(mark) && cell1 === cell2 && cell3 === Empty) {
        interCells.push(line[2]);
      }
      if (cell2 === invertMark(mark) && cell2 === cell3 && cell1 === Empty) {
        interCells.push(line[0]);
      }
      if (cell3 === invertMark(mark) && cell3 === cell1 && cell2 === Empty) {
        interCells.push(line[1]);
      }

      if (cell1 === mark && cell1 === cell2 && cell3 === Empty) {
        clearCells.push(line[2]);
      }
      if (cell2 === mark && cell2 === cell3 && cell1 === Empty) {
        clearCells.push(line[0]);
      }
      if (cell3 === mark && cell3 === cell1 && cell2 === Empty) {
        clearCells.push(line[1]);
      }
    }

    // 空きマス
    for (const [index, cell] of boardData.entries()) {
      if (cell === Empty) {
        emptyCells.push(index as Index);
      }
    }

    if (emptyCells.length === 0) {
      // 見つからなかったら終了
      return Reset;
    }

    // ランダム
    return randomSelect(clearCells) ?? randomSelect(interCells) ?? randomSelect(emptyCells) ?? Reset;
  },
};

export const gameNoughtAndCrossAi = (board: number[], mark: number): number => {
  // 各ラインで相手が2つと空きマスの場合、空きマスを選ぶ
  const clearCells: number[] = [];
  const interCells: number[] = [];
  const emptyCells: number[] = [];

  for (const [index, cell] of board.entries()) {
    if (cell !== CellEmpty) {
      continue;
    }

    if (isWin(board.with(index, mark), mark)) {
      clearCells.push(index);
    }

    if (isWin(board.with(index, turnMark(mark)), turnMark(mark))) {
      interCells.push(index);
    }
  }

  // 空きマス
  for (const [index, cell] of board.entries()) {
    if (cell === CellEmpty) {
      emptyCells.push(index);
    }
  }

  if (emptyCells.length === 0) {
    // 見つからなかったら終了
    return Reset;
  }

  // ランダム
  return randomSelect(clearCells) ?? randomSelect(interCells) ?? randomSelect(emptyCells) ?? Reset;
};
