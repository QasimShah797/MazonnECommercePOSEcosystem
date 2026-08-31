import { createContext, useContext, useMemo, useState } from 'react';

const ToastContext = createContext(null);

export function ToastProvider({ children }) {
  const [toasts, setToasts] = useState([]);
  const api = useMemo(() => ({
    show(message) {
      const id = Date.now() + Math.random();
      setToasts((current) => [...current, { id, message }]);
      setTimeout(() => setToasts((current) => current.filter((item) => item.id !== id)), 3200);
    },
  }), []);

  return (
    <ToastContext.Provider value={api}>
      {children}
      <div className="toast-wrap">
        {toasts.map((toast) => <div className="toast" key={toast.id}>{toast.message}</div>)}
      </div>
    </ToastContext.Provider>
  );
}

export function useToast() {
  return useContext(ToastContext);
}
