import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/produit.dart';
import '../services/favoris_service.dart';
import '../theme/app_colors.dart';

class FavorisScreen extends StatelessWidget {
  const FavorisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.cardBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Mes favoris',
          style: TextStyle(
            color: context.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<List<Produit>>(
        stream: FavorisService().getFavoris(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF2563EB)),
            );
          }

          final favoris = snapshot.data ?? [];

          if (favoris.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 80, color: context.chevronColor),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun favori pour l\'instant',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Appuyez sur le cœur dans un produit\npour l\'ajouter ici.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.textHint, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: favoris.length,
            itemBuilder: (context, index) {
              final produit = favoris[index];
              return _FavoriCard(produit: produit);
            },
          );
        },
      ),
    );
  }
}

class _FavoriCard extends StatelessWidget {
  final Produit produit;

  const _FavoriCard({required this.produit});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/produit/${produit.id}', extra: produit),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  produit.imageUrl,
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => Container(
                    width: 72,
                    height: 72,
                    color: context.containerBg,
                    child: Icon(Icons.image_not_supported,
                        color: context.chevronColor),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Infos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      produit.nom,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: context.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${produit.prix.toStringAsFixed(2)} € / ${produit.unite}',
                      style: const TextStyle(
                        color: Color(0xFF2563EB),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    if (produit.bio) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          '🌿 Bio',
                          style: TextStyle(
                            color: Color(0xFF16A34A),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Bouton retirer
              StreamBuilder<bool>(
                stream: FavorisService().estFavori(produit.id),
                builder: (context, snapshot) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.favorite, color: Colors.red),
                      onPressed: () => FavorisService().toggleFavori(produit),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
