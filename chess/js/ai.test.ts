import { test, expect, describe } from "vitest";
import { Black, BlackKing, BlackPawn, BlackQueen, White, WhiteKing, WhitePawn, WhiteQueen } from "@/chess/js/types";
import { generateBoard, generateState } from "./game/state";
import { alphaBeta } from "./ai";
import { getNextState } from "./game/get-next";
import { generateMoveMove } from "./game/generate-move";

describe("alpha-beta evaluation", () => {
  test("for white, black pawn more advantageous than black queen", () => {
    const state = generateState();
    state.board = generateBoard({
      4: BlackKing,

      35: BlackPawn,
      37: BlackQueen,

      44: WhitePawn,

      60: WhiteKing,
    });
    state.mark = White;

    const result1 = alphaBeta(getNextState(state, generateMoveMove(44, 37)), 1);
    const result2 = alphaBeta(getNextState(state, generateMoveMove(44, 35)), 1);

    expect(result1).toBeGreaterThan(result2);
  });

  test("for black", () => {
    const state = generateState();
    state.board = generateBoard({
      4: BlackKing,

      20: BlackPawn,

      27: WhitePawn,
      29: WhiteQueen,

      60: WhiteKing,
    });
    state.mark = Black;

    const result1 = alphaBeta(getNextState(state, generateMoveMove(20, 29)), 1);
    const result2 = alphaBeta(getNextState(state, generateMoveMove(20, 27)), 1);

    expect(result1).toBeGreaterThan(result2);
  });
});
