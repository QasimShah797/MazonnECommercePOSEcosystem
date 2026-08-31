import {
  addDoc,
  arrayUnion,
  collection,
  doc,
  getDoc,
  getDocs,
  limit,
  orderBy,
  query,
  serverTimestamp,
  setDoc,
  updateDoc,
  where,
  writeBatch,
} from 'firebase/firestore';
import { db } from './firebase.js';

export const STATUS = {
  pending: 'pending',
  approved: 'approved',
  rejected: 'rejected',
  suspended: 'suspended',
};

export function statusLabel(status) {
  return {
    pending: 'Pending approval',
    approved: 'Approved',
    rejected: 'Rejected',
    suspended: 'Suspended',
  }[status] || status || 'Unknown';
}

export function documentsStatus(vendor) {
  const docs = vendor.documents || [];
  if (!docs.length) return 'missing';
  if (docs.some((d) => d.status === 'rejected')) return 'rejected';
  if (docs.every((d) => d.status === 'verified')) return 'verified';
  return 'pending';
}

export function documentsLabel(status) {
  return { verified: 'Verified', rejected: 'Rejected', missing: 'Not uploaded', pending: 'Pending' }[status] || status;
}

export async function resolveDocumentUrl(docItem) {
  const url = docItem?.url || '';
  if (!url.startsWith('kyc:')) return url;
  const snap = await getDoc(doc(db, 'vendorKyc', url.slice(4)));
  const data = snap.data();
  if (!data?.base64) return '';
  return `data:${data.mime || 'image/jpeg'};base64,${data.base64}`;
}

export function formatDate(value) {
  if (!value) return '—';
  const date = typeof value.toDate === 'function' ? value.toDate() : new Date(value);
  if (Number.isNaN(date.getTime())) return '—';
  const dd = String(date.getDate()).padStart(2, '0');
  const mm = String(date.getMonth() + 1).padStart(2, '0');
  const yyyy = date.getFullYear();
  return `${dd}-${mm}-${yyyy}`;
}

export function money(value) {
  return new Intl.NumberFormat('en-PK', { style: 'currency', currency: 'PKR', maximumFractionDigits: 0 }).format(Number(value || 0));
}

async function mapCollection(ref) {
  const snap = await getDocs(ref);
  return snap.docs.map((item) => ({ id: item.id, ...item.data() }));
}

export async function fetchVendors() {
  return mapCollection(collection(db, 'vendors'));
}

export async function fetchVendor(id) {
  const snap = await getDoc(doc(db, 'vendors', id));
  if (!snap.exists()) return null;
  return { id: snap.id, ...snap.data() };
}

export async function fetchCustomers() {
  const users = await mapCollection(query(collection(db, 'users'), limit(400)));
  return users.filter((u) => u.role !== 'admin');
}

export async function fetchProducts() {
  return mapCollection(query(collection(db, 'products'), limit(400)));
}

export async function fetchOrders() {
  const orders = await mapCollection(query(collection(db, 'orders'), limit(400)));
  return orders.sort((a, b) => String(b.placedAt || '').localeCompare(String(a.placedAt || '')));
}

export async function fetchAuditLogs() {
  try {
    return mapCollection(query(collection(db, 'auditLogs'), orderBy('createdAt', 'desc'), limit(200)));
  } catch {
    const logs = await mapCollection(collection(db, 'auditLogs'));
    return logs.sort((a, b) => String(b.createdAt || '').localeCompare(String(a.createdAt || '')));
  }
}

export async function fetchSupportRequests() {
  const rows = await mapCollection(collection(db, 'supportRequests'));
  return rows.sort((a, b) => String(b.createdAt || '').localeCompare(String(a.createdAt || '')));
}

async function writeAudit({ action, actorId, actorName, targetId, detail }) {
  await addDoc(collection(db, 'auditLogs'), {
    action,
    actorId,
    actorName,
    targetId: targetId || null,
    detail: detail || '',
    createdAt: new Date().toISOString(),
    serverTime: serverTimestamp(),
  });
}

async function notifyVendor(vendorId, title, body) {
  await addDoc(collection(db, 'notifications'), {
    title,
    body,
    recipientId: vendorId,
    type: 'vendor_status',
    read: false,
    createdAt: new Date().toISOString(),
  });
}

async function stampVendorProducts(vendorId, status) {
  const products = await getDocs(query(collection(db, 'products'), where('vendorId', '==', vendorId)));
  if (products.empty) return;
  let batch = writeBatch(db);
  let count = 0;
  for (const item of products.docs) {
    batch.set(item.ref, { vendorApprovalStatus: status }, { merge: true });
    count += 1;
    if (count >= 400) {
      await batch.commit();
      batch = writeBatch(db);
      count = 0;
    }
  }
  if (count > 0) await batch.commit();
}

export async function setVendorStatus({ vendor, status, reason, actor }) {
  const now = new Date().toISOString();
  const action = status === 'approved' ? 'approved' : status === 'rejected' ? 'rejected' : status === 'suspended' ? 'suspended' : status;
  await setDoc(
    doc(db, 'vendors', vendor.id),
    {
      approvalStatus: status,
      rejectionReason: status === 'rejected' ? reason : '',
      suspensionReason: status === 'suspended' ? reason : '',
      reviewedAt: now,
      reviewedBy: actor.id,
      reviewedByName: actor.fullName || actor.email || 'Super Admin',
      history: arrayUnion({
        at: now,
        action,
        actorId: actor.id,
        actorName: actor.fullName || actor.email || 'Super Admin',
        detail: reason || '',
      }),
    },
    { merge: true },
  );
  await stampVendorProducts(vendor.id, status);

  const messages = {
    approved: ['You are approved to sell', 'Your vendor account has been approved. You can now publish products, receive orders, and access earnings on Mazonn.'],
    rejected: ['Application not approved', reason || 'Your submitted information could not be verified. Please update your documents and resubmit.'],
    suspended: ['Account suspended', reason || 'Your vendor account has been suspended. Selling is disabled until Super Admin reactivates it.'],
  };
  const [title, body] = messages[status] || ['Vendor status updated', `Your vendor status is now ${status}.`];
  await notifyVendor(vendor.id, title, body);
  await writeAudit({
    action: `Admin ${action} Vendor ${vendor.businessName || vendor.id}`,
    actorId: actor.id,
    actorName: actor.fullName || actor.email || 'Super Admin',
    targetId: vendor.id,
    detail: reason,
  });
}

export async function updateDocumentStatus({ vendor, documentId, status, note, actor }) {
  const documents = (vendor.documents || []).map((item) =>
    item.id === documentId ? { ...item, status, note: note || item.note || '' } : item,
  );
  await updateDoc(doc(db, 'vendors', vendor.id), { documents });
  await writeAudit({
    action: `Admin marked document ${status} for ${vendor.businessName || vendor.id}`,
    actorId: actor.id,
    actorName: actor.fullName || actor.email || 'Super Admin',
    targetId: vendor.id,
    detail: note,
  });
}

export async function setProductModeration({ product, status, reason, actor }) {
  await setDoc(
    doc(db, 'products', product.id),
    { moderation: status, rejectionReason: reason || '', isActive: status === 'approved' },
    { merge: true },
  );
  await writeAudit({
    action: `Admin ${status} product ${product.name || product.id}`,
    actorId: actor.id,
    actorName: actor.fullName || actor.email || 'Super Admin',
    targetId: product.id,
    detail: reason,
  });
}

export const DEFAULT_PLANS = [
  {
    id: 'basic',
    name: 'Basic',
    listingCap: 20,
    monthlyPrice: 1999,
    yearlyPrice: 19990,
    features: { analytics: false, promotions: false, ads: false, bulkPricing: true },
  },
  {
    id: 'standard',
    name: 'Standard',
    listingCap: 100,
    monthlyPrice: 4999,
    yearlyPrice: 49990,
    features: { analytics: true, promotions: true, ads: false, bulkPricing: true },
  },
  {
    id: 'premium',
    name: 'Premium',
    listingCap: 500,
    monthlyPrice: 9999,
    yearlyPrice: 99990,
    features: { analytics: true, promotions: true, ads: true, bulkPricing: true },
  },
];

export const DEFAULT_CATEGORIES = [
  { id: 'fashion', name: 'Fashion', subtitle: 'Tailored essentials', subcategories: ['outerwear', 'dresses', 'bottoms', 'knitwear', 'loungewear'] },
  { id: 'electronics', name: 'Electronics', subtitle: 'Considered tech', subcategories: ['headphones', 'televisions', 'smartphones', 'audio', 'desk'] },
  { id: 'beauty', name: 'Beauty', subtitle: 'Rituals & scent', subcategories: ['fragrance', 'skincare', 'home fragrance'] },
  { id: 'home', name: 'Home', subtitle: 'Living objects', subcategories: ['kitchen', 'bedding', 'lighting', 'refrigerators'] },
  { id: 'grocery', name: 'Grocery', subtitle: 'Pantry & produce', subcategories: ['grocery'] },
  { id: 'sports', name: 'Sports', subtitle: 'Move well', subcategories: ['tops', 'fitness', 'footwear'] },
  { id: 'accessories', name: 'Accessories', subtitle: 'Finishing notes', subcategories: ['earrings', 'bags', 'watches', 'scarves', 'hats'] },
];

export const DEFAULT_BRANDS = ['Atelier Noir', 'Samsung', 'LG', 'TCL', 'Apple', 'Mazonn'];

export async function ensurePlatformDefaults() {
  const settingsRef = doc(db, 'settings', 'system');
  const settingsSnap = await getDoc(settingsRef);
  if (!settingsSnap.exists()) {
    await setDoc(settingsRef, {
      language: 'en',
      currency: 'PKR',
      currencyLocked: true,
      businessName: 'Mazonn',
      logoUrl: '',
      dateFormat: 'DD-MM-YYYY',
    });
  }
  const plans = await getDocs(collection(db, 'subscriptionPlans'));
  if (plans.empty) {
    for (const plan of DEFAULT_PLANS) {
      await setDoc(doc(db, 'subscriptionPlans', plan.id), plan);
    }
  }
  const cats = await getDocs(collection(db, 'categories'));
  if (cats.empty) {
    for (const category of DEFAULT_CATEGORIES) {
      await setDoc(doc(db, 'categories', category.id), { ...category, commissionPercent: 10 });
    }
  }
  const brands = await getDocs(collection(db, 'brands'));
  if (brands.empty) {
    for (const name of DEFAULT_BRANDS) {
      const id = name.toLowerCase().replace(/\s+/g, '-');
      await setDoc(doc(db, 'brands', id), { name, status: 'active' });
    }
  }
}

export async function fetchSettings() {
  await ensurePlatformDefaults();
  const snap = await getDoc(doc(db, 'settings', 'system'));
  return { id: 'system', ...snap.data() };
}

export async function saveSettings(data, actor) {
  await setDoc(doc(db, 'settings', 'system'), { ...data, currency: 'PKR', language: 'en', dateFormat: 'DD-MM-YYYY' }, { merge: true });
  await writeAudit({ action: 'Admin updated system settings', actorId: actor.id, actorName: actor.fullName || actor.email, detail: 'PKR / English / DD-MM-YYYY' });
}

export async function fetchCategoriesAdmin() {
  await ensurePlatformDefaults();
  return mapCollection(collection(db, 'categories'));
}

export async function saveCategory(category, actor) {
  const id = category.id || category.name.toLowerCase().replace(/[^a-z0-9]+/g, '-');
  await setDoc(doc(db, 'categories', id), { ...category, id }, { merge: true });
  await writeAudit({ action: `Admin saved category ${category.name}`, actorId: actor.id, actorName: actor.fullName || actor.email, targetId: id });
}

export async function fetchBrands() {
  await ensurePlatformDefaults();
  return mapCollection(collection(db, 'brands'));
}

export async function saveBrand(brand, actor) {
  const id = brand.id || brand.name.toLowerCase().replace(/[^a-z0-9]+/g, '-');
  await setDoc(doc(db, 'brands', id), { name: brand.name, status: brand.status || 'active', id }, { merge: true });
  await writeAudit({ action: `Admin saved brand ${brand.name}`, actorId: actor.id, actorName: actor.fullName || actor.email, targetId: id });
}

export async function fetchPlans() {
  await ensurePlatformDefaults();
  const plans = await mapCollection(collection(db, 'subscriptionPlans'));
  return plans.sort((a, b) => Number(a.monthlyPrice || 0) - Number(b.monthlyPrice || 0));
}

export async function savePlan(plan, actor) {
  await setDoc(doc(db, 'subscriptionPlans', plan.id), plan, { merge: true });
  await writeAudit({ action: `Admin updated plan ${plan.name}`, actorId: actor.id, actorName: actor.fullName || actor.email, targetId: plan.id });
}

export async function fetchSubscriptions() {
  return mapCollection(collection(db, 'vendorSubscriptions'));
}

function periodEnd(interval) {
  const end = new Date();
  if (interval === 'yearly') end.setFullYear(end.getFullYear() + 1);
  else end.setMonth(end.getMonth() + 1);
  return end.toISOString();
}

export function prorateCharge({ currentPrice, newPrice, periodEndIso }) {
  const end = new Date(periodEndIso || Date.now());
  const remainingMs = Math.max(0, end.getTime() - Date.now());
  const remainingDays = remainingMs / (1000 * 60 * 60 * 24);
  const periodDays = remainingDays > 31 ? 365 : 30;
  const credit = (remainingDays / periodDays) * Number(currentPrice || 0);
  return Math.round(Number(newPrice || 0) - credit);
}

export async function assignVendorPlan({ vendor, plan, interval = 'monthly', actor }) {
  const subRef = doc(db, 'vendorSubscriptions', vendor.id);
  const existing = await getDoc(subRef);
  const current = existing.data() || {};
  const currentPlan = DEFAULT_PLANS.find((p) => p.id === (current.planId || vendor.planId)) || DEFAULT_PLANS[0];
  const newPrice = interval === 'yearly' ? plan.yearlyPrice : plan.monthlyPrice;
  const oldPrice = (current.interval || 'monthly') === 'yearly' ? currentPlan.yearlyPrice : currentPlan.monthlyPrice;
  const prorated = existing.exists() ? prorateCharge({ currentPrice: oldPrice, newPrice, periodEndIso: current.currentPeriodEnd }) : newPrice;
  const now = new Date().toISOString();
  await setDoc(subRef, {
    vendorId: vendor.id,
    storeName: vendor.businessName,
    planId: plan.id,
    planName: plan.name,
    interval,
    status: 'active',
    listingCap: plan.listingCap,
    currentPeriodEnd: periodEnd(interval),
    graceUntil: null,
    lastProration: prorated,
    updatedAt: now,
  }, { merge: true });
  await setDoc(doc(db, 'vendors', vendor.id), {
    planId: plan.id,
    listingCap: plan.listingCap,
    billingStatus: 'active',
  }, { merge: true });
  await writeAudit({
    action: `Admin assigned ${plan.name} (${interval}) to ${vendor.businessName || vendor.id}`,
    actorId: actor.id,
    actorName: actor.fullName || actor.email,
    targetId: vendor.id,
    detail: `Prorated charge ${prorated} PKR`,
  });
}

export async function tokenizePaymentMethod({ vendor, last4, brand, expMonth, expYear, actor }) {
  if (!/^\d{4}$/.test(String(last4 || ''))) throw new Error('Enter the last 4 digits only. Full card numbers are not stored.');
  const token = `pm_${vendor.id.slice(0, 8)}_${Date.now().toString(36)}`;
  await setDoc(doc(db, 'vendorSubscriptions', vendor.id), {
    vendorId: vendor.id,
    paymentMethod: {
      token,
      last4: String(last4),
      brand,
      expMonth: Number(expMonth),
      expYear: Number(expYear),
      tokenized: true,
      panStored: false,
      createdAt: new Date().toISOString(),
    },
  }, { merge: true });
  await writeAudit({
    action: `Admin tokenized card •••• ${last4} for ${vendor.businessName || vendor.id}`,
    actorId: actor.id,
    actorName: actor.fullName || actor.email,
    targetId: vendor.id,
  });
  return token;
}

export async function recordBillingEvent({ vendor, success, actor }) {
  const subRef = doc(db, 'vendorSubscriptions', vendor.id);
  const now = new Date();
  if (success) {
    const sub = (await getDoc(subRef)).data() || {};
    await setDoc(subRef, {
      status: 'active',
      graceUntil: null,
      lastChargeAt: now.toISOString(),
      currentPeriodEnd: periodEnd(sub.interval || 'monthly'),
    }, { merge: true });
    await setDoc(doc(db, 'vendors', vendor.id), { billingStatus: 'active' }, { merge: true });
    await notifyVendor(vendor.id, 'Subscription payment received', 'Your Mazonn subscription is active.');
  } else {
    const grace = new Date(now.getTime() + 3 * 24 * 60 * 60 * 1000);
    await setDoc(subRef, {
      status: 'past_due',
      graceUntil: grace.toISOString(),
      lastChargeAt: now.toISOString(),
      lastChargeFailed: true,
    }, { merge: true });
    await setDoc(doc(db, 'vendors', vendor.id), { billingStatus: 'grace' }, { merge: true });
    await notifyVendor(vendor.id, 'Payment failed', 'A 3-day grace period has started. Update your card to avoid a read-only store.');
  }
  await writeAudit({
    action: `Admin recorded ${success ? 'successful' : 'failed'} billing for ${vendor.businessName || vendor.id}`,
    actorId: actor.id,
    actorName: actor.fullName || actor.email,
    targetId: vendor.id,
  });
}

export async function setVendorReadOnly({ vendor, readOnly, actor }) {
  await setDoc(doc(db, 'vendors', vendor.id), { billingStatus: readOnly ? 'read_only' : 'active' }, { merge: true });
  await setDoc(doc(db, 'vendorSubscriptions', vendor.id), { status: readOnly ? 'read_only' : 'active' }, { merge: true });
  await notifyVendor(
    vendor.id,
    readOnly ? 'Account is read-only' : 'Selling restored',
    readOnly ? 'Your store is read-only until billing is resolved.' : 'Your vendor account is active again.',
  );
  await writeAudit({
    action: `Admin set ${vendor.businessName || vendor.id} ${readOnly ? 'read-only' : 'active'}`,
    actorId: actor.id,
    actorName: actor.fullName || actor.email,
    targetId: vendor.id,
  });
}

export async function flagOrderDispute({ order, status, note, actor }) {
  await setDoc(doc(db, 'orders', order.id), { disputeStatus: status, disputeNote: note || '' }, { merge: true });
  await writeAudit({
    action: `Admin ${status} dispute on order ${order.id}`,
    actorId: actor.id,
    actorName: actor.fullName || actor.email,
    targetId: order.id,
    detail: note,
  });
}

export async function saveCommission({ categoryId, percent, actor }) {
  await setDoc(doc(db, 'categories', categoryId), { commissionPercent: Number(percent) }, { merge: true });
  await writeAudit({
    action: `Admin set ${percent}% commission for ${categoryId}`,
    actorId: actor.id,
    actorName: actor.fullName || actor.email,
    targetId: categoryId,
    detail: 'Phase 3 backend config',
  });
}

