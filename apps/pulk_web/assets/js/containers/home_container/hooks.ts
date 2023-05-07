import useSWR from "swr";

export const useAvailableRoom = (): {
  roomId: string | undefined;
  isLoading: boolean;
} => {
  const { data, error, isLoading } = useSWR<{ data: { room_id: string } }>(
    "/api/room"
  );

  if (isLoading) {
    return { roomId: undefined, isLoading: true };
  }

  if (error !== undefined) {
    return { roomId: undefined, isLoading: false };
  }

  return { roomId: data?.data.room_id, isLoading: false };
};
