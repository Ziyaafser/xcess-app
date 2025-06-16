require('dotenv').config();

const functions = require("firebase-functions");
const admin = require("firebase-admin");
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);

admin.initializeApp();

exports.createPaymentIntent = functions.https.onCall(async (data, context) => {
  const amount = data.amount;

  try {
    const paymentIntent = await stripe.paymentIntents.create({
      amount: amount,
      currency: "myr",
      automatic_payment_methods: { enabled: true },
    });

    return {
      clientSecret: paymentIntent.client_secret,
    };
  } catch (error) {
    console.error("Stripe Error:", error);
    return { error: error.message };
  }
});
