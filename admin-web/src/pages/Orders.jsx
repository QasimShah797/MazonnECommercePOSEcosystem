import { useEffect, useState } from 'react';
import { useAuth } from '../auth.jsx';
import { fetchOrders, flagOrderDispute, formatDate, money } from '../api.js';
import ConfirmDialog from '../components/ConfirmDialog.jsx';
import { useToast } from '../components/Toast.jsx';

const STATUSES = ['all', 'pending', 'processing', 'shipped', 'delivered', 'cancelled', 'rejected'];

export default function Orders() {
  const { profile } = useAuth();
  const toast = useToast();
  const [rows, setRows] = useState([]);
  const [status, setStatus] = useState('all');
  const [error, setError] = useState('');
  const [dispute, setDispute] = useState(null);

  const load = () => fetchOrders().then(setRows).catch((e) => setError(e.message));
  useEffect(() => { load(); }, []);

  const filtered = rows.filter((o) => status === 'all' || o.status === status);
  if (error) return <div className="panel state">{error}</div>;

  return (
    <div>
      <div className="filters" style={{ marginBottom: 16 }}>
        {STATUSES.map((id) => (
          <button key={id} type="button" className={`chip${status === id ? ' active' : ''}`} onClick={() => setStatus(id)}>{id}</button>
        ))}
        <button type="button" className={`chip${status === 'disputes' ? ' active' : ''}`} onClick={() => setStatus('disputes')}>disputes</button>
      </div>
      <div className="panel table-wrap">
        {(status === 'disputes' ? rows.filter((o) => o.disputeStatus && o.disputeStatus !== 'none') : filtered).length === 0
          ? <div className="empty">No orders in this view.</div>
          : (
          <table>
            <thead>
              <tr>
                <th>Order</th>
                <th>Vendor</th>
                <th>Customer</th>
                <th>Total</th>
                <th>Status</th>
                <th>Dispute</th>
                <th>Placed</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              {(status === 'disputes' ? rows.filter((o) => o.disputeStatus && o.disputeStatus !== 'none') : filtered).map((o) => (
                <tr key={o.id}>
                  <td>{o.id}</td>
                  <td>{o.vendorName || o.vendorId}</td>
                  <td>{o.customerName || o.customerId}</td>
                  <td>{money(o.total)}</td>
                  <td>{o.status}</td>
                  <td>{o.disputeStatus && o.disputeStatus !== 'none' ? o.disputeStatus : '—'}</td>
                  <td>{formatDate(o.placedAt)}</td>
                  <td className="actions">
                    <button className="btn btn-outline" type="button" onClick={() => setDispute(o)}>Flag / escalate</button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
      <ConfirmDialog
        open={Boolean(dispute)}
        title="Dispute"
        message="Flag for review or escalate. This is recorded on the order and in the admin audit log."
        confirmLabel="Save dispute"
        requireReason
        onClose={() => setDispute(null)}
        onConfirm={async (note) => {
          await flagOrderDispute({ order: dispute, status: note.toLowerCase().includes('escalate') ? 'escalated' : 'flagged', note, actor: profile });
          toast.show('Dispute saved.');
          setDispute(null);
          load();
        }}
      />
    </div>
  );
}
