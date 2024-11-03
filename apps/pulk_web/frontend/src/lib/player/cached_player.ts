import { useLocalStorage } from "../utils";

const LOCAL_STORAGE_ID = "pulk_player_id";

export function useCachedPlayer() {
  const [cachedPlayerId, setCachedPlayerId] = useLocalStorage<
    string | undefined
  >(LOCAL_STORAGE_ID, undefined);

  return [cachedPlayerId, setCachedPlayerId] as const;
}
