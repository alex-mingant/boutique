import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/produit.dart';
import '../services/produit_service.dart';
import '../widgets/produit_card.dart';
import '../theme/app_colors.dart';

class RechercheScreen extends StatefulWidget {
  const RechercheScreen({super.key});

  @override
  State<RechercheScreen> createState() => _RechercheScreenState();
}

class _RechercheScreenState extends State<RechercheScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _recherche = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
          onPressed: () => context.pop(),
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true, // 👈 clavier s'ouvre automatiquement
          decoration: InputDecoration(
            hintText: "Rechercher un produit...",
            hintStyle: TextStyle(color: context.textHint),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: context.inputFill,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            suffixIcon: _recherche.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: context.textHint),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _recherche = '');
                    },
                  )
                : null,
          ),
          onChanged: (valeur) => setState(() => _recherche = valeur.toLowerCase()),
        ),
      ),

      body: _recherche.isEmpty
          // Écran vide si aucune recherche
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search, size: 80, color: context.chevronColor),
                  const SizedBox(height: 16),
                  Text(
                    "Tapez le nom d'un produit",
                    style: TextStyle(color: context.textHint, fontSize: 16),
                  ),
                ],
              ),
            )
          // Résultats de recherche
          : StreamBuilder<List<Produit>>(
              stream: ProduitService().getProduits(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF2563EB)),
                  );
                }

                final tousLesProduits = snapshot.data ?? [];

                // Filtre par nom, sous-catégorie ou provenance
                final resultats = tousLesProduits.where((p) {
                  return p.nom.toLowerCase().contains(_recherche) ||
                      p.sousCategorie.toLowerCase().contains(_recherche) ||
                      p.provenance.toLowerCase().contains(_recherche) ||
                      p.description.toLowerCase().contains(_recherche);
                }).toList();

                if (resultats.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("😕", style: TextStyle(fontSize: 60)),
                        const SizedBox(height: 16),
                        Text(
                          "Aucun résultat pour\n\"$_recherche\"",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: context.textHint,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nombre de résultats
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Text(
                        "${resultats.length} résultat${resultats.length > 1 ? 's' : ''} pour \"$_recherche\"",
                        style: TextStyle(
                          color: context.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),

                    // Grille de résultats
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.72,
                        ),
                        itemCount: resultats.length,
                        itemBuilder: (context, index) {
                          final produit = resultats[index];
                          return ProduitCard(
                            produit: produit,
                            onTap: () => context.push(
                              '/produit/${produit.id}',
                              extra: produit,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
