import { useEffect, useState } from 'react';
import { useAuth } from '../auth.jsx';
import { fetchCategoriesAdmin, saveCategory, saveCommission } from '../api.js';
import { useToast } from '../components/Toast.jsx';

export default function Categories() {
  const { profile } = useAuth();
  const toast = useToast();
  const [rows, setRows] = useState([]);
  const [form, setForm] = useState({ name: '', subtitle: '', subcategories: '', commissionPercent: 10 });

  const load = () => fetchCategoriesAdmin().then(setRows);
  useEffect(() => { load(); }, []);

  return (
    <div className="grid-2">
      <div className="panel">
        <h3>Global categories</h3>
        {rows.map((c) => (
          <div className="history-item" key={c.id}>
            <strong>{c.name}</strong>
            <div>{c.subtitle}</div>
            <div>Sub-categories: {(c.subcategories || []).join(', ') || '—'}</div>
            <div>Commission (Phase 3): {c.commissionPercent ?? 10}%</div>
            <form className="toolbar" onSubmit={async (e) => {
              e.preventDefault();
              const percent = Number(new FormData(e.currentTarget).get('percent'));
              await saveCommission({ categoryId: c.id, percent, actor: profile });
              toast.show('Commission saved for Phase 3.');
              load();
            }}>
              <input className="field" name="percent" type="number" min="0" max="40" defaultValue={c.commissionPercent ?? 10} style={{ width: 90 }} />
              <button className="btn btn-outline" type="submit">Save %</button>
            </form>
          </div>
        ))}
      </div>
      <form className="panel stack" onSubmit={async (e) => {
        e.preventDefault();
        await saveCategory({
          name: form.name,
          subtitle: form.subtitle,
          subcategories: form.subcategories.split(',').map((s) => s.trim()).filter(Boolean),
          commissionPercent: Number(form.commissionPercent),
        }, profile);
        toast.show('Category saved.');
        setForm({ name: '', subtitle: '', subcategories: '', commissionPercent: 10 });
        load();
      }}>
        <h3>Create category</h3>
        <label>Name<input className="field" required value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} /></label>
        <label>Subtitle<input className="field" value={form.subtitle} onChange={(e) => setForm({ ...form, subtitle: e.target.value })} /></label>
        <label>Sub-categories (comma separated)<input className="field" value={form.subcategories} onChange={(e) => setForm({ ...form, subcategories: e.target.value })} /></label>
        <label>Commission % (Phase 3 backend)<input className="field" type="number" value={form.commissionPercent} onChange={(e) => setForm({ ...form, commissionPercent: e.target.value })} /></label>
        <button className="btn btn-primary" type="submit">Save category</button>
      </form>
    </div>
  );
}
