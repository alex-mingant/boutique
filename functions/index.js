const { onCall, HttpsError } = require("firebase-functions/v2/https");
const stripeLib = require("stripe");
const admin = require("firebase-admin");

admin.initializeApp();

const STRIPE_OPTS = { secrets: ["STRIPE_SECRET_KEY"] };
const getStripe = (req) => stripeLib(process.env.STRIPE_SECRET_KEY);

// ── Crée ou récupère le customer Stripe lié au compte Firebase ──────────────
exports.creerOuRecupererCustomer = onCall(STRIPE_OPTS, async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Non connecté");
  const stripe = getStripe();
  const uid = request.auth.uid;
  const email = request.auth.token.email;

  const userRef = admin.firestore().collection("users").doc(uid);
  const userDoc = await userRef.get();
  if (userDoc.exists && userDoc.data().stripeCustomerId) {
    return { customerId: userDoc.data().stripeCustomerId };
  }

  const customer = await stripe.customers.create({
    email,
    metadata: { firebaseUID: uid },
  });
  await userRef.set({ stripeCustomerId: customer.id }, { merge: true });
  return { customerId: customer.id };
});

// ── SetupIntent pour enregistrer une carte sans paiement ─────────────────────
exports.creerSetupIntent = onCall(STRIPE_OPTS, async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Non connecté");
  const stripe = getStripe();
  const { customerId } = request.data;

  const ephemeralKey = await stripe.ephemeralKeys.create(
    { customer: customerId },
    { apiVersion: "2023-10-16" }
  );
  const setupIntent = await stripe.setupIntents.create({
    customer: customerId,
    payment_method_types: ["card"],
  });

  return {
    setupIntentClientSecret: setupIntent.client_secret,
    ephemeralKeySecret: ephemeralKey.secret,
  };
});

// ── Liste les cartes enregistrées d'un customer ──────────────────────────────
exports.listerCartes = onCall(STRIPE_OPTS, async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Non connecté");
  const stripe = getStripe();
  const { customerId } = request.data;

  const paymentMethods = await stripe.paymentMethods.list({
    customer: customerId,
    type: "card",
  });

  return {
    cartes: paymentMethods.data.map((pm) => ({
      id: pm.id,
      last4: pm.card.last4,
      brand: pm.card.brand,
      expMonth: pm.card.exp_month,
      expYear: pm.card.exp_year,
    })),
  };
});

// ── Supprime une carte enregistrée ───────────────────────────────────────────
exports.supprimerCarte = onCall(STRIPE_OPTS, async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Non connecté");
  const stripe = getStripe();
  await stripe.paymentMethods.detach(request.data.paymentMethodId);
  return { success: true };
});

// ── Paiement avec une carte enregistrée ─────────────────────────────────────
exports.payerAvecCarte = onCall(STRIPE_OPTS, async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Non connecté");
  const stripe = getStripe();
  const { montant, customerId, paymentMethodId } = request.data;

  const paymentIntent = await stripe.paymentIntents.create({
    amount: montant,
    currency: "eur",
    customer: customerId,
    payment_method: paymentMethodId,
    automatic_payment_methods: { enabled: true, allow_redirects: "never" },
  });

  return { clientSecret: paymentIntent.client_secret };
});

// ── Paiement standard ────────────────────────────────────────────────────────
exports.creerPaymentIntent = onCall(
  { secrets: ["STRIPE_SECRET_KEY"] },
  async (request) => {
  const stripe = stripeLib(process.env.STRIPE_SECRET_KEY);
  const data = request.data;

  console.log("Data reçue:", JSON.stringify(data));

  let montant = Number(data.montant);
  console.log("Montant converti:", montant);

  if (!montant || montant <= 0 || isNaN(montant)) {
    console.error("Montant invalide:", montant);
    throw new HttpsError("invalid-argument", `Montant invalide: ${montant}`);
  }

  try {
    const paymentIntent = await stripe.paymentIntents.create({
      amount: montant,
      currency: "eur",
      automatic_payment_methods: { enabled: true },
    });

    return { clientSecret: paymentIntent.client_secret };

  } catch (error) {
    console.error("Erreur Stripe:", error.message);
    throw new HttpsError("internal", error.message);
  }
});
