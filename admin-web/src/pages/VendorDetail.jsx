import { useEffect, useState } from 'react';
import { Link, useParams } from 'react-router-dom';
import { useAuth } from '../auth.jsx';
import { documentsStatus, fetchVendor, formatDate, resolveDocumentUrl, setVendorReadOnly, setVendorStatus, updateDocumentStatus } from '../api.js';
import ConfirmDialog from '../components/ConfirmDialog.jsx';
import StatusBadge from '../components/StatusBadge.jsx';
import { useToast } from '../components/Toast.jsx';

export default function VendorDetail() {
  const { id } = useParams();
  const { profile } = useAuth();
  const toast = useToast();
  const [vendor, setVendor] = useState(null);
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);
  const [dialog, setDialog] = useState(null);

  const load = () => fetchVendor(id).then(setVendor).catch((e) => setError(e.message || 'Unable to load vendor.'));

  useEffect(() => { load(); }, [id]);

  const run = async (status, reason = '') => {
    setBusy(true);
    try {
      await setVendorStatus({ vendor, status, reason, actor: profile });
      toast.show(`Vendor ${status}.`);
      setDialog(null);
      await load();
    } catch (e) {
      toast.show(e.message || 'Action failed.');
    } finally {
      setBusy(false);
    }
  };

  if (error) return <div className="panel state">{error}</div>;
  if (!vendor) return <div className="panel state">Loading vendor…</div>;

  const history = [...(vendor.history || [])].sort((a, b) => String(b.at || '').localeCompare(String(a.at || '')));

  return (
    <div>
      <p><Link to="/vendors">← All vendors</Link></p>
      <div className="panel" style={{ marginBottom: 16 }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', gap: 16, flexWrap: 'wrap' }}>
          <div>
            <h2 style={{ margin: '0 0 6px' }}>{vendor.businessName}</h2>
            <p>{vendor.ownerName} · {vendor.email} · {vendor.phone}</p>
            <StatusBadge status={vendor.approvalStatus} />
            {' '}
            <StatusBadge kind="docs" status={documentsStatus(vendor)} />
            <p>Billing: {vendor.billingStatus || 'active'} · Plan: {vendor.planId || 'basic'} · Cap: {vendor.listingCap || 20}</p>
          </div>
          <div className="actions">
            {vendor.approvalStatus !== 'approved' && (
              <button className="btn btn-gold" disabled={busy} type="button" onClick={() => setDialog('approve')}>APPROVE VENDOR</button>
            )}
            {vendor.approvalStatus === 'pending' && (
              <button className="btn btn-danger" disabled={busy} type="button" onClick={() => setDialog('reject')}>REJECT VENDOR</button>
            )}
            {vendor.approvalStatus === 'approved' && (
              <button className="btn btn-danger" disabled={busy} type="button" onClick={() => setDialog('suspend')}>Suspend</button>
            )}
            {vendor.approvalStatus === 'suspended' && (
              <button className="btn btn-gold" disabled={busy} type="button" onClick={() => setDialog('approve')}>Reactivate</button>
            )}
            {vendor.approvalStatus === 'approved' && vendor.billingStatus !== 'read_only' && (
              <button className="btn btn-outline" disabled={busy} type="button" onClick={async () => {
                await setVendorReadOnly({ vendor, readOnly: true, actor: profile });
                toast.show('Vendor set to read-only.');
                load();
              }}>Read-only</button>
            )}
            {vendor.billingStatus === 'read_only' && (
              <button className="btn btn-outline" disabled={busy} type="button" onClick={async () => {
                await setVendorReadOnly({ vendor, readOnly: false, actor: profile });
                toast.show('Selling restored.');
                load();
              }}>Restore selling</button>
            )}
          </div>
        </div>
      </div>

      <div className="grid-2">
        <div className="panel">
          <h3>Business information</h3>
          <p><strong>Store name</strong><br />{vendor.businessName || '—'}</p>
          <p><strong>Owner</strong><br />{vendor.ownerName || '—'}</p>
          <p><strong>Contact</strong><br />{vendor.email}<br />{vendor.phone}</p>
          <p><strong>Address</strong><br />{vendor.address || '—'}</p>
          <p><strong>Category</strong><br />{vendor.category || '—'}</p>
          <p><strong>CNIC / business ID</strong><br />{vendor.cnic || '—'}</p>
          <p><strong>Bank</strong><br />{vendor.bankName || '—'} · {vendor.accountTitle || '—'} · {vendor.iban || vendor.accountNumber || '—'}</p>
        </div>
        <div className="panel">
          <h3>Documents</h3>
          <div className="doc-list">
            {(vendor.documents || []).length === 0 && <div className="empty">No documents uploaded yet.</div>}
            {(vendor.documents || []).map((docItem) => (
              <div className="doc-card" key={docItem.id || docItem.url}>
                <div>
                  <strong>{docItem.name || docItem.type}</strong>
                  <div><StatusBadge kind="docs" status={docItem.status || 'pending'} /></div>
                  {docItem.note && <small>{docItem.note}</small>}
                </div>
                <div className="actions">
                  {docItem.url && (
                    <button className="btn btn-outline" type="button" onClick={async () => {
                      try {
                        const href = await resolveDocumentUrl(docItem);
                        if (!href) throw new Error('Document is missing.');
                        window.open(href, '_blank', 'noopener,noreferrer');
                      } catch (e) {
                        toast.show(e.message || 'Unable to open document.');
                      }
                    }}>View</button>
                  )}
                  <button className="btn btn-outline" type="button" disabled={busy} onClick={async () => {
                    await updateDocumentStatus({ vendor, documentId: docItem.id, status: 'verified', actor: profile });
                    toast.show('Document verified.');
                    load();
                  }}>Verify</button>
                  <button className="btn btn-outline" type="button" disabled={busy} onClick={async () => {
                    await updateDocumentStatus({ vendor, documentId: docItem.id, status: 'rejected', note: 'Please upload a clearer document.', actor: profile });
                    toast.show('Document rejected.');
                    load();
                  }}>Reject</button>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>

      <div className="panel" style={{ marginTop: 16 }}>
        <h3>Vendor history</h3>
        <p>Registered {formatDate(vendor.registeredAt)} · Last reviewed {formatDate(vendor.reviewedAt)} {vendor.reviewedByName ? `by ${vendor.reviewedByName}` : ''}</p>
        {vendor.rejectionReason && <p><strong>Rejection reason:</strong> {vendor.rejectionReason}</p>}
        {vendor.suspensionReason && <p><strong>Suspension reason:</strong> {vendor.suspensionReason}</p>}
        <div className="history">
          {history.length === 0 && <div className="empty">No previous admin actions.</div>}
          {history.map((item, index) => (
            <div className="history-item" key={`${item.at}-${index}`}>
              <strong>{item.action}</strong> · {item.actorName || item.actorId || 'System'}
              <div>{item.detail}</div>
              <small>{formatDate(item.at)}</small>
            </div>
          ))}
        </div>
      </div>

      <ConfirmDialog
        open={dialog === 'approve'}
        title={vendor.approvalStatus === 'suspended' ? 'Reactivate vendor' : 'Approve vendor'}
        message="This enables full Vendor Portal access, product publishing, orders, analytics, and customer-facing visibility."
        confirmLabel={vendor.approvalStatus === 'suspended' ? 'Reactivate' : 'APPROVE VENDOR'}
        onClose={() => setDialog(null)}
        onConfirm={() => run('approved')}
      />
      <ConfirmDialog
        open={dialog === 'reject'}
        title="Reject vendor"
        message="The vendor will see this reason and can update documents, then resubmit."
        confirmLabel="REJECT VENDOR"
        danger
        requireReason
        onClose={() => setDialog(null)}
        onConfirm={(reason) => run('rejected', reason)}
      />
      <ConfirmDialog
        open={dialog === 'suspend'}
        title="Suspend vendor"
        message="Products will be hidden from customers and selling will be disabled until reactivation."
        confirmLabel="Suspend"
        danger
        requireReason
        onClose={() => setDialog(null)}
        onConfirm={(reason) => run('suspended', reason)}
      />
    </div>
  );
}
