import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/produit.dart';
import '../providers/panier_provider.dart';
import '../services/favoris_service.dart';
import '../theme/app_colors.dart';

class DetailScreen extends StatefulWidget {
  final Produit produit;
  const DetailScreen({super.key, required this.produit});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  int _quantite = 1;
  int _tabIndex = 0; // 0 = Aperçu, 1 = Infos

  String _drapeau(String provenance) {
    switch (provenance.toLowerCase()) {
       case 'france': return '🇫🇷';
  case 'maroc': return '🇲🇦';
  case 'bresil': return '🇧🇷';
  case 'espagne': return '🇪🇸';
  case 'italie': return '🇮🇹';
  case 'allemagne': return '🇩🇪';
  case 'portugal': return '🇵🇹';
  case 'royaume uni': return '🇬🇧';
  case 'irlande': return '🇮🇪';
  case 'belgique': return '🇧🇪';
  case 'pays bas': return '🇳🇱';
  case 'suisse': return '🇨🇭';
  case 'autriche': return '🇦🇹';
  case 'suede': return '🇸🇪';
  case 'norvege': return '🇳🇴';
  case 'danemark': return '🇩🇰';
  case 'finlande': return '🇫🇮';
  case 'pologne': return '🇵🇱';
  case 'grece': return '🇬🇷';
  case 'turquie': return '🇹🇷';
  case 'russie': return '🇷🇺';
  case 'ukraine': return '🇺🇦';
  case 'etats unis': return '🇺🇸';
  case 'canada': return '🇨🇦';
  case 'mexique': return '🇲🇽';
  case 'argentine': return '🇦🇷';
  case 'chili': return '🇨🇱';
  case 'colombie': return '🇨🇴';
  case 'perou': return '🇵🇪';
  case 'venezuela': return '🇻🇪';
  case 'chine': return '🇨🇳';
  case 'japon': return '🇯🇵';
  case 'coree du sud': return '🇰🇷';
  case 'inde': return '🇮🇳';
  case 'indonesie': return '🇮🇩';
  case 'thailande': return '🇹🇭';
  case 'vietnam': return '🇻🇳';
  case 'philippines': return '🇵🇭';
  case 'australie': return '🇦🇺';
  case 'nouvelle zelande': return '🇳🇿';
  case 'afrique du sud': return '🇿🇦';
  case 'algerie': return '🇩🇿';
  case 'tunisie': return '🇹🇳';
  case 'egypte': return '🇪🇬';
  case 'nigeria': return '🇳🇬';
  case 'senegal': return '🇸🇳';
  case 'cote d\'ivoire': return '🇨🇮';
  case 'cameroun': return '🇨🇲';
  case 'arabie saoudite': return '🇸🇦';
  case 'emirats arabes unis': return '🇦🇪';
  case 'qatar': return '🇶🇦';
  case 'israel': return '🇮🇱';
  default: return '🌍';
    }
  }

  @override
  Widget build(BuildContext context) {
    final produit = widget.produit;
    final totalPrix = produit.prix * _quantite;
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: context.scaffoldBg,
        body: Stack(
          children: [
            // ── Contenu scrollable ──────────────────────────────────────
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Image hero ────────────────────────────────────────
                  Stack(
                    children: [
                      // Photo
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(28),
                          bottomRight: Radius.circular(28),
                        ),
                        child: Image.network(
                          produit.imageUrl,
                          width: double.infinity,
                          height: 340,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stack) => Container(
                            height: 340,
                            color: context.containerBg,
                            child: Icon(Icons.image_not_supported,
                                color: context.chevronColor, size: 60),
                          ),
                        ),
                      ),

                      // Cadre glassmorphism bas
                      Positioned(
                        bottom: 16, left: 16, right: 16,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Nom + Prix
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          produit.nom,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          const Text(
                                            "Prix",
                                            style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: 12),
                                          ),
                                          Text(
                                            "${produit.prix.toStringAsFixed(2)} €",
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 26,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // Provenance
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on,
                                          color: Colors.white60, size: 14),
                                      const SizedBox(width: 4),
                                      Text(
                                        "${_drapeau(produit.provenance)}  ${produit.provenance}",
                                        style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Bouton retour
                      Positioned(
                        top: topPadding + 12,
                        left: 16,
                        child: _boutonCircle(
                          context: context,
                          icon: Icons.arrow_back_ios_new,
                          onTap: () => context.pop(),
                        ),
                      ),

                      // Bouton favori
                      Positioned(
                        top: topPadding + 12,
                        right: 16,
                        child: StreamBuilder<bool>(
                          stream: FavorisService().estFavori(produit.id),
                          builder: (context, snapshot) {
                            final estFavori = snapshot.data ?? false;
                            return _boutonCircle(
                              context: context,
                              icon: estFavori
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              onTap: () =>
                                  FavorisService().toggleFavori(produit),
                              iconColor: estFavori
                                  ? Colors.red
                                  : context.textPrimary,
                            );
                          },
                        ),
                      ),

                      // Badge BIO
                      if (produit.bio)
                        Positioned(
                          top: topPadding + 16,
                          left: 68,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.eco, color: Colors.white, size: 13),
                                SizedBox(width: 4),
                                Text("BIO",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    )),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),

                  // ── Contenu bas ───────────────────────────────────────
                  Padding(
                    padding: EdgeInsets.fromLTRB(20, 24, 20, bottomPadding + 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // Onglets
                        Row(
                          children: [
                            _onglet("Aperçu", 0),
                            const SizedBox(width: 28),
                            _onglet("Infos", 1),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Barre stats
                        Row(
                          children: [
                            _statItem(context, Icons.scale_outlined, produit.unite),
                            _statItem(
                              context,
                              Icons.eco_outlined,
                              produit.bio ? "Bio" : "Standard",
                            ),
                            if (produit.prixAuKg > 0)
                              _statItem(
                                context,
                                Icons.euro,
                                "${produit.prixAuKg.toStringAsFixed(2)}/kg",
                              ),
                          ],
                        ),
                        const SizedBox(height: 28),

                        // Contenu selon onglet
                        if (_tabIndex == 0) ...[
                          Text(
                            produit.description.isNotEmpty
                                ? produit.description
                                : "Aucune description disponible.",
                            style: TextStyle(
                              fontSize: 14,
                              color: context.textHint,
                              height: 1.75,
                            ),
                          ),
                        ] else ...[
                          _ligneInfo(context, "Provenance",
                              "${_drapeau(produit.provenance)}  ${produit.provenance}"),
                          const SizedBox(height: 10),
                          _ligneInfo(context, "Vendu par", produit.unite),
                          const SizedBox(height: 10),
                          if (produit.prixAuKg > 0) ...[
                            _ligneInfo(context, "Prix au kg",
                                "${produit.prixAuKg.toStringAsFixed(2)} €"),
                            const SizedBox(height: 10),
                          ],
                          _ligneInfo(context,
                              "Agriculture bio", produit.bio ? "Oui ✅" : "Non"),
                          const SizedBox(height: 10),
                          _ligneInfo(context, "Catégorie",
                              produit.categorie[0].toUpperCase() +
                                  produit.categorie.substring(1)),
                        ],

                        const SizedBox(height: 36),

                        // Sélecteur quantité
                        Row(
                          children: [
                            Text(
                              "Quantité",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: context.textPrimary,
                              ),
                            ),
                            const Spacer(),
                            _boutonQuantite(
                              context: context,
                              icon: Icons.remove,
                              onTap: _quantite > 1
                                  ? () => setState(() => _quantite--)
                                  : null,
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 18),
                              child: Text(
                                "$_quantite",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: context.textPrimary,
                                ),
                              ),
                            ),
                            _boutonQuantite(
                              context: context,
                              icon: Icons.add,
                              onTap: () => setState(() => _quantite++),
                              filled: true,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Barre du bas fixe ────────────────────────────────────────
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding: EdgeInsets.fromLTRB(
                    20, 16, 20, bottomPadding > 0 ? bottomPadding : 20),
                decoration: BoxDecoration(
                  color: context.cardBg,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Total
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Total",
                          style: TextStyle(
                              color: context.textHint, fontSize: 12),
                        ),
                        Text(
                          "${totalPrix.toStringAsFixed(2)} €",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: context.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),

                    // Bouton panier
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          final panier = Provider.of<PanierProvider>(
                              context,
                              listen: false);
                          for (int i = 0; i < _quantite; i++) {
                            panier.ajouterProduit(produit);
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(children: [
                                const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                                const SizedBox(width: 10),
                                Expanded(child: Text("$_quantite x ${produit.nom} ajouté${_quantite > 1 ? 's' : ''} au panier !")),
                              ]),
                              backgroundColor: const Color(0xFF16A34A).withValues(alpha: 0.90),
                            ),
                          );
                          context.pop();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF0F172A)
                                : const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Ajouter au panier",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(width: 10),
                              Icon(Icons.shopping_cart_checkout,
                                  color: Colors.white, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  Widget _boutonCircle({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: context.cardBg,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 10,
            ),
          ],
        ),
        child: Icon(icon, color: iconColor ?? context.textPrimary, size: 18),
      ),
    );
  }

  Widget _onglet(String label, int index) {
    final actif = _tabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _tabIndex = index),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: actif ? FontWeight.bold : FontWeight.normal,
              color: actif
                  ? context.textPrimary
                  : context.textHint,
            ),
          ),
          const SizedBox(height: 4),
          if (actif)
            Container(
              height: 2,
              width: 28,
              decoration: BoxDecoration(
                color: context.textPrimary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ),
    );
  }

  Widget _statItem(BuildContext context, IconData icon, String label) {
    return Expanded(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: context.containerBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 15, color: context.textSecondary),
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: context.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _ligneInfo(BuildContext context, String label, String valeur) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: context.scaffoldBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: context.textHint, fontSize: 14)),
          Text(valeur,
              style: TextStyle(
                color: context.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              )),
        ],
      ),
    );
  }

  Widget _boutonQuantite({
    required BuildContext context,
    required IconData icon,
    VoidCallback? onTap,
    bool filled = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: filled
              ? const Color(0xFF1E293B)
              : onTap != null
                  ? context.containerBg
                  : context.borderColor,
          borderRadius: BorderRadius.circular(10),
          border: filled && Theme.of(context).brightness == Brightness.dark
              ? Border.all(color: const Color(0xFF94A3B8), width: 1)
              : null,
        ),
        child: Icon(
          icon,
          size: 18,
          color: filled
              ? Colors.white
              : onTap != null
                  ? context.textPrimary
                  : context.textHint,
        ),
      ),
    );
  }
}
