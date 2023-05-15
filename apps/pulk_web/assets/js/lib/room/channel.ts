import { Channel } from "phoenix";
import { Matrix } from "../matrix";

export enum RoomEventType {
  BOARD_UPDATE = "board_update",
}

export type RoomOutgoingMessagePayload = {
  [RoomEventType.BOARD_UPDATE]: { matrix: Matrix };
};

export const pushRoomMessage = <T extends RoomEventType>(
  channel: Channel,
  messageType: T,
  payload: RoomOutgoingMessagePayload[T]
) => {
  channel.push(messageType, payload);
};

export type RoomIncomingMessagePayload = {
  [RoomEventType.BOARD_UPDATE]: { board: Matrix; player_id: string };
};

export function onRoomMessage<T extends RoomEventType>(
  channel: Channel,
  messageType: T,
  callback: (payload: RoomIncomingMessagePayload[T]) => void
): number {
  return channel.on(messageType, callback);
}
