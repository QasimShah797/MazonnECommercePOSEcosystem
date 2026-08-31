import { useEffect, useMemo, useState } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { documentsStatus, fetchVendors, formatDate } from '../api.js';
import StatusBadge from '../components/StatusBadge.jsx';

const filters = [
  { id: 'all', label: 'All' },
  { id: 'pending', label: 'Pending' },
  { id: 'approved', label: 'Approved' },
  { id: 'rejected', label: 'Rejected' },
  { id: 'suspended', label: 'Suspended' },
];

export default function Vendors() {
  const [vendors, setVendors] = useState([]);
  const [error, setError] = useState('');
  const [query, setQuery] = useState('');
  const [params, setParams] = useSearchParams();
  const navigate = useNavigate();
  const status = params.get('status') || 'all';

  useEffect(() => {
    fetchVendors().then(setVendors).catch((e) => setError(e.message || 'Unable to load vendors.'));
  }, []);

  const stats = {
    total: vendors.length,
    pending: vendors.filter((v) => v.approvalStatus === 'pending').length,
    approved: vendors.filter((v) => v.approvalStatus === 'approved').length,
    rejected: vendors.filter((v) => v.approvalStatus === 'rejected').length,
    suspended: vendors.filter((v) => v.approvalStatus === 'suspended').length,
  };

  const rows = useMemo(() => {
    const q = query.trim().toLowerCase();
    return vendors.filter((vendor) => {
      const matchStatus = status === 'all' || vendor.approvalStatus === status;
      const haystack = [vendor.businessName, vendor.ownerName, vendor.email, vendor.phone].join(' ').toLowerCase();
      return matchStatus && (!q || haystack.includes(q));
    });
  }, [vendors, query, status]);

  if (error) return <div className="panel state">{error}</div>;

  return (
    <div>
      <div className="cards">
        <div className="card"><div className="label">Total Vendors</div><div className="value">{stats.total}</div></div>
        <div className="card"><div className="label">Pending Approval</div><div className="value">{stats.pending}</div></div>
        <div className="card"><div className="label">Approved</div><div className="value">{stats.approved}</div></div>
        <div className="card"><div className="label">Rejected</div><div className="value">{stats.rejected}</div></div>
        <div className="card"><div className="label">Suspended</div><div className="value">{stats.suspended}</div></div>
      </div>
      <div className="toolbar">
        <input className="search" placeholder="Search store, owner, email, or phone" value={query} onChange={(e) => setQuery(e.target.value)} />
        <div className="filters">
          {filters.map((item) => (
            <button
              key={item.id}
              type="button"
              className={`chip${status === item.id ? ' active' : ''}`}
              onClick={() => setParams(item.id === 'all' ? {} : { status: item.id })}
            >
              {item.label}
            </button>
          ))}
        </div>
      </div>
      <div className="panel table-wrap">
        {rows.length === 0 ? <div className="empty">No vendors match this filter.</div> : (
          <table>
            <thead>
              <tr>
                <th>Store Name</th>
                <th>Owner Name</th>
                <th>Email</th>
                <th>Phone</th>
                <th>Registration Date</th>
                <th>Verification Status</th>
                <th>Documents Status</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {rows.map((vendor) => (
                <tr key={vendor.id} className="row-link" onClick={() => navigate(`/vendors/${vendor.id}`)}>
                  <td>{vendor.businessName || '—'}</td>
                  <td>{vendor.ownerName || '—'}</td>
                  <td>{vendor.email || '—'}</td>
                  <td>{vendor.phone || '—'}</td>
                  <td>{formatDate(vendor.registeredAt)}</td>
                  <td><StatusBadge status={vendor.approvalStatus} /></td>
                  <td><StatusBadge kind="docs" status={documentsStatus(vendor)} /></td>
                  <td><button type="button" className="btn btn-outline" onClick={(e) => { e.stopPropagation(); navigate(`/vendors/${vendor.id}`); }}>Review</button></td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
}
