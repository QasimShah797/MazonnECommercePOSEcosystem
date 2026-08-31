import { useEffect, useState } from 'react';
import { useAuth } from '../auth.jsx';
import { fetchAuditLogs, fetchSettings, formatDate, saveSettings } from '../api.js';
import { useToast } from '../components/Toast.jsx';

export default function Settings() {
  const { profile } = useAuth();
  const toast = useToast();
  const [settings, setSettings] = useState(null);
  const [logs, setLogs] = useState([]);
  const [logoUrl, setLogoUrl] = useState('');
  const [businessName, setBusinessName] = useState('Mazonn');

  useEffect(() => {
    fetchSettings().then((s) => {
      setSettings(s);
      setLogoUrl(s.logoUrl || '');
      setBusinessName(s.businessName || 'Mazonn');
    });
    fetchAuditLogs().then(setLogs).catch(() => setLogs([]));
  }, []);

  if (!settings) return <div className="panel state">Loading settings…</div>;

  return (
    <div>
      <form className="panel stack" onSubmit={async (e) => {
        e.preventDefault();
        await saveSettings({ businessName, logoUrl }, profile);
        toast.show('System settings saved.');
      }}>
        <h3>Platform</h3>
        <label>Language<input className="field" value="English" readOnly /></label>
        <label>Currency<input className="field" value="PKR (fixed base currency)" readOnly /></label>
        <label>Date format<input className="field" value="DD-MM-YYYY" readOnly /></label>
        <label>Business name<input className="field" value={businessName} onChange={(e) => setBusinessName(e.target.value)} /></label>
        <label>Logo URL<input className="field" value={logoUrl} onChange={(e) => setLogoUrl(e.target.value)} placeholder="https://…" /></label>
        <button className="btn btn-primary" type="submit">Save</button>
      </form>
      <div className="panel" style={{ marginTop: 20 }}>
        <h3>Admin activity</h3>
        {logs.length === 0 ? <div className="empty">No admin actions yet.</div> : logs.slice(0, 25).map((log) => (
          <div className="history-item" key={log.id}>
            <strong>{log.action}</strong>
            <div>{log.actorName || log.actorId}</div>
            <small>{formatDate(log.createdAt)}</small>
          </div>
        ))}
      </div>
    </div>
  );
}
