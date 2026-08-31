import { NavLink, Outlet, useLocation } from 'react-router-dom';
import { useAuth } from '../auth.jsx';

const links = [
  { to: '/', label: 'Dashboard', end: true },
  { section: 'Vendor management' },
  { to: '/vendors', label: 'All vendors', end: true },
  { to: '/vendors?status=pending', label: 'Pending KYC', nested: true },
  { to: '/vendors?status=approved', label: 'Approved', nested: true },
  { to: '/vendors?status=rejected', label: 'Rejected', nested: true },
  { to: '/vendors?status=suspended', label: 'Suspended', nested: true },
  { section: 'Catalog moderation' },
  { to: '/catalog', label: 'Product review' },
  { to: '/categories', label: 'Categories' },
  { to: '/brands', label: 'Brand registry' },
  { section: 'Commerce' },
  { to: '/subscriptions', label: 'Subscriptions' },
  { to: '/orders', label: 'Orders & disputes' },
  { to: '/settings', label: 'System settings' },
];

const titles = {
  '/': 'Super Admin dashboard',
  '/vendors': 'Vendor management',
  '/catalog': 'Catalog moderation',
  '/categories': 'Categories',
  '/brands': 'Brand registry',
  '/subscriptions': 'Subscription engine',
  '/orders': 'Orders & financial oversight',
  '/settings': 'System settings',
};

export default function Layout() {
  const { profile, logout } = useAuth();
  const location = useLocation();
  const title = location.pathname.startsWith('/vendors/')
    ? 'Vendor verification'
    : titles[location.pathname] || 'Mazonn Super Admin';

  return (
    <div className="layout">
      <aside className="sidebar">
        <div className="brand">
          <small>Mazonn</small>
          <h1>Super Admin</h1>
        </div>
        {links.map((link) => (
          link.section
            ? <div className="nav-section" key={link.section}>{link.section}</div>
            : (
              <NavLink
                key={link.to}
                to={link.to}
                end={link.end}
                className={({ isActive }) => `${link.nested ? 'sub-link' : 'nav-link'}${isActive && !link.to.includes('?') ? ' active' : ''}`}
              >
                {link.label}
              </NavLink>
            )
        ))}
      </aside>
      <div className="content">
        <header className="topbar">
          <h2>{title}</h2>
          <div className="user-chip">
            <span>{profile?.fullName || profile?.email || 'Super Admin'}</span>
            <button className="btn btn-outline" type="button" onClick={logout}>Sign out</button>
          </div>
        </header>
        <main className="page">
          <Outlet />
        </main>
      </div>
    </div>
  );
}
