import { Skin } from "./type";
import w95Skin from "./w95";

const SKINS = {
  w95: w95Skin,
};
export type SkinType = keyof typeof SKINS;

export const getSkin = (skinType: SkinType): Skin => {
  return SKINS[skinType];
};
