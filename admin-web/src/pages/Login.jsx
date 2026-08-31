import { useState } from 'react';
import { useAuth } from '../auth.jsx';

export default function Login() {
  const { login, error, setError } = useAuth();
  const [email, setEmail] = useState('admin@mazonn.app');
  const [password, setPassword] = useState('admin123');
  const [busy, setBusy] = useState(false);
  const [localError, setLocalError] = useState('');

  return (
    <div className="login">
      <form
        className="panel login-card"
        onSubmit={async (e) => {
          e.preventDefault();
          setBusy(true);
          setLocalError('');
          setError('');
          try {
            await login(email, password);
          } catch (err) {
            setLocalError(err.message || 'Unable to sign in.');
          } finally {
            setBusy(false);
          }
        }}
      >
        <small style={{ letterSpacing: '0.14em', textTransform: 'uppercase', color: 'var(--gold-dark)' }}>Mazonn</small>
        <h1>Super Admin</h1>
        <p>Vendor verification, approvals, and platform control.</p>
        {(localError || error) && <p className="error">{localError || error}</p>}
        <div className="stack">
          <label>Email<input className="field" value={email} onChange={(e) => setEmail(e.target.value)} type="email" required /></label>
          <label>Password<input className="field" value={password} onChange={(e) => setPassword(e.target.value)} type="password" required /></label>
          <button className="btn btn-primary" disabled={busy} type="submit">{busy ? 'Signing in…' : 'Sign in'}</button>
        </div>
      </form>
    </div>
  );
}
