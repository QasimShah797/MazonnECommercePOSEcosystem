import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { ensurePlatformDefaults, fetchOrders, fetchProducts, fetchVendors, money } from '../api.js';
import StatusBadge from '../components/StatusBadge.jsx';

export default function Dashboard() {
  const [data, setData] = useState(null);
  const [error, setError] = useState('');

  useEffect(() => {
    ensurePlatformDefaults()
      .then(() => Promise.all([fetchVendors(), fetchProducts(), fetchOrders()]))
      .then(([vendors, products, orders]) => setData({ vendors, products, orders }))
      .catch((e) => setError(e.message || 'Unable to load dashboard.'));
  }, []);

  if (error) return <div className="panel state">{error}</div>;
  if (!data) return <div className="panel state">Loading dashboard…</div>;

  const pending = data.vendors.filter((v) => v.approvalStatus === 'pending');
  const queued = data.products.filter((p) => p.moderation === 'pending');
  const disputes = data.orders.filter((o) => o.disputeStatus && o.disputeStatus !== 'none');
  const readOnly = data.vendors.filter((v) => v.billingStatus === 'read_only' || v.billingStatus === 'grace');

  const stats = [
    ['Pending KYC', pending.length],
    ['Product queue', queued.length],
    ['Disputes', disputes.length],
    ['Billing alerts', readOnly.length],
    ['Live catalog', data.products.filter((p) => p.moderation === 'approved' && p.vendorApprovalStatus === 'approved').length],
    ['GMV (PKR)', money(data.orders.reduce((sum, o) => sum + Number(o.total || 0), 0))],
  ];

  return (
    <div>
      <div className="cards">
        {stats.map(([label, value]) => (
          <div className="card" key={label}>
            <div className="label">{label}</div>
            <div className="value">{value}</div>
          </div>
        ))}
      </div>
      <div className="grid-2" style={{ marginTop: 20 }}>
        <div className="panel">
          <h3>KYC waiting for review</h3>
          {pending.length === 0 ? <div className="empty">No vendor applications waiting.</div> : (
            <table>
              <tbody>
                {pending.slice(0, 8).map((vendor) => (
                  <tr key={vendor.id}>
                    <td><Link to={`/vendors/${vendor.id}`}>{vendor.businessName}</Link></td>
                    <td>{vendor.ownerName}</td>
                    <td><StatusBadge status={vendor.approvalStatus} /></td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
        <div className="panel">
          <h3>Catalog queue</h3>
          {queued.length === 0 ? <div className="empty">No products waiting for approval.</div> : queued.slice(0, 8).map((p) => (
            <div className="history-item" key={p.id}>
              <Link to="/catalog"><strong>{p.name}</strong></Link>
              <div>{p.vendorName} · {money(p.price)}</div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
