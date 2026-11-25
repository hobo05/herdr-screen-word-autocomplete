export function terminalOnScreen(focus) {
  return focus?.shown ?? focus?.terminal ?? null;
}
