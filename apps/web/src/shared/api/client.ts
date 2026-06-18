import { env } from '../config/env';
import { ApiError } from './apiError';

type ApiErrorBody = {
  error?: {
    code?: string;
    message?: string;
  };
};

export async function getJson<T>(path: string): Promise<T> {
  return requestJson<T>(path, { method: 'GET' });
}

export async function postJson<T>(path: string, body?: unknown): Promise<T> {
  return requestJson<T>(path, {
    method: 'POST',
    body: body === undefined ? undefined : JSON.stringify(body)
  });
}

async function requestJson<T>(
  path: string,
  init: RequestInit
): Promise<T> {
  const response = await fetch(`${env.apiBaseUrl}${path}`, {
    ...init,
    headers: {
      'Content-Type': 'application/json',
      'X-Dev-User-Id': env.devUserId,
      ...init.headers
    }
  });

  const data = await readJson(response);

  if (!response.ok) {
    const errorBody = data as ApiErrorBody;
    throw new ApiError(
      errorBody.error?.message ?? 'Request failed.',
      errorBody.error?.code,
      response.status
    );
  }

  return data as T;
}

async function readJson(response: Response): Promise<unknown> {
  const text = await response.text();
  if (!text) {
    return {};
  }

  try {
    return JSON.parse(text);
  } catch {
    throw new ApiError('Invalid JSON response.', undefined, response.status);
  }
}
