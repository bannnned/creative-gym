import { apiUrl, deleteRequest, getJson, postForm } from '../../shared/api/client';
import { mapSubmission, type Submission, type SubmissionDto } from './submissionTypes';

type SubmissionResponse = {
  submission: SubmissionDto | null;
};

export async function getMySubmission(roomId: string): Promise<Submission | null> {
  const response = await getJson<SubmissionResponse>(
    `/api/v1/rooms/${roomId}/submissions/me`
  );

  return response.submission ? mapSubmission(response.submission) : null;
}

export async function uploadSubmission(roomId: string, photo: File): Promise<Submission> {
  const form = new FormData();
  form.append('photo', photo);

  const response = await postForm<SubmissionResponse>(
    `/api/v1/rooms/${roomId}/submissions`,
    form
  );

  if (!response.submission) {
    throw new Error('Submission was not returned.');
  }

  return mapSubmission(response.submission);
}

export async function deleteSubmission(submissionId: string): Promise<void> {
  await deleteRequest(`/api/v1/submissions/${submissionId}`);
}

export function submissionMediaUrl(submission: Submission): string {
  return apiUrl(submission.mediaUrl);
}
