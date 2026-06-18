export type Submission = {
  id: string;
  roomId: string;
  mediaUrl: string;
  contentType: string;
  byteSize: number;
  createdAt: string;
  updatedAt: string;
};

export type SubmissionDto = {
  id: string;
  room_id: string;
  media_url: string;
  content_type: string;
  byte_size: number;
  created_at: string;
  updated_at: string;
};

export function mapSubmission(dto: SubmissionDto): Submission {
  return {
    id: dto.id,
    roomId: dto.room_id,
    mediaUrl: dto.media_url,
    contentType: dto.content_type,
    byteSize: dto.byte_size,
    createdAt: dto.created_at,
    updatedAt: dto.updated_at
  };
}
