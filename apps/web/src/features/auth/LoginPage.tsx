import { Link } from 'react-router-dom';

export function LoginPage() {
  return (
    <section className="login-screen">
      <div className="login-panel">
        <p className="eyebrow">Photo workouts</p>
        <h1>Creative Gym</h1>
        <p className="lead">
          Спокойная еженедельная практика: задание, маленькая комната, одна
          фотография и анонимное голосование.
        </p>
        <div className="login-actions">
          <Link className="button primary" to="/challenges">
            Продолжить как Dev User
          </Link>
          <button className="button secondary" type="button" disabled>
            Google
          </button>
          <button className="button secondary" type="button" disabled>
            Yandex
          </button>
          <button className="button secondary" type="button" disabled>
            GitHub
          </button>
        </div>
      </div>
    </section>
  );
}
