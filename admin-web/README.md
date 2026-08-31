# Mazonn Super Admin (React)

Web dashboard for Super Admin only. It is not part of the customer or vendor apps.

## Run

```bash
cd admin-web
npm install
npm run dev
```

http://localhost:5173 — `admin@mazonn.app` / `admin123`

## This console can only

- Review vendor KYC, approve/reject stores, suspend, and set read-only
- Moderate products before they appear in the shop
- Create global categories, sub-categories, and brands
- Manage Basic / Standard / Premium subscriptions, proration, tokenized cards, and 3-day billing grace
- View all orders, flag/escalate disputes, and store per-category commission % (Phase 3)
- Set business name and logo. Language is English, currency is PKR, dates are DD-MM-YYYY

## Deploy rules / billing job

```bash
firebase deploy --only firestore:rules,storage,functions
```
