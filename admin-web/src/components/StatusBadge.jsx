import { documentsLabel, statusLabel } from '../api.js';

export default function StatusBadge({ status, kind = 'vendor' }) {
  const value = status || 'pending';
  const label = kind === 'docs' ? documentsLabel(value) : statusLabel(value);
  return <span className={`badge ${value}`}>{label}</span>;
}
