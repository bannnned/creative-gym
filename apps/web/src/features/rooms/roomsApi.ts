import { getJson } from '../../shared/api/client';
import { mapRoom, type Room, type RoomDto } from './roomTypes';

type RoomResponse = {
  room: RoomDto;
};

export async function getRoom(roomId: string): Promise<Room> {
  const response = await getJson<RoomResponse>(`/api/v1/rooms/${roomId}`);
  return mapRoom(response.room);
}
