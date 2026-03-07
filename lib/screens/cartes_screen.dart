import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../models/carte_bancaire.dart';
import '../services/stripe_service.dart';
import '../theme/app_colors.dart';

class CartesScreen extends StatefulWidget {
  const CartesScreen({super.key});

  @override
  State<CartesScreen> createState() => _CartesScreenState();
}

class _CartesScreenState extends State<CartesScreen> {
  final _stripeService = StripeService();
  String? _customerId;
  List<CarteBancaire> _cartes = [];
  bool _chargement = true;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    try {
      final customerId = await _stripeService.getOuCreerCustomer();
      final cartes = await _stripeService.listerCartes(customerId);
      if (mounted) {
        setState(() {
          _customerId = customerId;
          _cartes = cartes;
          _chargement = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _erreur = e.toString();
          _chargement = false;
        });
      }
    }
  }

  Future<void> _ajouterCarte() async {
    if (_customerId == null) return;
    try {
      await _stripeService.ajouterCarte(_customerId!);
      await _charger();
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) return;
      if (mounted) _afficherErreur('Erreur lors de l\'ajout de la carte');
    } catch (_) {
      if (mounted) _afficherErreur('Erreur lors de l\'ajout de la carte');
    }
  }

  Future<void> _supprimerCarte(CarteBancaire carte) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Supprimer la carte',
            style: TextStyle(color: ctx.textPrimary, fontWeight: FontWeight.bold)),
        content: Text(
          'Supprimer la carte ${carte.brandLabel} se terminant par ${carte.last4} ?',
          style: TextStyle(color: ctx.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Annuler',
                style: TextStyle(color: ctx.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirme != true) return;
    try {
      await _stripeService.supprimerCarte(carte.id);
      await _charger();
    } catch (_) {
      if (mounted) _afficherErreur('Erreur lors de la suppression');
    }
  }

  void _afficherErreur(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ]),
        backgroundColor: const Color(0xFFDC2626).withValues(alpha: 0.90),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.cardBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Mes cartes enregistrées',
          style: TextStyle(
            color: context.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _chargement
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2563EB)))
          : _erreur != null
              ? _buildErreur()
              : _buildContenu(),
    );
  }

  Widget _buildErreur() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: context.textHint),
            const SizedBox(height: 16),
            Text('Impossible de charger les cartes',
                style: TextStyle(
                    color: context.textPrimary, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_erreur!,
                style: TextStyle(color: context.textSecondary, fontSize: 13),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _charger,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContenu() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Infos sécurité
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(Icons.lock_outline, color: Color(0xFF2563EB), size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Vos cartes sont sécurisées et chiffrées par Stripe. Nous ne stockons jamais vos données bancaires.',
                  style: TextStyle(
                    color: const Color(0xFF1D4ED8),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Liste des cartes
        if (_cartes.isEmpty) ...[
          Center(
            child: Column(
              children: [
                const SizedBox(height: 20),
                Icon(Icons.credit_card_off_outlined,
                    size: 56, color: context.textHint),
                const SizedBox(height: 16),
                Text(
                  'Aucune carte enregistrée',
                  style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ajoutez une carte pour payer plus rapidement',
                  style:
                      TextStyle(color: context.textSecondary, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ] else ...[
          Text(
            '${_cartes.length} carte${_cartes.length > 1 ? 's' : ''} enregistrée${_cartes.length > 1 ? 's' : ''}',
            style: TextStyle(
                color: context.textHint,
                fontSize: 13,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          ..._cartes.map((carte) => _CarteTuile(
                carte: carte,
                onSupprimer: () => _supprimerCarte(carte),
              )),
        ],

        const SizedBox(height: 24),

        // Bouton ajouter
        GestureDetector(
          onTap: _ajouterCarte,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_card_outlined, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Text(
                  'Ajouter une carte',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Widget carte ──────────────────────────────────────────────────────────────

class _CarteTuile extends StatelessWidget {
  final CarteBancaire carte;
  final VoidCallback onSupprimer;

  const _CarteTuile({required this.carte, required this.onSupprimer});

  IconData get _icone => switch (carte.brand.toLowerCase()) {
        'visa' || 'mastercard' || 'amex' || 'discover' => Icons.credit_card,
        _ => Icons.credit_card_outlined,
      };

  Color get _couleurBrand => switch (carte.brand.toLowerCase()) {
        'visa' => const Color(0xFF1A1F71),
        'mastercard' => const Color(0xFFEB001B),
        'amex' => const Color(0xFF007BC1),
        _ => const Color(0xFF1E293B),
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _couleurBrand.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_icone, color: _couleurBrand, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  carte.brandLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '•••• •••• •••• ${carte.last4}  •  ${carte.expiry}',
                  style: TextStyle(color: context.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
            onPressed: onSupprimer,
          ),
        ],
      ),
    );
  }
}
