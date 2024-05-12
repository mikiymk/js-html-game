export const CLUB = "club";
export const DIAMOND = "diamond";
export const HEART = "heart";
export const SPADE = "spade";

export type Suit = typeof CLUB | typeof DIAMOND | typeof HEART | typeof SPADE;

export const Ranks = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13] as const;
export type Rank = typeof Ranks[number];
