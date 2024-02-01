import { Board } from "@/components/board/board";
import board from "@/images/shogi/board.svg";
import type { JSXElement } from "solid-js";
import { Square } from "./square";

type BoardProperties = {
  readonly board: readonly number[];
};
export const ShogiBoard = (properties: BoardProperties): JSXElement => {
  return (
    <Board height={9} width={9} data={properties.board} background={board.src}>
      {(square, _, x, y) => <Square x={x()} y={y()} square={square} />}
    </Board>
  );
};