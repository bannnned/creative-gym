import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom';
import { ChallengeDetailsPage } from '../features/challenges/ChallengeDetailsPage';
import { ChallengesPage } from '../features/challenges/ChallengesPage';
import { LoginPage } from '../features/auth/LoginPage';
import { RoomPage } from '../features/rooms/RoomPage';
import { AppLayout } from './AppLayout';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 30_000,
      retry: 1
    }
  }
});

export function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <BrowserRouter>
        <Routes>
          <Route element={<AppLayout />}>
            <Route index element={<Navigate to="/login" replace />} />
            <Route path="/login" element={<LoginPage />} />
            <Route path="/challenges" element={<ChallengesPage />} />
            <Route
              path="/challenges/:challengeId"
              element={<ChallengeDetailsPage />}
            />
            <Route path="/rooms/:roomId" element={<RoomPage />} />
            <Route path="*" element={<Navigate to="/challenges" replace />} />
          </Route>
        </Routes>
      </BrowserRouter>
    </QueryClientProvider>
  );
}
