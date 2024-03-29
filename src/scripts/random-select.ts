export const randomRange = (min: number, max: number): number => {
  return Math.floor(Math.random() * (max - min)) + min;
};

export const randomSelect = <T>(list: readonly T[]): T | undefined => {
  if (list.length === 0) {
    return undefined;
  }

  return list[randomRange(0, list.length)];
};
