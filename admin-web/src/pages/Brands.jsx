import { useEffect, useState } from 'react';
import { useAuth } from '../auth.jsx';
import { fetchBrands, saveBrand } from '../api.js';
import { useToast } from '../components/Toast.jsx';

export default function Brands() {
  const { profile } = useAuth();
  const toast = useToast();
  const [rows, setRows] = useState([]);
  const [name, setName] = useState('');
  const load = () => fetchBrands().then(setRows);
  useEffect(() => { load(); }, []);

  return (
    <div>
      <form className="toolbar" onSubmit={async (e) => {
        e.preventDefault();
        await saveBrand({ name }, profile);
        toast.show('Brand added to the registry.');
        setName('');
        load();
      }}>
        <input className="search" required placeholder="Brand name" value={name} onChange={(e) => setName(e.target.value)} />
        <button className="btn btn-primary" type="submit">Add brand</button>
      </form>
      <div className="panel table-wrap">
        <table>
          <thead><tr><th>Brand</th><th>Status</th></tr></thead>
          <tbody>
            {rows.map((b) => (
              <tr key={b.id}>
                <td>{b.name}</td>
                <td>{b.status || 'active'}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
