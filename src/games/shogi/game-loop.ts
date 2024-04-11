import type { MultiPromise } from "@/scripts/multi-promise";
import type { PlayerType } from "@/scripts/player";
import { PlayerTypeHuman } from "@/scripts/player";
import { sleep } from "@/scripts/sleep";
import { MOVE_TARGET } from "./constants";

type GamePtr = 0 | (number & { readonly __uniqueShogiGame: "Wasm pointer of Game struct" });
type BoardArray = 0 | (number & { readonly __uniqueShogiBoardArray: "Wasm pointer of Game struct" });
type Game = { readonly game: GamePtr; readonly board: BoardArray };

type WasmExports = {
  init: () => GamePtr;
  deinit: (g: GamePtr) => void;
  initBoard: () => BoardArray;
  deinitBoard: (b: BoardArray) => void;
  setBoard: (g: GamePtr, b: BoardArray) => void;
  player: (g: GamePtr) => number;
  winner: (g: GamePtr) => number;
  movePos: (g: GamePtr, b: BoardArray, from: number) => void;
  move: (g: GamePtr, from: number, to: number) => boolean;
  hit: (g: GamePtr, piece: number, position: number) => void;
  promote: (g: GamePtr, position: number) => void;
  moveAi: (g: GamePtr) => void;

  memory: WebAssembly.Memory;
};

type WasmConnect = {
  readonly init: () => Game;
  readonly deinit: (g: Game) => void;

  readonly board: (g: Game) => readonly number[];
  readonly player: (g: Game) => number;
  readonly winner: (g: Game) => number;
  readonly movePos: (g: Game, from: number) => readonly number[];

  readonly move: (g: Game, from: number, to: number) => boolean;
  readonly hit: (g: Game, piece: number, position: number) => void;
  readonly promote: (g: Game, position: number) => void;

  readonly ai: (g: Game) => void;
};

const AI_SLEEP_TIME_MS = 500;
const EmptyBoard: readonly number[] = Array.from({ length: 81 }, () => 0);

const getWasm = async (): Promise<WasmConnect> => {
  const wasm = await WebAssembly.instantiateStreaming(fetch(`${import.meta.env.BASE_URL}/wasm/shogi.wasm`), {});

  const exports = wasm.instance.exports as WasmExports;
  const buffer = new Uint8Array(exports.memory.buffer);

  const getBoard = (board: BoardArray): readonly number[] => {
    // UInt8ArrayからArrayに変換する
    // eslint-disable-next-line unicorn/no-useless-spread
    return [...buffer.slice(board, board + 81)];
  };

  return {
    init: (): Game => {
      const game = exports.init();
      const board = exports.initBoard();

      return { game, board };
    },
    deinit: (game: Game): void => {
      exports.deinitBoard(game.board);
      exports.deinit(game.game);
    },

    board: ({ game, board }: Game): readonly number[] => {
      exports.setBoard(game, board);

      return getBoard(board);
    },
    player: ({ game }: Game): number => exports.player(game),
    winner: ({ game }: Game): number => exports.winner(game),
    movePos: ({ game, board }: Game, from: number): readonly number[] => {
      exports.movePos(game, board, from);

      return getBoard(board);
    },

    move: ({ game }: Game, from: number, to: number): boolean => exports.move(game, from, to),
    hit: ({ game }: Game, piece: number, position: number): void => {
      exports.hit(game, piece, position);
    },
    promote: ({ game }: Game, position: number): void => {
      exports.promote(game, position);
    },

    ai: ({ game }: Game): void => {
      exports.moveAi(game);
    },
  };
};

type Players = { readonly [Key in number]: PlayerType };
const isHuman = (players: Players, color: number): boolean => {
  return players[color] === PlayerTypeHuman;
};

const askPromote = async (humanInput: MultiPromise<number>): Promise<boolean> => {
  return (await humanInput.request()) === 1;
};

const gameLoop = (
  wasm: WasmConnect,
  setPlayer: (player: number) => void,
  setBoard: (board: readonly number[]) => void,
  setWinner: (winner: number) => void,
  setMove: (move: readonly number[]) => void,
  humanInput: MultiPromise<number>,
  players: Players,
): (() => void) => {
  const {
    init,
    deinit,

    board,
    player,
    winner,
    movePos,

    move,
    hit,
    promote,

    ai: moveAi,
  } = wasm;

  let game: Game = init();
  console.log(`game start id(${game.game}, ${game.board})`);

  const terminate = (): void => {
    console.log(`game end id(${game.game}, ${game.board})`);
    deinit(game);
    game = { game: 0, board: 0 };
  };

  // biome-ignore lint/complexity/noExcessiveCognitiveComplexity: 長い関数
  const ply = async (color: number): Promise<void> => {
    if (isHuman(players, color)) {
      let from: number;
      let to: number;

      for (;;) {
        setMove(EmptyBoard);

        from = await humanInput.request();

        const moves = movePos(game, from);

        if (!moves.includes(MOVE_TARGET)) {
          continue;
        }

        setMove(moves);

        to = await humanInput.request();

        if (moves[to] === MOVE_TARGET) {
          break;
        }
      }

      if (move(game, from, to)) {
        const isPromote = await askPromote(humanInput);
        if (isPromote) {
          promote(game, to);
        }
      }
    } else {
      console.time("ai think");
      moveAi(game);
      console.timeEnd("ai think");

      await sleep(AI_SLEEP_TIME_MS);
    }
  };

  const run = async (): Promise<void> => {
    setBoard(board(game));
    const color = player(game);
    console.log("color", color);

    await ply(color);

    setPlayer(player(game));
    setBoard(board(game));
    setMove(EmptyBoard);

    const end = winner(game);
    if (end !== 0) {
      setWinner(end);
      terminate();
    }

    if (game.game !== 0) {
      setTimeout(() => {
        console.log(`game continue id(${game.game}, ${game.board})`);
        void run();
      }, 0);
    }
  };

  setTimeout(() => {
    void run();
  }, 0);

  return terminate;
};

export { getWasm, gameLoop };
