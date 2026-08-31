const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");
const crypto = require("crypto");

initializeApp();

exports.onNotificationCreated = onDocumentCreated("notifications/{id}", async (event) => {
  const data = event.data?.data();
  if (!data) return;
  const recipientId = data.recipientId;
  if (!recipientId) return;
  const tokensSnap = await getFirestore()
    .collection("deviceTokens")
    .where("userId", "==", recipientId)
    .get();
  const tokens = tokensSnap.docs.map((doc) => doc.get("token")).filter(Boolean);
  if (tokens.length === 0) return;
  await getMessaging().sendEachForMulticast({
    tokens,
    notification: {
      title: data.title || "Mazonn",
      body: data.body || "",
    },
    data: {
      type: String(data.type || "system"),
      orderId: String(data.orderId || ""),
    },
    android: { priority: "high", notification: { channelId: "mazonn_orders", sound: "default" } },
    apns: { payload: { aps: { sound: "default" } } },
  });
});

exports.tokenizePaymentMethod = onCall(async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Sign in required.");
  const { last4, brand, expMonth, expYear, pan, cvc, cardNumber } = request.data || {};
  if (pan || cvc || cardNumber) {
    throw new HttpsError("invalid-argument", "Full card numbers are not accepted. Send last4, brand, and expiry only.");
  }
  if (!/^\d{4}$/.test(String(last4 || ""))) {
    throw new HttpsError("invalid-argument", "last4 must be exactly 4 digits.");
  }
  const token = `pm_${crypto.randomBytes(12).toString("hex")}`;
  const vendorId = request.auth.uid;
  await getFirestore().collection("vendorSubscriptions").doc(vendorId).set({
    vendorId,
    paymentMethod: {
      token,
      last4: String(last4),
      brand: brand || "card",
      expMonth: Number(expMonth || 0),
      expYear: Number(expYear || 0),
      tokenized: true,
      panStored: false,
      createdAt: new Date().toISOString(),
    },
  }, { merge: true });
  return { token, last4: String(last4), brand: brand || "card" };
});

exports.processSubscriptionBilling = onSchedule("every 24 hours", async () => {
  const db = getFirestore();
  const now = new Date();
  const snap = await db.collection("vendorSubscriptions").get();
  for (const docSnap of snap.docs) {
    const sub = docSnap.data();
    const vendorRef = db.collection("vendors").doc(sub.vendorId || docSnap.id);
    if (sub.status === "past_due" && sub.graceUntil && new Date(sub.graceUntil) <= now) {
      await docSnap.ref.set({ status: "read_only" }, { merge: true });
      await vendorRef.set({ billingStatus: "read_only" }, { merge: true });
      await db.collection("notifications").add({
        title: "Account is read-only",
        body: "The 3-day grace period ended. Selling is paused until a subscription payment is received.",
        recipientId: sub.vendorId || docSnap.id,
        type: "vendor_status",
        read: false,
        createdAt: now.toISOString(),
      });
      continue;
    }
    if (sub.status !== "active" || !sub.currentPeriodEnd) continue;
    if (new Date(sub.currentPeriodEnd) > now) continue;
    const hasToken = Boolean(sub.paymentMethod?.token);
    if (hasToken) {
      const end = new Date(now);
      if (sub.interval === "yearly") end.setFullYear(end.getFullYear() + 1);
      else end.setMonth(end.getMonth() + 1);
      await docSnap.ref.set({
        lastChargeAt: now.toISOString(),
        lastChargeFailed: false,
        currentPeriodEnd: end.toISOString(),
        status: "active",
      }, { merge: true });
      await vendorRef.set({ billingStatus: "active" }, { merge: true });
    } else {
      const grace = new Date(now.getTime() + 3 * 24 * 60 * 60 * 1000);
      await docSnap.ref.set({
        status: "past_due",
        lastChargeFailed: true,
        graceUntil: grace.toISOString(),
      }, { merge: true });
      await vendorRef.set({ billingStatus: "grace" }, { merge: true });
      await db.collection("notifications").add({
        title: "Payment failed",
        body: "A 3-day grace period has started. Add a tokenized card to keep selling.",
        recipientId: sub.vendorId || docSnap.id,
        type: "vendor_status",
        read: false,
        createdAt: now.toISOString(),
      });
    }
  }
});
