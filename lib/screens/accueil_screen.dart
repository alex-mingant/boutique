import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/produit.dart';
import '../models/panier_pret.dart';
import '../providers/panier_provider.dart';
import '../services/produit_service.dart';
import '../services/panier_pret_service.dart';
import '../theme/app_colors.dart';

class AccueilScreen extends StatefulWidget {
  const AccueilScreen({super.key});

  @override
  State<AccueilScreen> createState() => _AccueilScreenState();
}

class _AccueilScreenState extends State<AccueilScreen> {
  final _produitService = ProduitService();
  final _panierPretService = PanierPretService();
  List<Produit> _produits = [];
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _sub = _produitService.getProduits().listen((liste) {
      if (mounted) setState(() => _produits = liste);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final phares = _produits.where((p) => p.phare).toList();
    final legumes = _produits.where((p) => p.saison).toList();

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: _buildAppBar(context),
      bottomNavigationBar: _buildBottomNav(context),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const SizedBox(height: 28),

            // ─── Nos rayons ──────────────────────────────────────
            _titreSection(context, "Nos rayons"),
            const SizedBox(height: 14),
            _buildCategories(context),
            const SizedBox(height: 28),

            // ─── Produits phares de la semaine ───────────────────
            if (phares.isNotEmpty) ...[
              _titreSectionLien(context, "Produits les + vendus ⭐", "Voir tout", () => context.push('/recherche')),
              const SizedBox(height: 14),
              _buildListeProduits(context, phares),
              const SizedBox(height: 28),
            ],

            // ─── Légumes de saison ───────────────────────────────
            if (legumes.isNotEmpty) ...[
              _titreSectionLien(context, "Produits de saison 🌱", "Voir tout", () => context.push('/categorie/legumes')),
              const SizedBox(height: 14),
              _buildListeProduits(context, legumes),
              const SizedBox(height: 28),
            ],

            // ─── Paniers prêts à commander ────────────────────────
            _titreSection(context, "Paniers prêts à commander 🧺"),
            const SizedBox(height: 14),
            _buildPaniersPrets(context),
            const SizedBox(height: 28),

            // ─── Informations pratiques ───────────────────────────
            _buildInfosPratiques(context),
            const SizedBox(height: 28),

            // ─── À propos du producteur ───────────────────────────
            _buildAPropos(context),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  AppBar
  // ─────────────────────────────────────────────────────────────

  bool _estOuvert() {
    final now = DateTime.now();
    final heure = now.hour + now.minute / 60.0;
    if (now.weekday >= 1 && now.weekday <= 6) {
      return heure >= 8 && heure < 19;
    } else {
      return heure >= 9 && heure < 13;
    }
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final ouvert = _estOuvert();
    return AppBar(
      backgroundColor: context.cardBg,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 16,
      title: Row(
        children: [
          Text(
            "Ma Boutique",
            style: TextStyle(
              color: context.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: ouvert ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: ouvert ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  ouvert ? "Ouvert" : "Fermé",
                  style: TextStyle(
                    color: ouvert ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        Consumer<PanierProvider>(
          builder: (context, panier, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.shopping_cart_outlined, color: context.textPrimary),
                  onPressed: () => context.go('/panier'),
                ),
                if (panier.nombreArticles > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFF1E293B),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        "${panier.nombreArticles}",
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        IconButton(
          icon: Icon(Icons.person_outline, color: context.textPrimary),
          onPressed: () => context.push('/profil'),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  Bottom Nav
  // ─────────────────────────────────────────────────────────────

  Widget _buildBottomNav(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BottomNavigationBar(
      currentIndex: 0,
      onTap: (index) {
        if (index == 1) context.go('/panier');
        if (index == 2) context.push('/commandes');
        if (index == 3) context.push('/profil');
      },
      backgroundColor: context.cardBg,
      selectedItemColor: const Color(0xFF1E293B),
      unselectedItemColor: context.textHint,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
      unselectedLabelStyle: const TextStyle(fontSize: 11),
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: "Accueil"),
        BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_outlined), activeIcon: Icon(Icons.shopping_cart), label: "Panier"),
        BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), activeIcon: Icon(Icons.receipt_long), label: "Commandes"),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: "Profil"),
      ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  Catégories
  // ─────────────────────────────────────────────────────────────

  Widget _buildCategories(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _carteCategorie(context, emoji: "🍎", label: "Fruits", imageUrl: "https://images.unsplash.com/photo-1619566636858-adf3ef46400b?w=300", categorie: "fruits"),
          _carteCategorie(context, emoji: "🥦", label: "Légumes", imageUrl: "https://images.unsplash.com/photo-1598170845058-32b9d6a5da37?w=300", categorie: "legumes"),
          _carteCategorie(context, emoji: "🛒", label: "Autres", imageUrl: "https://images.unsplash.com/photo-1506617564039-2f3b650b7010?w=300", categorie: "autres"),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  Liste de produits (scroll horizontal)
  // ─────────────────────────────────────────────────────────────

  Widget _buildListeProduits(BuildContext context, List<Produit> produits) {
    return SizedBox(
      height: 210,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: produits.length,
        itemBuilder: (context, i) => _carteProduit(context, produits[i]),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  Paniers prêts à commander
  // ─────────────────────────────────────────────────────────────

  // Mapping theme → couleurs
  static Color _fondTheme(String theme) {
    switch (theme) {
      case 'orange': return const Color(0xFFFFF7ED);
      case 'bleu':   return const Color(0xFFEFF6FF);
      case 'rouge':  return const Color(0xFFFEF2F2);
      default:       return const Color(0xFFF0FDF4); // vert
    }
  }

  static Color _prixTheme(String theme) {
    switch (theme) {
      case 'orange': return const Color(0xFFEA580C);
      case 'bleu':   return const Color(0xFF2563EB);
      case 'rouge':  return const Color(0xFFDC2626);
      default:       return const Color(0xFF16A34A); // vert
    }
  }

  Widget _buildPaniersPrets(BuildContext context) {
    return StreamBuilder<List<PanierPret>>(
      stream: _panierPretService.getPaniersPrets(),
      builder: (context, snapshot) {
        final paniers = snapshot.data ?? [];
        if (paniers.isEmpty) return const SizedBox();
        return SizedBox(
          height: 185,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: paniers.length,
            itemBuilder: (context, i) {
              final p = paniers[i];
              return GestureDetector(
                onTap: () => _afficherDetailPanier(context, p),
                child: Container(
                  width: 200,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.cardBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: context.borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _fondTheme(p.theme),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(child: Text(p.emoji, style: const TextStyle(fontSize: 22))),
                      ),
                      const SizedBox(height: 10),
                      Text(p.nom, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: context.textPrimary)),
                      const SizedBox(height: 4),
                      Expanded(
                        child: Text(p.contenu,
                            style: TextStyle(color: context.textSecondary, fontSize: 12),
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${p.prix.toStringAsFixed(2)} €',
                        style: TextStyle(color: _prixTheme(p.theme), fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _afficherDetailPanier(BuildContext context, PanierPret panier) {
    // Produits du panier tirés de la liste déjà chargée
    final produitsInclus = _produits.where((p) => panier.produitIds.contains(p.id)).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: ctx.cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: ctx.borderColor, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(color: _fondTheme(panier.theme), borderRadius: BorderRadius.circular(14)),
                  child: Center(child: Text(panier.emoji, style: const TextStyle(fontSize: 26))),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(panier.nom, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ctx.textPrimary)),
                    Text('${panier.prix.toStringAsFixed(2)} €',
                        style: TextStyle(color: _prixTheme(panier.theme), fontWeight: FontWeight.w600, fontSize: 15)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text("Contenu du panier", style: TextStyle(fontWeight: FontWeight.bold, color: ctx.textPrimary, fontSize: 14)),
            const SizedBox(height: 8),
            // Affiche les produits liés ou le texte libre si aucun produit lié
            if (produitsInclus.isNotEmpty)
              ...produitsInclus.map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Icon(Icons.circle, size: 5, color: ctx.textHint),
                        const SizedBox(width: 8),
                        Expanded(child: Text(p.nom, style: TextStyle(color: ctx.textSecondary, fontSize: 14))),
                        Text('${p.prix.toStringAsFixed(2)} €/${p.unite}',
                            style: TextStyle(color: ctx.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ))
            else
              Text(panier.contenu, style: TextStyle(color: ctx.textSecondary, fontSize: 14, height: 1.5)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final panierProvider = Provider.of<PanierProvider>(context, listen: false);
                  for (final p in produitsInclus) {
                    panierProvider.ajouterProduit(p);
                  }
                  Navigator.pop(context);
                  context.go('/panier');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E293B),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  produitsInclus.isEmpty
                      ? 'Aucun produit lié à ce panier'
                      : 'Ajouter au panier (${produitsInclus.length} article${produitsInclus.length > 1 ? 's' : ''})',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  Informations pratiques
  // ─────────────────────────────────────────────────────────────

  Widget _buildInfosPratiques(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Informations pratiques ℹ️",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.textPrimary),
          ),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: context.borderColor),
            ),
            child: Column(
              children: [
                _infoItem(context, Icons.access_time_outlined, "Horaires", "Lun–Sam : 8h–19h  |  Dim : 9h–13h"),
                _infoItem(context, Icons.local_shipping_outlined, "Livraison", "Commande avant 18h → livraison le lendemain"),
                _infoItem(context, Icons.location_on_outlined, "Zone", "Rayon de 30 km autour de Brest"),
                _infoItem(context, Icons.phone_outlined, "Contact", "+33 6 12 34 56 78", isLast: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoItem(BuildContext context, IconData icone, String titre, String sousTitre, {bool isLast = false}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.containerBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icone, color: context.textPrimary, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titre, style: TextStyle(fontWeight: FontWeight.w600, color: context.textPrimary, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(sousTitre, style: TextStyle(color: context.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast) Divider(height: 1, indent: 56, color: context.dividerColor),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  À propos du producteur
  // ─────────────────────────────────────────────────────────────

  Widget _buildAPropos(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: context.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text("🌾", style: TextStyle(fontSize: 24)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "À propos du producteur",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.textPrimary),
                      ),
                      Text(
                        "Ferme des Collines — Bordeaux",
                        style: TextStyle(color: context.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              "Depuis 1995, notre famille cultive des fruits et légumes frais sur 12 hectares de terres bordelaises. "
              "Nous favorisons une agriculture raisonnée pour vous offrir des produits de qualité tout au long de l'année.",
              style: TextStyle(color: context.textSecondary, fontSize: 14, height: 1.6),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _badge(context, "🌿 Agriculture raisonnée"),
                _badge(context, "🇫🇷 Produit local"),
                _badge(context, "♻️ Zéro gaspillage"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  Widgets réutilisables
  // ─────────────────────────────────────────────────────────────

  Widget _titreSection(BuildContext context, String titre) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(titre, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.textPrimary)),
    );
  }

  Widget _titreSectionLien(BuildContext context, String titre, String lien, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(titre, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.textPrimary)),
          GestureDetector(
            onTap: onTap,
            child: const Text(
              "Voir tout",
              style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _carteProduit(BuildContext context, Produit p) {
    return GestureDetector(
      onTap: () => context.push('/produit/${p.id}', extra: p),
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image plein format
              Image.network(
                p.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => Container(
                  color: context.containerBg,
                  child: Center(
                    child: Icon(Icons.image_not_supported_outlined, color: context.textHint, size: 28),
                  ),
                ),
              ),

              // Overlay dégradé en bas
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xCC1E1E1E)],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              p.nom,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (p.bio)
                            Container(
                              margin: const EdgeInsets.only(left: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF16A34A).withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text("Bio", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${p.prix.toStringAsFixed(2)} €/${p.unite}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _carteCategorie(
    BuildContext context, {
    required String emoji,
    required String label,
    required String imageUrl,
    required String categorie,
  }) {
    return GestureDetector(
      onTap: () => context.push('/categorie/$categorie'),
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image de fond
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => Container(color: Colors.grey.shade300),
              ),
              // Assombrissement
              Container(color: Colors.black.withValues(alpha: 0.35)),
              // Emoji + label
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 36)),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(BuildContext context, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: context.containerBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(fontSize: 12, color: context.textPrimary, fontWeight: FontWeight.w500)),
    );
  }
}
