import { LabeledRadioInput } from "@/components/common/labeled-radio/labeled-radio";
import {
  StatusDraw,
  StatusNextO,
  StatusNextX,
  StatusNone,
  StatusWinO,
  StatusWinX,
} from "@/games/nought-and-cross/types";
import type { Status } from "@/games/nought-and-cross/types";
import cross from "@/images/symbol/cross.svg";
import nought from "@/images/symbol/nought.svg";
import { PlayerTypeAi, PlayerTypeHuman } from "@/scripts/player";
import type { PlayerType } from "@/scripts/player";
import { inlineImageStyle } from "@/styles/common.css";
import {
  controllerOutputStyle,
  controllerPlayerStyle,
  controllerStyle,
  restartButtonStyle,
} from "@/styles/nought-and-cross.css";
import { Match, Switch } from "solid-js";
import type { JSXElement, Setter } from "solid-js";
import { StyledSvg } from "../common/styled-svg";

type ControllerProperties = {
  readonly statusMessage: Status;
  readonly onReset: () => void;

  readonly playerO: PlayerType;
  readonly playerX: PlayerType;
  readonly setPlayerO: Setter<PlayerType>;
  readonly setPlayerX: Setter<PlayerType>;
};
export const Controller = (properties: ControllerProperties): JSXElement => {
  return (
    <div class={controllerStyle}>
      <output class={controllerOutputStyle}>
        <Switch>
          <Match when={properties.statusMessage === StatusWinO}>
            <StyledSvg src={nought.src} alt="nought" class={inlineImageStyle} /> Win!
          </Match>
          <Match when={properties.statusMessage === StatusWinX}>
            <StyledSvg src={cross.src} alt="cross" class={inlineImageStyle} /> Win!
          </Match>
          <Match when={properties.statusMessage === StatusDraw}>Draw!</Match>
          <Match when={properties.statusMessage === StatusNextO}>
            next <StyledSvg src={nought.src} alt="nought" class={inlineImageStyle} />
          </Match>
          <Match when={properties.statusMessage === StatusNextX}>
            next <StyledSvg src={cross.src} alt="cross" class={inlineImageStyle} />
          </Match>
          <Match when={properties.statusMessage === StatusNone}>{""}</Match>
        </Switch>
      </output>

      <dl class={controllerPlayerStyle}>
        <dt>
          player
          <StyledSvg src={nought.src} alt="nought" class={inlineImageStyle} />
        </dt>
        <dd>
          <LabeledRadioInput
            label="Player"
            check={() => {
              properties.setPlayerO(PlayerTypeHuman);
            }}
            checked={properties.playerO === PlayerTypeHuman}
          />
          <LabeledRadioInput
            label="AI"
            check={() => {
              properties.setPlayerO(PlayerTypeAi);
            }}
            checked={properties.playerO === PlayerTypeAi}
          />
        </dd>

        <dt>
          player
          <StyledSvg src={cross.src} alt="cross" class={inlineImageStyle} />
        </dt>
        <dd>
          <LabeledRadioInput
            label="Player"
            check={() => {
              properties.setPlayerX(PlayerTypeHuman);
            }}
            checked={properties.playerX === PlayerTypeHuman}
          />
          <LabeledRadioInput
            label="AI"
            check={() => {
              properties.setPlayerX(PlayerTypeAi);
            }}
            checked={properties.playerX === PlayerTypeAi}
          />
        </dd>
      </dl>

      <button
        type="button"
        onClick={() => {
          properties.onReset();
        }}
        class={restartButtonStyle}
      >
        Restart
      </button>
    </div>
  );
};
