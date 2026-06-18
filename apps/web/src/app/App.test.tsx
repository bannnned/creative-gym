import { render, screen } from '@testing-library/react';
import { describe, expect, it } from 'vitest';
import { App } from './App';

describe('App', () => {
  it('renders the login route', () => {
    render(<App />);

    expect(screen.getByRole('heading', { name: 'Creative Gym' })).toBeVisible();
    expect(screen.getByRole('link', { name: /продолжить/i })).toBeVisible();
  });
});
