import { Navigate, Route, Routes } from 'react-router-dom';
import { useAuth } from './auth.jsx';
import Layout from './components/Layout.jsx';
import Login from './pages/Login.jsx';
import Dashboard from './pages/Dashboard.jsx';
import Vendors from './pages/Vendors.jsx';
import VendorDetail from './pages/VendorDetail.jsx';
import Products from './pages/Products.jsx';
import Categories from './pages/Categories.jsx';
import Brands from './pages/Brands.jsx';
import Subscriptions from './pages/Subscriptions.jsx';
import Orders from './pages/Orders.jsx';
import Settings from './pages/Settings.jsx';

function Guard({ children }) {
  const { loading, isAdmin } = useAuth();
  if (loading) return <div className="state">Checking Super Admin access…</div>;
  if (!isAdmin) return <Navigate to="/login" replace />;
  return children;
}

export default function App() {
  const { isAdmin, loading } = useAuth();
  return (
    <Routes>
      <Route path="/login" element={loading ? <div className="state">Loading…</div> : isAdmin ? <Navigate to="/" replace /> : <Login />} />
      <Route path="/" element={<Guard><Layout /></Guard>}>
        <Route index element={<Dashboard />} />
        <Route path="vendors" element={<Vendors />} />
        <Route path="vendors/:id" element={<VendorDetail />} />
        <Route path="catalog" element={<Products />} />
        <Route path="categories" element={<Categories />} />
        <Route path="brands" element={<Brands />} />
        <Route path="subscriptions" element={<Subscriptions />} />
        <Route path="orders" element={<Orders />} />
        <Route path="settings" element={<Settings />} />
      </Route>
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}
