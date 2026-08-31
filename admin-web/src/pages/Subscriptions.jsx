import { useEffect, useState } from 'react';
import { useAuth } from '../auth.jsx';
import {
  assignVendorPlan,
  fetchPlans,
  fetchSubscriptions,
  fetchVendors,
  money,
  recordBillingEvent,
  savePlan,
  tokenizePaymentMethod,
} from '../api.js';
import { useToast } from '../components/Toast.jsx';

export default function Subscriptions() {
  const { profile } = useAuth();
  const toast = useToast();
  const [plans, setPlans] = useState([]);
  const [vendors, setVendors] = useState([]);
  const [subs, setSubs] = useState([]);
  const [vendorId, setVendorId] = useState('');
  const [planId, setPlanId] = useState('basic');
  const [interval, setInterval] = useState('monthly');
  const [card, setCard] = useState({ last4: '', brand: 'Visa', expMonth: '12', expYear: '2028' });

  const load = () => Promise.all([fetchPlans(), fetchVendors(), fetchSubscriptions()]).then(([p, v, s]) => {
    setPlans(p);
    setVendors(v);
    setSubs(s);
  });
  useEffect(() => { load(); }, []);

  const vendor = vendors.find((v) => v.id === vendorId);
  const plan = plans.find((p) => p.id === planId);

  return (
    <div>
      <div className="cards">
        {plans.map((p) => (
          <div className="card" key={p.id}>
            <div className="label">{p.name}</div>
            <div className="value">{money(p.monthlyPrice)}</div>
            <p>{p.listingCap} listings · yearly {money(p.yearlyPrice)}</p>
          </div>
        ))}
      </div>

      <div className="grid-2" style={{ marginTop: 20 }}>
        <form className="panel stack" onSubmit={async (e) => {
          e.preventDefault();
          if (!vendor || !plan) return;
          await assignVendorPlan({ vendor, plan, interval, actor: profile });
          toast.show('Plan assigned with proration.');
          load();
        }}>
          <h3>Assign / change plan</h3>
          <p>Upgrades and downgrades are prorated against the unused portion of the current period.</p>
          <label>Vendor
            <select className="select" value={vendorId} onChange={(e) => setVendorId(e.target.value)} required>
              <option value="">Select vendor</option>
              {vendors.map((v) => <option key={v.id} value={v.id}>{v.businessName}</option>)}
            </select>
          </label>
          <label>Plan
            <select className="select" value={planId} onChange={(e) => setPlanId(e.target.value)}>
              {plans.map((p) => <option key={p.id} value={p.id}>{p.name}</option>)}
            </select>
          </label>
          <label>Billing
            <select className="select" value={interval} onChange={(e) => setInterval(e.target.value)}>
              <option value="monthly">Monthly</option>
              <option value="yearly">Yearly</option>
            </select>
          </label>
          <button className="btn btn-primary" type="submit">Save plan</button>
        </form>

        <form className="panel stack" onSubmit={async (e) => {
          e.preventDefault();
          if (!vendor) return;
          await tokenizePaymentMethod({ vendor, ...card, actor: profile });
          toast.show('Card tokenized. PAN was not stored.');
          load();
        }}>
          <h3>Tokenized card</h3>
          <p>Only last 4 digits, brand, and expiry are saved. Full card numbers are never written to the database.</p>
          <label>Vendor
            <select className="select" value={vendorId} onChange={(e) => setVendorId(e.target.value)} required>
              <option value="">Select vendor</option>
              {vendors.map((v) => <option key={v.id} value={v.id}>{v.businessName}</option>)}
            </select>
          </label>
          <label>Last 4<input className="field" required maxLength={4} value={card.last4} onChange={(e) => setCard({ ...card, last4: e.target.value.replace(/\D/g, '') })} /></label>
          <label>Brand
            <select className="select" value={card.brand} onChange={(e) => setCard({ ...card, brand: e.target.value })}>
              <option>Visa</option>
              <option>Mastercard</option>
              <option>UnionPay</option>
            </select>
          </label>
          <div className="toolbar">
            <input className="field" style={{ width: 80 }} value={card.expMonth} onChange={(e) => setCard({ ...card, expMonth: e.target.value })} />
            <input className="field" style={{ width: 100 }} value={card.expYear} onChange={(e) => setCard({ ...card, expYear: e.target.value })} />
          </div>
          <button className="btn btn-outline" type="submit">Create payment token</button>
        </form>
      </div>

      <div className="panel" style={{ marginTop: 20 }}>
        <h3>Vendor subscriptions</h3>
        <p>Failed charges start a 3-day grace period, then the store becomes read-only automatically.</p>
        <div className="table-wrap">
          <table>
            <thead>
              <tr>
                <th>Store</th>
                <th>Plan</th>
                <th>Status</th>
                <th>Period end</th>
                <th>Card</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              {subs.map((s) => {
                const v = vendors.find((item) => item.id === s.vendorId) || { id: s.vendorId, businessName: s.storeName };
                return (
                  <tr key={s.id}>
                    <td>{s.storeName || s.vendorId}</td>
                    <td>{s.planName} · {s.interval}</td>
                    <td>{s.status}</td>
                    <td>{s.currentPeriodEnd ? new Date(s.currentPeriodEnd).toLocaleDateString('en-GB') : '—'}</td>
                    <td>{s.paymentMethod ? `${s.paymentMethod.brand} •••• ${s.paymentMethod.last4}` : 'None'}</td>
                    <td className="actions">
                      <button className="btn btn-outline" type="button" onClick={async () => { await recordBillingEvent({ vendor: v, success: true, actor: profile }); toast.show('Charge recorded'); load(); }}>Paid</button>
                      <button className="btn btn-danger" type="button" onClick={async () => { await recordBillingEvent({ vendor: v, success: false, actor: profile }); toast.show('Failure + 3-day grace'); load(); }}>Fail payment</button>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </div>

      <div className="panel" style={{ marginTop: 20 }}>
        <h3>Plan limits</h3>
        {plans.map((p) => (
          <form key={p.id} className="toolbar" onSubmit={async (e) => {
            e.preventDefault();
            const data = new FormData(e.currentTarget);
            await savePlan({
              ...p,
              listingCap: Number(data.get('cap')),
              monthlyPrice: Number(data.get('month')),
              yearlyPrice: Number(data.get('year')),
            }, profile);
            toast.show(`${p.name} updated.`);
            load();
          }}>
            <strong style={{ minWidth: 90 }}>{p.name}</strong>
            <input className="field" name="cap" type="number" defaultValue={p.listingCap} />
            <input className="field" name="month" type="number" defaultValue={p.monthlyPrice} />
            <input className="field" name="year" type="number" defaultValue={p.yearlyPrice} />
            <button className="btn btn-outline" type="submit">Save</button>
          </form>
        ))}
      </div>
    </div>
  );
}
