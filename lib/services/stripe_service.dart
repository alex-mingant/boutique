import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter/material.dart';
import '../models/carte_bancaire.dart';

class StripeService {
  static void init() {
    Stripe.publishableKey = 'pk_test_51Oc89YEeMOw8l3rt4ANt0jt8pZKUMvgqxcTdNx6FlBaDBxD0JxNKzikyQYW2AUQhsPTsKJLdynTnk8qWZkASpBxg005sVYhwdT';
  }

  static FirebaseFunctions get _functions =>
      FirebaseFunctions.instanceFor(region: 'us-central1');

  // ── Apparence partagée ────────────────────────────────────────────────────

  static PaymentSheetAppearance get _appearance => PaymentSheetAppearance(
        colors: PaymentSheetAppearanceColors(
          primary: const Color(0xFF1E293B),
          background: const Color(0xFFF8FAFC),
          componentBackground: Colors.white,
          componentBorder: const Color(0xFFE2E8F0),
          componentDivider: const Color(0xFFE2E8F0),
          primaryText: const Color(0xFF1E293B),
          secondaryText: const Color(0xFF64748B),
          componentText: const Color(0xFF1E293B),
          placeholderText: const Color(0xFF94A3B8),
          icon: const Color(0xFF64748B),
        ),
        shapes: PaymentSheetShape(
          borderRadius: 12,
          borderWidth: 1.0,
          shadow: PaymentSheetShadowParams(
            color: Colors.black,
            opacity: 0.04,
            offset: PaymentSheetShadowOffset(x: 0, y: 2),
          ),
        ),
        primaryButton: PaymentSheetPrimaryButtonAppearance(
          shapes: PaymentSheetPrimaryButtonShape(blurRadius: 0),
          colors: PaymentSheetPrimaryButtonTheme(
            light: PaymentSheetPrimaryButtonThemeColors(
              background: const Color(0xFF1E293B),
              text: Colors.white,
              border: Colors.transparent,
            ),
          ),
        ),
      );

  // ── Paiement standard (flow existant) ────────────────────────────────────

  Future<bool> payerCommande(double montantEuros) async {
    try {
      final montantCentimes = (montantEuros * 100).round();
      final callable = _functions.httpsCallable('creerPaymentIntent');
      final resultat =
          await callable.call(<String, dynamic>{'montant': montantCentimes});
      final clientSecret = resultat.data['clientSecret'];

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Fruits & Légumes',
          style: ThemeMode.light,
          appearance: _appearance,
        ),
      );

      await Stripe.instance.presentPaymentSheet();
      return true;
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) return false;
      rethrow;
    }
  }

  // ── Gestion des clients Stripe ────────────────────────────────────────────

  /// Crée ou récupère le customer Stripe lié à l'utilisateur Firebase.
  Future<String> getOuCreerCustomer() async {
    final result =
        await _functions.httpsCallable('creerOuRecupererCustomer').call({});
    return result.data['customerId'] as String;
  }

  // ── Gestion des cartes enregistrées ──────────────────────────────────────

  /// Ouvre le sheet Stripe pour enregistrer une nouvelle carte.
  Future<void> ajouterCarte(String customerId) async {
    final result = await _functions
        .httpsCallable('creerSetupIntent')
        .call({'customerId': customerId});

    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        setupIntentClientSecret: result.data['setupIntentClientSecret'] as String,
        customerEphemeralKeySecret: result.data['ephemeralKeySecret'] as String,
        customerId: customerId,
        merchantDisplayName: 'Fruits & Légumes',
        style: ThemeMode.light,
        appearance: _appearance,
      ),
    );

    await Stripe.instance.presentPaymentSheet();
  }

  /// Liste les cartes enregistrées pour un customer.
  Future<List<CarteBancaire>> listerCartes(String customerId) async {
    final result = await _functions
        .httpsCallable('listerCartes')
        .call({'customerId': customerId});
    final list = result.data['cartes'] as List<dynamic>;
    return list
        .map((c) => CarteBancaire.fromJson(Map<String, dynamic>.from(c as Map)))
        .toList();
  }

  /// Supprime une carte enregistrée.
  Future<void> supprimerCarte(String paymentMethodId) async {
    await _functions
        .httpsCallable('supprimerCarte')
        .call({'paymentMethodId': paymentMethodId});
  }

  /// Paie avec une carte enregistrée (sans ouvrir le sheet Stripe).
  Future<bool> payerAvecCarte(
      double montantEuros, String customerId, String paymentMethodId) async {
    try {
      final montantCentimes = (montantEuros * 100).round();
      final result =
          await _functions.httpsCallable('payerAvecCarte').call({
        'montant': montantCentimes,
        'customerId': customerId,
        'paymentMethodId': paymentMethodId,
      });

      final clientSecret = result.data['clientSecret'] as String;

      final paymentResult = await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: clientSecret,
        data: PaymentMethodParams.cardFromMethodId(
          paymentMethodData: PaymentMethodDataCardFromMethod(
            paymentMethodId: paymentMethodId,
          ),
        ),
      );

      return paymentResult.status == PaymentIntentsStatus.Succeeded;
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) return false;
      rethrow;
    }
  }
}
