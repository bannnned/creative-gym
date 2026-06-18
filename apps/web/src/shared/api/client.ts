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

export async function postForm<T>(path: string, body: FormData): Promise<T> {
  return requestJson<T>(path, {
    method: 'POST',
    body,
    headers: {
      'X-Dev-User-Id': env.devUserId
    }
  });
}

export async function deleteRequest(path: string): Promise<void> {
  await requestJson<unknown>(path, {
    method: 'DELETE'
  });
}

export function apiUrl(path: string): string {
  return `${env.apiBaseUrl}${path}`;
}

async function requestJson<T>(
  path: string,
  init: RequestInit
): Promise<T> {
  const headers = new Headers(init.headers);
  if (!headers.has('Content-Type') && typeof init.body === 'string') {
    headers.set('Content-Type', 'application/json');
  }
  if (!headers.has('X-Dev-User-Id')) {
    headers.set('X-Dev-User-Id', env.devUserId);
  }

  const response = await fetch(`${env.apiBaseUrl}${path}`, {
    ...init,
    headers
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
