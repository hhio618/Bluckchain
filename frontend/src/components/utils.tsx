export const formatBets = (value: string) => {
  const num = parseFloat(value);
  if (num < 0.0001) {
    return "~0.0";
  }
  return num.toFixed(5);
};
