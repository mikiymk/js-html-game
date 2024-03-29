import { filledBoard, gameLoop, isWin } from "@/games/nought-and-cross/game-model";
import {
  Empty,
  MarkO,
  MarkX,
  StatusDraw,
  StatusNextO,
  StatusNextX,
  StatusNone,
  StatusWinO,
  StatusWinX,
} from "@/games/nought-and-cross/types";
import type { Status } from "@/games/nought-and-cross/types";
import { doNothingFunction } from "@/scripts/do-nothing";
import { MultiPromise } from "@/scripts/multi-promise";
import { PlayerTypeAi, PlayerTypeHuman, playerType } from "@/scripts/player";
import type { JSXElement } from "solid-js";
import { createSignal, onMount } from "solid-js";
import { Board } from "./board";
import { Controller } from "./controller";
import { History } from "./history";

export const App = (): JSXElement => {
  const query = new URLSearchParams(location.search);

  const playerO = playerType(query.get("o"), PlayerTypeHuman);
  const playerX = playerType(query.get("x"), PlayerTypeAi);

  const [board, setBoardData] = createSignal<readonly number[]>([]);
  const [mark, setMark] = createSignal(MarkO);
  const [history, setHistory] = createSignal<readonly number[]>([]);

  let terminate = doNothingFunction;
  let resolve: (value: number) => void = doNothingFunction;

  const humanInput = new MultiPromise<number>((rs) => {
    resolve = rs;
  });

  const handleClick = (index: number): void => {
    if (board()[index] !== Empty) {
      return;
    }

    resolve(index);
  };

  const reset = (): void => {
    terminate();

    const players = {
      o: playerO,
      x: playerX,
    };

    // eslint-disable-next-line @typescript-eslint/prefer-destructuring
    terminate = gameLoop(setBoardData, setMark, setHistory, humanInput, players).terminate;
  };

  onMount(reset);

  const status = (): Status => {
    if (isWin(board(), MarkO)) {
      return StatusWinO;
    }
    if (isWin(board(), MarkX)) {
      return StatusWinX;
    }
    if (filledBoard(board())) {
      return StatusDraw;
    }
    if (mark() === MarkO) {
      return StatusNextO;
    }
    if (mark() === MarkX) {
      return StatusNextX;
    }

    return StatusNone;
  };

  return (
    <>
      <Board board={board()} click={handleClick} />
      <Controller statusMessage={status()} onReset={reset} />
      <History history={history()} />
    </>
  );
};
