import { NavLink, Outlet } from 'react-router-dom';

export function AppLayout() {
  return (
    <div className="app-frame">
      <header className="top-bar">
        <NavLink className="brand" to="/challenges" aria-label="Creative Gym">
          <span className="brand-mark" aria-hidden="true" />
          <span>Creative Gym</span>
        </NavLink>
        <nav className="top-nav" aria-label="Главная навигация">
          <NavLink to="/challenges">Workouts</NavLink>
        </nav>
      </header>
      <main className="page-shell">
        <Outlet />
      </main>
    </div>
  );
}
