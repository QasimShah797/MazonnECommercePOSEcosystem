import { useEffect, useState } from 'react';
import { useAuth } from '../auth.jsx';
import { fetchProducts, money, setProductModeration } from '../api.js';
import ConfirmDialog from '../components/ConfirmDialog.jsx';
import { useToast } from '../components/Toast.jsx';

export default function Products() {
  const { profile } = useAuth();
  const toast = useToast();
  const [rows, setRows] = useState([]);
  const [filter, setFilter] = useState('pending');
  const [query, setQuery] = useState('');
  const [error, setError] = useState('');
  const [rejecting, setRejecting] = useState(null);

  const load = () => fetchProducts().then(setRows).catch((e) => setError(e.message));
  useEffect(() => { load(); }, []);

  const filtered = rows.filter((p) => {
    const match = `${p.name} ${p.vendorName} ${p.brand} ${p.sku}`.toLowerCase().includes(query.toLowerCase());
    if (!match) return false;
    if (filter === 'all') return true;
    return p.moderation === filter;
  });

  if (error) return <div className="panel state">{error}</div>;

  return (
    <div>
      <p>Products stay hidden from customers until both catalog moderation and vendor KYC are approved.</p>
      <div className="toolbar">
        <input className="search" placeholder="Search product, vendor, brand" value={query} onChange={(e) => setQuery(e.target.value)} />
        <div className="filters">
          {['pending', 'approved', 'rejected', 'draft', 'all'].map((id) => (
            <button key={id} type="button" className={`chip${filter === id ? ' active' : ''}`} onClick={() => setFilter(id)}>{id}</button>
          ))}
        </div>
      </div>
      <div className="panel table-wrap">
        {filtered.length === 0 ? <div className="empty">No products in this queue.</div> : (
          <table>
            <thead>
              <tr>
                <th>Product</th>
                <th>Vendor</th>
                <th>Brand</th>
                <th>Price</th>
                <th>Moderation</th>
                <th>Vendor KYC</th>
                <th>Marketplace</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              {filtered.map((p) => {
                const live = p.isActive && p.moderation === 'approved' && p.vendorApprovalStatus === 'approved';
                return (
                  <tr key={p.id}>
                    <td>{p.name}</td>
                    <td>{p.vendorName}</td>
                    <td>{p.brand}</td>
                    <td>{money(p.price)}</td>
                    <td>{p.moderation}</td>
                    <td>{p.vendorApprovalStatus || 'approved'}</td>
                    <td>{live ? 'Visible' : 'Hidden'}</td>
                    <td className="actions">
                      <button className="btn btn-gold" type="button" onClick={async () => {
                        await setProductModeration({ product: p, status: 'approved', actor: profile });
                        toast.show('Product approved for marketplace.');
                        load();
                      }}>Approve</button>
                      <button className="btn btn-danger" type="button" onClick={() => setRejecting(p)}>Reject</button>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        )}
      </div>
      <ConfirmDialog
        open={Boolean(rejecting)}
        title="Reject product"
        message="The product will stay hidden from customers. The vendor will see this reason."
        confirmLabel="Reject"
        danger
        requireReason
        onClose={() => setRejecting(null)}
        onConfirm={async (reason) => {
          await setProductModeration({ product: rejecting, status: 'rejected', reason, actor: profile });
          toast.show('Product rejected.');
          setRejecting(null);
          load();
        }}
      />
    </div>
  );
}
