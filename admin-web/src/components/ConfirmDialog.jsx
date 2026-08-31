export default function ConfirmDialog({
  open,
  title,
  message,
  confirmLabel = 'Confirm',
  danger = false,
  requireReason = false,
  onClose,
  onConfirm,
}) {
  if (!open) return null;
  return (
    <div className="modal-backdrop" onClick={onClose}>
      <form
        className="modal"
        onClick={(e) => e.stopPropagation()}
        onSubmit={(e) => {
          e.preventDefault();
          const reason = new FormData(e.currentTarget).get('reason')?.toString().trim() || '';
          if (requireReason && !reason) return;
          onConfirm(reason);
        }}
      >
        <h3>{title}</h3>
        <p>{message}</p>
        {requireReason && (
          <textarea className="field" name="reason" rows="4" required placeholder="Enter a reason the vendor will see" />
        )}
        <div className="actions" style={{ marginTop: 16 }}>
          <button type="button" className="btn btn-outline" onClick={onClose}>Cancel</button>
          <button type="submit" className={`btn ${danger ? 'btn-danger' : 'btn-gold'}`}>{confirmLabel}</button>
        </div>
      </form>
    </div>
  );
}
