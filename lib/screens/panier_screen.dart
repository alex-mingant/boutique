import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/panier_provider.dart';
import '../models/produit.dart';
import '../models/carte_bancaire.dart';
import '../services/commande_service.dart';
import '../services/stripe_service.dart';
import '../services/promo_service.dart';
import '../models/code_promo.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/adresse.dart';
import '../services/profil_service.dart';
import '../theme/app_colors.dart';

class PanierScreen extends StatefulWidget {
  const PanierScreen({super.key});

  @override
  State<PanierScreen> createState() => _PanierScreenState();
}

class _PanierScreenState extends State<PanierScreen> {
  final _promoController = TextEditingController();
  final _promoService = PromoService();
  final _stripeService = StripeService();
  bool _chargementPromo = false;
  bool _afficherSaisieManuelle = false;
  String _modeLivraison = 'retrait';
  Adresse? _adresseLivraison;
  final _profilService = ProfilService();

  // Cartes enregistrées
  String? _stripeCustomerId;
  List<CarteBancaire> _cartesSauvegardees = [];
  CarteBancaire? _carteSelectionnee;
  bool _cartesChargees = false;

  // Sections collapsibles
  bool _promoExpanded = false;
  bool _livraisonExpanded = true;
  bool _paiementExpanded = false;

  @override
  void initState() {
    super.initState();
    _chargerCartes();
  }

  Future<void> _chargerCartes() async {
    try {
      final customerId = await _stripeService.getOuCreerCustomer();
      final cartes = await _stripeService.listerCartes(customerId);
      if (mounted) {
        setState(() {
          _stripeCustomerId = customerId;
          _cartesSauvegardees = cartes;
          _cartesChargees = true;
          if (cartes.isNotEmpty) _paiementExpanded = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _cartesChargees = true);
    }
  }

  double _fraisLivraison(double sousTotal) {
    if (_modeLivraison != 'livraison') return 0;
    return sousTotal >= 30 ? 0 : 8;
  }

  Widget _buildSectionCard({
    required BuildContext context,
    required IconData icone,
    required String titre,
    required bool expanded,
    required VoidCallback onToggle,
    required Widget content,
    String? badge,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: context.containerBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icone, color: context.textPrimary, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      titre,
                      style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (badge != null)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          color: Color(0xFF2563EB),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.keyboard_arrow_down,
                        color: context.chevronColor, size: 22),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: content,
            ),
            crossFadeState: expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _tuileMode(String mode, String emoji, String titre, String sousTitre) {
    final selected = _modeLivraison == mode;
    return GestureDetector(
      onTap: () => setState(() {
        _modeLivraison = mode;
        if (mode == 'retrait') _adresseLivraison = null;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1E293B) : context.scaffoldBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFF1E293B) : context.borderColor,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    titre,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : context.textPrimary,
                    ),
                  ),
                ),
                if (selected)
                  const Icon(Icons.check_circle, color: Colors.white, size: 15),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              sousTitre,
              style: TextStyle(
                fontSize: 12,
                color: selected
                    ? Colors.white.withValues(alpha: 0.7)
                    : context.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tuileAdresse(Adresse adresse) {
    final selected = _adresseLivraison?.id == adresse.id;
    return GestureDetector(
      onTap: () => setState(() => _adresseLivraison = adresse),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEFF6FF) : context.scaffoldBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFF2563EB) : context.borderColor,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              adresse.label == 'Maison'
                  ? Icons.home_outlined
                  : adresse.label == 'Travail'
                      ? Icons.work_outline
                      : Icons.location_on_outlined,
              size: 18,
              color: selected ? const Color(0xFF2563EB) : context.textHint,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    adresse.label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: selected
                          ? const Color(0xFF2563EB)
                          : context.textPrimary,
                    ),
                  ),
                  Text(
                    "${adresse.adresse}, ${adresse.codePostal} ${adresse.ville}",
                    style: TextStyle(fontSize: 12, color: context.textHint),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle,
                  color: Color(0xFF2563EB), size: 16),
          ],
        ),
      ),
    );
  }

  Widget _tuileCartePaiement(
    BuildContext context, {
    required IconData icone,
    required String titre,
    required String sousTitre,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEFF6FF) : context.scaffoldBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFF2563EB) : context.borderColor,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icone,
                size: 18,
                color:
                    selected ? const Color(0xFF2563EB) : context.textHint),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titre,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: selected
                            ? const Color(0xFF2563EB)
                            : context.textPrimary,
                      )),
                  Text(sousTitre,
                      style:
                          TextStyle(fontSize: 11, color: context.textHint)),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle,
                  color: Color(0xFF2563EB), size: 16),
          ],
        ),
      ),
    );
  }

  void _afficherFormulaireAdresse(BuildContext context) {
    final adresseCtrl = TextEditingController();
    final villeCtrl = TextEditingController();
    final cpCtrl = TextEditingController();
    String labelSelectionne = 'Maison';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Ajouter une adresse",
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                children: ['Maison', 'Travail', 'Autre'].map((label) {
                  final sel = labelSelectionne == label;
                  return GestureDetector(
                    onTap: () => setModal(() => labelSelectionne = label),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel
                            ? const Color(0xFF2563EB)
                            : ctx.containerBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(label,
                          style: TextStyle(
                              color: sel ? Colors.white : ctx.textSecondary,
                              fontWeight: FontWeight.w600)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: adresseCtrl,
                decoration: InputDecoration(
                  labelText: "Adresse",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: cpCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Code postal",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: villeCtrl,
                      decoration: InputDecoration(
                        labelText: "Ville",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final nouvelleAdresse = Adresse(
                      id: '',
                      label: labelSelectionne,
                      adresse: adresseCtrl.text.trim(),
                      ville: villeCtrl.text.trim(),
                      codePostal: cpCtrl.text.trim(),
                    );
                    await _profilService.ajouterAdresse(nouvelleAdresse);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text("Ajouter"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _appliquerCodeSaisi(PanierProvider panier) async {
    final code = _promoController.text.trim();
    if (code.isEmpty) return;

    setState(() => _chargementPromo = true);
    try {
      final codePromo = await _promoService.validerEtAjouter(code);
      if (codePromo.minAchat > panier.total) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Row(children: [
              const Icon(Icons.info_outline, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(
                      'Minimum d\'achat : ${codePromo.minAchat.toStringAsFixed(2)} €')),
            ]),
            backgroundColor:
                const Color(0xFFD97706).withValues(alpha: 0.90),
          ));
        }
        return;
      }
      panier.appliquerCodePromo(codePromo);
      _promoController.clear();
      setState(() => _afficherSaisieManuelle = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
                child: Text(e
                    .toString()
                    .replaceFirst('Exception: ', ''))),
          ]),
          backgroundColor:
              const Color(0xFFDC2626).withValues(alpha: 0.90),
        ));
      }
    } finally {
      if (mounted) setState(() => _chargementPromo = false);
    }
  }

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  Map<String, ({Produit produit, int quantite})> _grouper(
      List<Produit> articles) {
    final map = <String, ({Produit produit, int quantite})>{};
    for (final p in articles) {
      if (map.containsKey(p.id)) {
        map[p.id] = (produit: p, quantite: map[p.id]!.quantite + 1);
      } else {
        map[p.id] = (produit: p, quantite: 1);
      }
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.cardBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textPrimary),
          onPressed: () => context.go('/'),
        ),
        title: Text(
          "Mon panier",
          style: TextStyle(
            color: context.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Consumer<PanierProvider>(
        builder: (context, panier, _) {
          // ── Panier vide ──────────────────────────────────────────────────
          if (panier.articles.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: context.containerBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.shopping_cart_outlined,
                        size: 48, color: context.textHint),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Votre panier est vide",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Ajoutez des produits pour commencer",
                    style:
                        TextStyle(color: context.textHint, fontSize: 14),
                  ),
                  const SizedBox(height: 32),
                  GestureDetector(
                    onTap: () => context.go('/'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text(
                        "Continuer mes achats",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          final groupes = _grouper(panier.articles);
          final remise = panier.total - panier.totalApresRemise;
          final totalFinal = panier.totalApresRemise +
              _fraisLivraison(panier.totalApresRemise);

          // ── Panier avec articles ─────────────────────────────────────────
          return Stack(
            children: [
              ListView(
                padding: EdgeInsets.fromLTRB(
                    16, 16, 16, bottomPadding + 120),
                children: [
                  // ── Section : Articles ────────────────────────────────
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: context.cardBg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: context.borderColor),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: context.containerBg,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.shopping_bag_outlined,
                                    color: context.textPrimary, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  "Articles",
                                  style: TextStyle(
                                    color: context.textPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E293B)
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  "${panier.articles.length} article${panier.articles.length > 1 ? 's' : ''}",
                                  style: TextStyle(
                                    color: context.textPrimary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Divider(
                            height: 1, color: context.dividerColor),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                          child: Column(
                            children: groupes.values
                                .map((entry) => _ArticleCard(
                                      produit: entry.produit,
                                      quantite: entry.quantite,
                                      onAjouter: () =>
                                          panier.ajouterProduit(entry.produit),
                                      onRetirer: () =>
                                          panier.supprimerProduit(
                                              entry.produit),
                                      onSupprimer: () {
                                        for (int i = 0;
                                            i < entry.quantite;
                                            i++) {
                                          panier.supprimerProduit(
                                              entry.produit);
                                        }
                                      },
                                    ))
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Section : Code promo ──────────────────────────────
                  _buildSectionCard(
                    context: context,
                    icone: Icons.local_offer_outlined,
                    titre: "Code promo",
                    expanded: _promoExpanded,
                    onToggle: () =>
                        setState(() => _promoExpanded = !_promoExpanded),
                    badge: panier.codePromoApplique?.code,
                    content: panier.codePromoApplique != null
                        ? _CodePromoApplique(
                            code: panier.codePromoApplique!,
                            onRetirer: panier.retirerCodePromo,
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              StreamBuilder<List<CodePromo>>(
                                stream: _promoService.getMesCodes(),
                                builder: (context, snapshot) {
                                  final codes = snapshot.data ?? [];
                                  if (codes.isEmpty) {
                                    return _BoutonSaisieManuelle(
                                      afficher: _afficherSaisieManuelle,
                                      onToggle: () => setState(() =>
                                          _afficherSaisieManuelle =
                                              !_afficherSaisieManuelle),
                                    );
                                  }
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      DropdownButtonFormField<CodePromo>(
                                        decoration: InputDecoration(
                                          hintText: 'Sélectionner un code',
                                          prefixIcon: const Icon(
                                              Icons.local_offer_outlined,
                                              size: 18),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 10),
                                          filled: true,
                                          fillColor: context.inputFill,
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            borderSide: BorderSide(
                                                color: context.borderColor),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            borderSide: BorderSide(
                                                color: context.borderColor),
                                          ),
                                        ),
                                        items: codes
                                            .map((c) => DropdownMenuItem(
                                                  value: c,
                                                  child: Text(
                                                      '${c.code}  •  ${c.libelle}'),
                                                ))
                                            .toList(),
                                        onChanged: (c) {
                                          if (c == null) return;
                                          if (c.minAchat > panier.total) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(SnackBar(
                                              content: Row(children: [
                                                const Icon(
                                                    Icons.info_outline,
                                                    color: Colors.white,
                                                    size: 18),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                    child: Text(
                                                        'Minimum d\'achat : ${c.minAchat.toStringAsFixed(2)} €')),
                                              ]),
                                              backgroundColor: const Color(
                                                      0xFFD97706)
                                                  .withValues(alpha: 0.90),
                                            ));
                                            return;
                                          }
                                          panier.appliquerCodePromo(c);
                                        },
                                      ),
                                      TextButton.icon(
                                        onPressed: () => setState(() =>
                                            _afficherSaisieManuelle =
                                                !_afficherSaisieManuelle),
                                        icon:
                                            const Icon(Icons.add, size: 14),
                                        label:
                                            const Text('Entrer un autre code'),
                                        style: TextButton.styleFrom(
                                          foregroundColor:
                                              const Color(0xFF2563EB),
                                          padding: EdgeInsets.zero,
                                          textStyle: const TextStyle(
                                              fontSize: 13),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              if (_afficherSaisieManuelle)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _promoController,
                                          textCapitalization:
                                              TextCapitalization.characters,
                                          style: const TextStyle(fontSize: 14),
                                          decoration: InputDecoration(
                                            hintText: 'Code promo',
                                            filled: true,
                                            fillColor: context.inputFill,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 14,
                                                    vertical: 12),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                  color: context.borderColor),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                  color: context.borderColor),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      GestureDetector(
                                        onTap: _chargementPromo
                                            ? null
                                            : () =>
                                                _appliquerCodeSaisi(panier),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 18, vertical: 13),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF1E293B),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: _chargementPromo
                                              ? const SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: Colors.white,
                                                  ),
                                                )
                                              : const Text("Appliquer",
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 13)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                  ),

                  // ── Section : Livraison ───────────────────────────────
                  _buildSectionCard(
                    context: context,
                    icone: Icons.local_shipping_outlined,
                    titre: "Livraison",
                    expanded: _livraisonExpanded,
                    onToggle: () => setState(
                        () => _livraisonExpanded = !_livraisonExpanded),
                    badge: _modeLivraison == 'retrait' ? 'Retrait' : 'Livraison',
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _tuileMode(
                                  'retrait', '🏪', 'Retrait', 'Gratuit'),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _tuileMode(
                                'livraison',
                                '🚚',
                                'Livraison',
                                panier.totalApresRemise >= 30
                                    ? 'Offerte'
                                    : '8,00 €',
                              ),
                            ),
                          ],
                        ),
                        if (_modeLivraison == 'livraison') ...[
                          const SizedBox(height: 14),
                          Text(
                            "Adresse de livraison",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: context.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          StreamBuilder<List<Adresse>>(
                            stream: _profilService.getAdresses(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF2563EB)),
                                  ),
                                );
                              }
                              final adresses = snapshot.data ?? [];
                              return Column(
                                children: [
                                  ...adresses.map((a) => _tuileAdresse(a)),
                                  GestureDetector(
                                    onTap: () =>
                                        _afficherFormulaireAdresse(context),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12, horizontal: 14),
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        border: Border.all(
                                            color: context.borderColor),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: context.containerBg,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Icon(Icons.add,
                                                size: 16,
                                                color:
                                                    context.textSecondary),
                                          ),
                                          const SizedBox(width: 10),
                                          const Text(
                                            "Ajouter une adresse",
                                            style: TextStyle(
                                              color: Color(0xFF2563EB),
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),

                  // ── Section : Moyen de paiement ───────────────────────
                  if (_cartesChargees && _cartesSauvegardees.isNotEmpty)
                    _buildSectionCard(
                      context: context,
                      icone: Icons.credit_card_outlined,
                      titre: "Moyen de paiement",
                      expanded: _paiementExpanded,
                      onToggle: () => setState(
                          () => _paiementExpanded = !_paiementExpanded),
                      badge: _carteSelectionnee != null
                          ? '••••  ${_carteSelectionnee!.last4}'
                          : 'Nouvelle carte',
                      content: Column(
                        children: [
                          _tuileCartePaiement(
                            context,
                            icone: Icons.credit_card_outlined,
                            titre: "Nouvelle carte",
                            sousTitre: "Payer via Stripe",
                            selected: _carteSelectionnee == null,
                            onTap: () =>
                                setState(() => _carteSelectionnee = null),
                          ),
                          const SizedBox(height: 6),
                          ..._cartesSauvegardees.map((carte) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: _tuileCartePaiement(
                                  context,
                                  icone: Icons.credit_card,
                                  titre:
                                      '${carte.brandLabel}  ••••  ${carte.last4}',
                                  sousTitre: 'Expire ${carte.expiry}',
                                  selected:
                                      _carteSelectionnee?.id == carte.id,
                                  onTap: () => setState(
                                      () => _carteSelectionnee = carte),
                                ),
                              )),
                        ],
                      ),
                    ),

                  // ── Récapitulatif ─────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.cardBg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: context.borderColor),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: context.containerBg,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.receipt_long_outlined,
                                  color: context.textPrimary, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "Récapitulatif",
                              style: TextStyle(
                                color: context.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Divider(height: 1, color: context.dividerColor),
                        const SizedBox(height: 14),
                        if (panier.codePromoApplique != null) ...[
                          _lignePrix(
                              "Sous-total",
                              "${panier.total.toStringAsFixed(2)} €",
                              barre: true),
                          const SizedBox(height: 8),
                          _lignePrix(
                            "Remise (${panier.codePromoApplique!.libelle})",
                            "-${remise.toStringAsFixed(2)} €",
                            couleur: Colors.green,
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (_modeLivraison == 'livraison') ...[
                          _lignePrix(
                            "Livraison",
                            panier.totalApresRemise >= 30
                                ? "Offerte"
                                : "+8,00 €",
                            couleur: panier.totalApresRemise >= 30
                                ? Colors.green
                                : null,
                          ),
                          const SizedBox(height: 8),
                        ],
                        _lignePrix(
                          "Total",
                          "${totalFinal.toStringAsFixed(2)} €",
                          gras: true,
                          taille: 18,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // ── Barre basse fixe : bouton commander ──────────────────
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.fromLTRB(
                      16, 12, 16, bottomPadding > 0 ? bottomPadding : 16),
                  decoration: BoxDecoration(
                    color: context.cardBg,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.07),
                        blurRadius: 16,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: GestureDetector(
                    onTap: () async {
                      final stripeService = StripeService();
                      final user = FirebaseAuth.instance.currentUser;
                      if (user == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(children: const [
                              Icon(Icons.lock_outline,
                                  color: Colors.white, size: 18),
                              SizedBox(width: 10),
                              Expanded(
                                  child:
                                      Text("Vous devez être connecté !")),
                            ]),
                          ),
                        );
                        return;
                      }

                      if (_modeLivraison == 'livraison' &&
                          _adresseLivraison == null) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(
                          content: Row(children: const [
                            Icon(Icons.location_off,
                                color: Colors.white, size: 18),
                            SizedBox(width: 10),
                            Expanded(
                                child: Text(
                                    "Sélectionnez une adresse de livraison")),
                          ]),
                          backgroundColor: const Color(0xFFD97706)
                              .withValues(alpha: 0.90),
                        ));
                        return;
                      }

                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => const Center(
                            child: CircularProgressIndicator(
                                color: Color(0xFF1E293B))),
                      );

                      try {
                        final bool ok;
                        if (_carteSelectionnee != null &&
                            _stripeCustomerId != null) {
                          ok = await _stripeService.payerAvecCarte(
                            totalFinal,
                            _stripeCustomerId!,
                            _carteSelectionnee!.id,
                          );
                        } else {
                          ok = await stripeService
                              .payerCommande(totalFinal);
                        }
                        if (context.mounted) Navigator.pop(context);
                        if (ok) {
                          await CommandeService().passerCommande(
                              panier.articles,
                              totalFinal,
                              _modeLivraison,
                              _adresseLivraison);
                          panier.viderPanier();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(children: const [
                                  Icon(Icons.check_circle_outline,
                                      color: Colors.white, size: 18),
                                  SizedBox(width: 10),
                                  Expanded(
                                      child: Text(
                                          "Paiement réussi ! Commande confirmée")),
                                ]),
                                backgroundColor: const Color(0xFF16A34A)
                                    .withValues(alpha: 0.90),
                              ),
                            );
                            context.go('/');
                          }
                        }
                      } catch (e) {
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(children: [
                                const Icon(Icons.error_outline,
                                    color: Colors.white, size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                    child: Text("Erreur de paiement : $e")),
                              ]),
                              backgroundColor: const Color(0xFFDC2626)
                                  .withValues(alpha: 0.90),
                            ),
                          );
                        }
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Commander  •  ${totalFinal.toStringAsFixed(2)} €",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Icon(Icons.arrow_forward,
                              color: Colors.white, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _lignePrix(String label, String valeur,
      {bool barre = false,
      Color? couleur,
      bool gras = false,
      double taille = 14}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
              fontSize: taille,
              color: couleur ?? context.textSecondary,
              fontWeight: gras ? FontWeight.bold : FontWeight.normal,
            )),
        Text(valeur,
            style: TextStyle(
              fontSize: taille,
              color: couleur ?? context.textPrimary,
              fontWeight: gras ? FontWeight.bold : FontWeight.w500,
              decoration: barre ? TextDecoration.lineThrough : null,
              decorationColor: context.textHint,
            )),
      ],
    );
  }
}

// ── Carte article ─────────────────────────────────────────────────────────────

class _ArticleCard extends StatelessWidget {
  final Produit produit;
  final int quantite;
  final VoidCallback onAjouter;
  final VoidCallback onRetirer;
  final VoidCallback onSupprimer;

  const _ArticleCard({
    required this.produit,
    required this.quantite,
    required this.onAjouter,
    required this.onRetirer,
    required this.onSupprimer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.scaffoldBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              produit.imageUrl,
              width: 66,
              height: 66,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => Container(
                width: 66,
                height: 66,
                color: context.containerBg,
                child: Icon(Icons.image_not_supported,
                    color: context.chevronColor, size: 26),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        produit.nom,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: context.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: onSupprimer,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: const Icon(Icons.delete_outline,
                            color: Color(0xFFDC2626), size: 15),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  "${produit.prix.toStringAsFixed(2)} € / ${produit.unite}",
                  style: TextStyle(color: context.textHint, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _boutonQte(
                      context: context,
                      icon: Icons.remove,
                      onTap: onRetirer,
                      actif: quantite > 1,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        "$quantite",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: context.textPrimary,
                        ),
                      ),
                    ),
                    _boutonQte(
                        context: context,
                        icon: Icons.add,
                        onTap: onAjouter,
                        filled: true),
                    const Spacer(),
                    Text(
                      "${(produit.prix * quantite).toStringAsFixed(2)} €",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: context.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _boutonQte(
      {required BuildContext context,
      required IconData icon,
      required VoidCallback onTap,
      bool actif = true,
      bool filled = false}) {
    return GestureDetector(
      onTap: actif ? onTap : null,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: filled
              ? const Color(0xFF1E293B)
              : actif
                  ? context.containerBg
                  : context.borderColor,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Icon(
          icon,
          size: 14,
          color: filled
              ? Colors.white
              : actif
                  ? context.textPrimary
                  : context.textHint,
        ),
      ),
    );
  }
}

// ── Code promo appliqué ───────────────────────────────────────────────────────

class _CodePromoApplique extends StatelessWidget {
  final CodePromo code;
  final VoidCallback onRetirer;

  const _CodePromoApplique({required this.code, required this.onRetirer});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF86EFAC)),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_offer, color: Color(0xFF16A34A), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${code.code}  •  ${code.libelle}',
              style: const TextStyle(
                color: Color(0xFF16A34A),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          GestureDetector(
            onTap: onRetirer,
            child: const Icon(Icons.close,
                color: Color(0xFF16A34A), size: 18),
          ),
        ],
      ),
    );
  }
}

// ── Bouton saisie manuelle ────────────────────────────────────────────────────

class _BoutonSaisieManuelle extends StatelessWidget {
  final bool afficher;
  final VoidCallback onToggle;

  const _BoutonSaisieManuelle(
      {required this.afficher, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: context.containerBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              afficher ? Icons.close : Icons.local_offer_outlined,
              size: 14,
              color: context.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Ajouter un code promo',
            style: TextStyle(
              color: Color(0xFF2563EB),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
