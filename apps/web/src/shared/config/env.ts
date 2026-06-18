export const env = {
  apiBaseUrl: import.meta.env.VITE_API_BASE_URL ?? '',
  devUserId:
    import.meta.env.VITE_DEV_USER_ID ??
    '00000000-0000-0000-0000-000000000001'
};
