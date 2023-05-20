export * from "./local_storage";
export * from "./types";

export const notNil = <T>(value: T | null | undefined): value is T => {
  return value !== null && value !== undefined;
};
