import 'package:flutter/material.dart';
import '../models/commande.dart';
import '../models/code_promo.dart';
import '../models/panier_pret.dart';
import '../services/commande_service.dart';
import '../services/promo_service.dart';
import '../services/produit_service.dart';
import '../services/panier_pret_service.dart';
import '../models/produit.dart';
import '../theme/app_colors.dart';

// Helper partagé pour le style des champs
InputDecoration _inputDeco(BuildContext context, String label, {String? hint, IconData? icon}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    hintStyle: TextStyle(color: context.textHint),
    prefixIcon: icon != null
        ? Icon(icon, color: context.textSecondary, size: 20)
        : null,
    filled: true,
    fillColor: context.inputFill,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF1E293B), width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFDC2626)),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFDC2626), width: 2),
    ),
  );
}

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.cardBg,
        elevation: 0,
        iconTheme: IconThemeData(color: context.textPrimary),
        title: Text(
          "Panel Admin",
          style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: context.textPrimary,
          unselectedLabelColor: context.textHint,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontSize: 13),
          indicatorColor: context.textPrimary,
          indicatorWeight: 2,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(text: 'Commandes'),
            Tab(text: 'Codes promos'),
            Tab(text: 'Produits'),
            Tab(text: 'Paniers'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _CommandesTab(),
          _CodesPromosTab(),
          _ProduitsTab(),
          _PaniersPretsTab(),
        ],
      ),
    );
  }
}

// ─── Onglet Commandes ────────────────────────────────────────────────────────

class _CommandesTab extends StatelessWidget {
  const _CommandesTab();

  Color _couleur(String statut) {
    switch (statut) {
      case 'expédiée': return const Color(0xFF2563EB);
      case 'livrée':   return const Color(0xFF16A34A);
      default:         return const Color(0xFFD97706);
    }
  }

  String _emoji(String statut) {
    switch (statut) {
      case 'expédiée': return '🚚';
      case 'livrée':   return '✅';
      default:         return '🟠';
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: CommandeService().getToutesLesCommandes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF1E293B)));
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.wifi_off_outlined, size: 48, color: context.textHint),
                const SizedBox(height: 12),
                Text("Erreur : ${snapshot.error}",
                    style: TextStyle(color: context.textHint), textAlign: TextAlign.center),
              ],
            ),
          );
        }

        final commandes = snapshot.data ?? [];

        if (commandes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 100, height: 100,
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: context.containerBg, shape: BoxShape.circle),
                    child: Icon(Icons.receipt_long_outlined, size: 46, color: context.textHint),
                  ),
                ),
                const SizedBox(height: 24),
                Text("Aucune commande", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.textPrimary)),
                const SizedBox(height: 8),
                Text("Les commandes clients apparaîtront ici", style: TextStyle(color: context.textHint, fontSize: 14)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          itemCount: commandes.length,
          itemBuilder: (context, index) {
            final uid = commandes[index]['uid'] as String;
            final commande = commandes[index]['commande'] as Commande;
            final couleur = _couleur(commande.statut);

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: context.borderColor),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42, height: 42,
                          decoration: BoxDecoration(color: context.containerBg, borderRadius: BorderRadius.circular(12)),
                          child: Icon(Icons.receipt_long_outlined, color: context.textPrimary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Commande #${commande.id.substring(0, 6).toUpperCase()}",
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: context.textPrimary)),
                              Text("Client : ${uid.substring(0, 8)}...",
                                  style: TextStyle(color: context.textHint, fontSize: 12)),
                            ],
                          ),
                        ),
                        Text("${commande.total.toStringAsFixed(2)} €",
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: context.textPrimary)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...commande.produits.map(
                      (p) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Icon(Icons.circle, size: 5, color: context.textHint),
                            const SizedBox(width: 8),
                            Expanded(child: Text(p.nom, style: TextStyle(fontSize: 13, color: context.textSecondary))),
                            Text("${p.prix.toStringAsFixed(2)} €",
                                style: TextStyle(fontSize: 13, color: context.textPrimary, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ),
                    Container(height: 1, color: context.dividerColor, margin: const EdgeInsets.symmetric(vertical: 10)),
                    Row(
                      children: [
                        Icon(
                          commande.modeLivraison == 'livraison' ? Icons.local_shipping_outlined : Icons.store_outlined,
                          size: 14, color: context.textHint,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          commande.modeLivraison == 'livraison' ? 'Livraison à domicile' : 'Retrait en magasin',
                          style: TextStyle(fontSize: 13, color: context.textSecondary),
                        ),
                      ],
                    ),
                    if (commande.modeLivraison == 'livraison' && commande.adresseLivraison != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 20, top: 2),
                        child: Text(
                          "${commande.adresseLivraison!.adresse}, ${commande.adresseLivraison!.codePostal} ${commande.adresseLivraison!.ville}",
                          style: TextStyle(fontSize: 12, color: context.textHint),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: couleur.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: couleur.withValues(alpha: 0.30)),
                          ),
                          child: Text(
                            "${_emoji(commande.statut)}  ${commande.statut[0].toUpperCase()}${commande.statut.substring(1)}",
                            style: TextStyle(color: couleur, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(color: context.containerBg, borderRadius: BorderRadius.circular(10)),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: commande.statut,
                              isDense: true,
                              style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                              icon: Icon(Icons.keyboard_arrow_down, color: context.textSecondary, size: 18),
                              items: const [
                                DropdownMenuItem(value: 'en cours', child: Text("🟠 En cours")),
                                DropdownMenuItem(value: 'expédiée', child: Text("🔵 Expédiée")),
                                DropdownMenuItem(value: 'livrée', child: Text("🟢 Livrée")),
                              ],
                              onChanged: (nouveauStatut) async {
                                if (nouveauStatut != null) {
                                  await CommandeService().mettreAJourStatut(uid, commande.id, nouveauStatut);
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ─── Onglet Codes promos ─────────────────────────────────────────────────────

class _CodesPromosTab extends StatefulWidget {
  const _CodesPromosTab();

  @override
  State<_CodesPromosTab> createState() => _CodesPromosTabState();
}

class _CodesPromosTabState extends State<_CodesPromosTab> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _valeurController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _minAchatController = TextEditingController();
  final _maxUtilisationsController = TextEditingController();
  String _type = 'pourcentage';
  DateTime? _dateExpiration;
  bool _chargement = false;

  @override
  void dispose() {
    _codeController.dispose();
    _valeurController.dispose();
    _descriptionController.dispose();
    _minAchatController.dispose();
    _maxUtilisationsController.dispose();
    super.dispose();
  }

  Future<void> _choisirDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (date != null) setState(() => _dateExpiration = date);
  }

  Future<void> _creerCode() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _chargement = true);
    try {
      final code = CodePromo(
        id: '',
        code: _codeController.text.trim().toUpperCase(),
        type: _type,
        valeur: double.parse(_valeurController.text.trim()),
        description: _descriptionController.text.trim(),
        minAchat: _minAchatController.text.isEmpty ? 0 : double.parse(_minAchatController.text.trim()),
        dateExpiration: _dateExpiration,
        maxUtilisations: _maxUtilisationsController.text.isEmpty ? null : int.parse(_maxUtilisationsController.text.trim()),
      );
      await PromoService().creerCode(code);
      _codeController.clear();
      _valeurController.clear();
      _descriptionController.clear();
      _minAchatController.clear();
      _maxUtilisationsController.clear();
      setState(() => _dateExpiration = null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Row(children: [
            Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Expanded(child: Text('Code promo créé avec succès !')),
          ]),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text('Erreur : $e')),
          ]),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ));
      }
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
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
                        width: 42, height: 42,
                        decoration: BoxDecoration(color: context.containerBg, borderRadius: BorderRadius.circular(12)),
                        child: Icon(Icons.local_offer_outlined, color: context.textPrimary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text('Créer un code promo',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: context.textPrimary)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _codeController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: _inputDeco(context, 'Code *', hint: 'ex: SUMMER10', icon: Icons.tag),
                    validator: (v) => (v == null || v.isEmpty) ? 'Champ requis' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _type,
                    decoration: _inputDeco(context, 'Type de réduction', icon: Icons.percent),
                    dropdownColor: context.cardBg,
                    style: TextStyle(color: context.textPrimary, fontSize: 14),
                    items: const [
                      DropdownMenuItem(value: 'pourcentage', child: Text('Pourcentage (%)')),
                      DropdownMenuItem(value: 'fixe', child: Text('Montant fixe (€)')),
                    ],
                    onChanged: (v) => setState(() => _type = v!),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _valeurController,
                    keyboardType: TextInputType.number,
                    decoration: _inputDeco(
                      context,
                      _type == 'pourcentage' ? 'Valeur en % *' : 'Valeur en € *',
                      hint: _type == 'pourcentage' ? 'ex: 10' : 'ex: 5',
                      icon: _type == 'pourcentage' ? Icons.percent : Icons.euro_outlined,
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Champ requis';
                      if (double.tryParse(v) == null) return 'Nombre invalide';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: _inputDeco(context, 'Description', hint: 'ex: 10% sur votre commande', icon: Icons.description_outlined),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _minAchatController,
                    keyboardType: TextInputType.number,
                    decoration: _inputDeco(context, 'Montant minimum d\'achat (€)', hint: 'Laisser vide si aucun minimum', icon: Icons.shopping_bag_outlined),
                    validator: (v) {
                      if (v != null && v.isNotEmpty && double.tryParse(v) == null) return 'Nombre invalide';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _choisirDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(color: context.containerBg, borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today_outlined, color: context.textSecondary, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _dateExpiration == null
                                  ? 'Aucune expiration (illimitée)'
                                  : '${_dateExpiration!.day.toString().padLeft(2, '0')}/${_dateExpiration!.month.toString().padLeft(2, '0')}/${_dateExpiration!.year}',
                              style: TextStyle(
                                color: _dateExpiration == null ? context.textHint : context.textPrimary,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          if (_dateExpiration != null)
                            GestureDetector(
                              onTap: () => setState(() => _dateExpiration = null),
                              child: Icon(Icons.close, size: 16, color: context.textHint),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _maxUtilisationsController,
                    keyboardType: TextInputType.number,
                    decoration: _inputDeco(context, 'Nombre max d\'utilisations', hint: 'Laisser vide si illimité', icon: Icons.people_outline),
                    validator: (v) {
                      if (v != null && v.isNotEmpty && int.tryParse(v) == null) return 'Nombre entier requis';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _chargement ? null : _creerCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E293B),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _chargement
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add, size: 18),
                                SizedBox(width: 8),
                                Text('Créer le code promo', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Onglet Produits ──────────────────────────────────────────────────────────

class _ProduitsTab extends StatefulWidget {
  const _ProduitsTab();

  @override
  State<_ProduitsTab> createState() => _ProduitsTabState();
}

class _ProduitsTabState extends State<_ProduitsTab> {
  final _service = ProduitService();

  void _ouvrirFormulaireAjout(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _FormulaireProduit(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<List<Produit>>(
            stream: _service.getProduits(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF1E293B)));
              }
              final produits = snapshot.data ?? [];
              if (produits.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 100, height: 100,
                        child: DecoratedBox(
                          decoration: BoxDecoration(color: context.containerBg, shape: BoxShape.circle),
                          child: Icon(Icons.inventory_2_outlined, size: 46, color: context.textHint),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text("Aucun produit", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.textPrimary)),
                      const SizedBox(height: 8),
                      Text("Ajoutez votre premier produit", style: TextStyle(color: context.textHint, fontSize: 14)),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => _ouvrirFormulaireAjout(context),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text("Ajouter un produit"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E293B),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                itemCount: produits.length,
                itemBuilder: (context, index) => _ProduitItem(produit: produits[index]),
              );
            },
          ),
        ),
        // Bouton fixe en bas
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _ouvrirFormulaireAjout(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text("Ajouter un produit", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E293B),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Formulaire création/édition produit (bottom sheet) ──────────────────────

class _FormulaireProduit extends StatefulWidget {
  final Produit? produitExistant;
  const _FormulaireProduit({this.produitExistant});

  @override
  State<_FormulaireProduit> createState() => _FormulaireProduitState();
}

class _FormulaireProduitState extends State<_FormulaireProduit> {
  final _service = ProduitService();
  late final TextEditingController _nomController;
  late final TextEditingController _prixController;
  late final TextEditingController _imageController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _prixAuKgController;
  late final TextEditingController _provenanceController;
  late String _categorie;
  late String _unite;
  late bool _bio;
  late bool _phare;
  late bool _saison;
  bool _chargement = false;

  bool get _estEdition => widget.produitExistant != null;

  @override
  void initState() {
    super.initState();
    final p = widget.produitExistant;
    _nomController = TextEditingController(text: p?.nom ?? '');
    _prixController = TextEditingController(text: p != null ? p.prix.toString() : '');
    _imageController = TextEditingController(text: p?.imageUrl ?? '');
    _descriptionController = TextEditingController(text: p?.description ?? '');
    _prixAuKgController = TextEditingController(text: p != null && p.prixAuKg > 0 ? p.prixAuKg.toString() : '');
    _provenanceController = TextEditingController(text: p?.provenance ?? 'France');
    const validCategories = ['fruits', 'legumes', 'autres'];
    const validUnites = ['kg', 'pièce'];
    final cat = p?.categorie ?? 'fruits';
    final uni = p?.unite ?? 'kg';
    _categorie = validCategories.contains(cat) ? cat : 'fruits';
    _unite = validUnites.contains(uni) ? uni : 'kg';
    _bio = p?.bio ?? false;
    _phare = p?.phare ?? false;
    _saison = p?.saison ?? false;
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prixController.dispose();
    _imageController.dispose();
    _descriptionController.dispose();
    _prixAuKgController.dispose();
    _provenanceController.dispose();
    super.dispose();
  }

  Future<void> _enregistrer() async {
    if (_nomController.text.trim().isEmpty || _prixController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Nom et prix sont requis'),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ));
      return;
    }
    final prixVal = double.tryParse(_prixController.text.trim());
    if (prixVal == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Prix invalide'),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ));
      return;
    }
    setState(() => _chargement = true);
    try {
      if (_estEdition) {
        await _service.mettreAJourProduit(widget.produitExistant!.id, {
          'nom': _nomController.text.trim(),
          'prix': prixVal,
          'imageUrl': _imageController.text.trim(),
          'description': _descriptionController.text.trim(),
          'categorie': _categorie,
          'unite': _unite,
          'prixAuKg': double.tryParse(_prixAuKgController.text.trim()) ?? 0,
          'provenance': _provenanceController.text.trim().isEmpty ? 'France' : _provenanceController.text.trim(),
          'bio': _bio,
          'phare': _phare,
          'saison': _saison,
        });
      } else {
        await _service.ajouterProduit(Produit(
          id: '',
          nom: _nomController.text.trim(),
          prix: prixVal,
          imageUrl: _imageController.text.trim(),
          description: _descriptionController.text.trim(),
          categorie: _categorie,
          unite: _unite,
          prixAuKg: double.tryParse(_prixAuKgController.text.trim()) ?? 0,
          provenance: _provenanceController.text.trim().isEmpty ? 'France' : _provenanceController.text.trim(),
          bio: _bio,
          phare: _phare,
          saison: _saison,
        ));
      }
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(_estEdition ? 'Produit modifié avec succès !' : 'Produit ajouté avec succès !')),
          ]),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text('Erreur : $e')),
          ]),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ));
      }
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: context.scaffoldBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle + titre
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(bottom: BorderSide(color: context.borderColor)),
            ),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: context.borderColor, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(color: context.containerBg, borderRadius: BorderRadius.circular(10)),
                      child: Icon(_estEdition ? Icons.edit_outlined : Icons.inventory_2_outlined, color: context.textPrimary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(_estEdition ? "Modifier le produit" : "Nouveau produit",
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: context.textPrimary)),
                  ],
                ),
              ],
            ),
          ),

          // Champs scrollables
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Infos principales ──
                  _sectionLabel(context, "Informations principales"),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nomController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: _inputDeco(context, 'Nom du produit *', hint: 'ex: Tomates cerises', icon: Icons.label_outline),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _prixController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: _inputDeco(context, 'Prix (€) *', hint: '2.50', icon: Icons.euro_outlined),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _dropdown<String>(
                          context: context,
                          value: _unite,
                          items: const [
                            DropdownMenuItem(value: 'kg', child: Text('Par kg')),
                            DropdownMenuItem(value: 'pièce', child: Text('À la pièce')),
                          ],
                          onChanged: (v) => setState(() => _unite = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _dropdown<String>(
                    context: context,
                    value: _categorie,
                    items: const [
                      DropdownMenuItem(value: 'fruits', child: Text('🍎  Fruits')),
                      DropdownMenuItem(value: 'legumes', child: Text('🥦  Légumes')),
                      DropdownMenuItem(value: 'autres', child: Text('🛒  Autres')),
                    ],
                    onChanged: (v) => setState(() => _categorie = v!),
                  ),

                  const SizedBox(height: 20),
                  _sectionLabel(context, "Détails"),
                  const SizedBox(height: 12),

                  TextField(
                    controller: _imageController,
                    decoration: _inputDeco(context, 'URL de l\'image', hint: 'https://...', icon: Icons.image_outlined),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: _inputDeco(context, 'Description', hint: 'Décrivez le produit...', icon: Icons.description_outlined),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _prixAuKgController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: _inputDeco(context, 'Prix au kg (€)', hint: 'Optionnel', icon: Icons.straighten_outlined),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _provenanceController,
                          decoration: _inputDeco(context, 'Provenance', hint: 'France', icon: Icons.location_on_outlined),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Switches
                  _switchRow(context, Icons.eco_outlined, 'Produit bio', _bio, const Color(0xFF16A34A), (v) => setState(() => _bio = v)),
                  const SizedBox(height: 8),
                  _switchRow(context, Icons.star_outline, 'Produit phare ⭐', _phare, const Color(0xFF1E293B), (v) => setState(() => _phare = v)),
                  const SizedBox(height: 8),
                  _switchRow(context, Icons.eco, 'Légume de saison 🌱', _saison, const Color(0xFF16A34A), (v) => setState(() => _saison = v)),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Bouton enregistrer
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            color: context.cardBg,
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _chargement ? null : _enregistrer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E293B),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _chargement
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check, size: 18),
                          const SizedBox(width: 8),
                          Text(_estEdition ? "Modifier le produit" : "Enregistrer le produit",
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String label) {
    return Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.textSecondary, letterSpacing: 0.5));
  }

  Widget _switchRow(BuildContext context, IconData icon, String label, bool value, Color activeColor, ValueChanged<bool> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(color: context.containerBg, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, color: context.textSecondary, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: TextStyle(fontSize: 14, color: context.textPrimary))),
          Switch(value: value, activeThumbColor: activeColor, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _dropdown<T>({
    required BuildContext context,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(color: context.containerBg, borderRadius: BorderRadius.circular(12)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          style: TextStyle(color: context.textPrimary, fontSize: 14),
          icon: Icon(Icons.keyboard_arrow_down, color: context.textSecondary, size: 18),
          dropdownColor: context.cardBg,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ─── Item produit ──────────────────────────────────────────────────────────────

class _ProduitItem extends StatelessWidget {
  final Produit produit;
  const _ProduitItem({required this.produit});

  @override
  Widget build(BuildContext context) {
    final service = ProduitService();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: produit.imageUrl.isNotEmpty
                ? Image.network(produit.imageUrl, width: 48, height: 48, fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => _iconePlaceholder(context))
                : _iconePlaceholder(context),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(produit.nom,
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: context.textPrimary),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('${produit.prix.toStringAsFixed(2)} €/${produit.unite}  •  ${produit.categorie}',
                    style: TextStyle(color: context.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          // Toggle Phare
          Column(
            children: [
              const Text("⭐", style: TextStyle(fontSize: 13)),
              Switch(
                value: produit.phare,
                activeThumbColor: const Color(0xFF1E293B),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onChanged: (val) => service.mettreAJourProduit(produit.id, {'phare': val}),
              ),
            ],
          ),
          // Toggle Saison
          Column(
            children: [
              const Text("🌱", style: TextStyle(fontSize: 13)),
              Switch(
                value: produit.saison,
                activeThumbColor: const Color(0xFF16A34A),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onChanged: (val) => service.mettreAJourProduit(produit.id, {'saison': val}),
              ),
            ],
          ),
          // Modifier
          IconButton(
            icon: Icon(Icons.edit_outlined, color: context.textSecondary, size: 20),
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => _FormulaireProduit(produitExistant: produit),
            ),
          ),
          // Supprimer
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
            onPressed: () => _confirmerSuppression(context, service),
          ),
        ],
      ),
    );
  }

  void _confirmerSuppression(BuildContext context, ProduitService service) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text("Supprimer le produit ?", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text('"${produit.nom}" sera définitivement supprimé.', style: TextStyle(color: context.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text("Annuler", style: TextStyle(color: context.textSecondary))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              service.supprimerProduit(produit.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text("Supprimer"),
          ),
        ],
      ),
    );
  }

  Widget _iconePlaceholder(BuildContext context) => Container(
        width: 48, height: 48,
        color: context.containerBg,
        child: Icon(Icons.image_not_supported_outlined, color: context.textHint, size: 22),
      );
}

// ─── Onglet Paniers prêts ────────────────────────────────────────────────────

class _PaniersPretsTab extends StatefulWidget {
  const _PaniersPretsTab();

  @override
  State<_PaniersPretsTab> createState() => _PaniersPretsTabState();
}

class _PaniersPretsTabState extends State<_PaniersPretsTab> {
  final _service = PanierPretService();
  final _nomController = TextEditingController();
  final _emojiController = TextEditingController();
  final _contenuController = TextEditingController();
  final _prixController = TextEditingController();
  final _ordreController = TextEditingController();
  String _theme = 'vert';
  bool _chargement = false;
  final Set<String> _selectedProduitIds = {};

  static const _themes = {
    'vert':   ('Vert',   Color(0xFF16A34A)),
    'orange': ('Orange', Color(0xFFEA580C)),
    'bleu':   ('Bleu',   Color(0xFF2563EB)),
    'rouge':  ('Rouge',  Color(0xFFDC2626)),
  };

  @override
  void dispose() {
    _nomController.dispose();
    _emojiController.dispose();
    _contenuController.dispose();
    _prixController.dispose();
    _ordreController.dispose();
    super.dispose();
  }

  void _ouvrirSelecteurProduits(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (context, setModal) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: context.borderColor, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Text("Sélectionner les produits",
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: context.textPrimary)),
              const SizedBox(height: 4),
              Text("${_selectedProduitIds.length} produit(s) sélectionné(s)",
                  style: TextStyle(color: context.textSecondary, fontSize: 13)),
              const SizedBox(height: 12),
              Expanded(
                child: StreamBuilder<List<Produit>>(
                  stream: ProduitService().getProduits(),
                  builder: (context, snapshot) {
                    final produits = snapshot.data ?? [];
                    return ListView.builder(
                      itemCount: produits.length,
                      itemBuilder: (context, i) {
                        final p = produits[i];
                        final selectionne = _selectedProduitIds.contains(p.id);
                        return CheckboxListTile(
                          value: selectionne,
                          activeColor: const Color(0xFF1E293B),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                          title: Text(p.nom, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: context.textPrimary)),
                          subtitle: Text('${p.prix.toStringAsFixed(2)} €/${p.unite}',
                              style: TextStyle(fontSize: 12, color: context.textSecondary)),
                          secondary: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: p.imageUrl.isNotEmpty
                                ? Image.network(p.imageUrl, width: 40, height: 40, fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) => _imgPlaceholder(context))
                                : _imgPlaceholder(context),
                          ),
                          onChanged: (val) {
                            setModal(() {
                              if (val == true) {
                                _selectedProduitIds.add(p.id);
                              } else {
                                _selectedProduitIds.remove(p.id);
                              }
                            });
                            setState(() {}); // met à jour le compteur dans le formulaire
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E293B),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      _selectedProduitIds.isEmpty
                          ? 'Aucun produit sélectionné'
                          : 'Confirmer (${_selectedProduitIds.length})',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imgPlaceholder(BuildContext context) => Container(
        width: 40, height: 40,
        color: context.containerBg,
        child: Icon(Icons.image_not_supported_outlined, color: context.textHint, size: 18),
      );

  Future<void> _ajouter() async {
    if (_nomController.text.trim().isEmpty || _prixController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Nom et prix sont requis'),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ));
      return;
    }
    setState(() => _chargement = true);
    try {
      await _service.ajouterPanier(PanierPret(
        id: '',
        nom: _nomController.text.trim(),
        emoji: _emojiController.text.trim().isEmpty ? '🧺' : _emojiController.text.trim(),
        contenu: _contenuController.text.trim(),
        prix: double.tryParse(_prixController.text.trim()) ?? 0,
        theme: _theme,
        ordre: int.tryParse(_ordreController.text.trim()) ?? 0,
        produitIds: _selectedProduitIds.toList(),
      ));
      _nomController.clear();
      _emojiController.clear();
      _contenuController.clear();
      _prixController.clear();
      _ordreController.clear();
      setState(() {
        _theme = 'vert';
        _selectedProduitIds.clear();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Row(children: [
            Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Expanded(child: Text('Panier ajouté avec succès !')),
          ]),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ));
      }
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Liste des paniers existants ──
          StreamBuilder<List<PanierPret>>(
            stream: _service.getPaniersPrets(),
            builder: (context, snapshot) {
              final paniers = snapshot.data ?? [];
              if (paniers.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: context.cardBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: context.borderColor),
                  ),
                  child: Center(
                    child: Text("Aucun panier pour l'instant",
                        style: TextStyle(color: context.textHint, fontSize: 14)),
                  ),
                );
              }
              return Column(
                children: paniers.map((panier) {
                  final info = _themes[panier.theme] ?? _themes['vert']!;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: context.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.borderColor),
                    ),
                    child: Row(
                      children: [
                        Text(panier.emoji, style: const TextStyle(fontSize: 28)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(panier.nom,
                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: context.textPrimary)),
                              Text('${panier.prix.toStringAsFixed(2)} €  •  ${info.$1}',
                                  style: TextStyle(color: info.$2, fontSize: 12, fontWeight: FontWeight.w500)),
                              if (panier.contenu.isNotEmpty)
                                Text(panier.contenu,
                                    style: TextStyle(color: context.textHint, fontSize: 12),
                                    maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                          onPressed: () => _service.supprimerPanier(panier.id),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),

          const SizedBox(height: 20),

          // ── Formulaire d'ajout ──
          Container(
            padding: const EdgeInsets.all(16),
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
                      width: 42, height: 42,
                      decoration: BoxDecoration(color: context.containerBg, borderRadius: BorderRadius.circular(12)),
                      child: const Center(child: Text("🧺", style: TextStyle(fontSize: 20))),
                    ),
                    const SizedBox(width: 12),
                    Text('Ajouter un panier',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: context.textPrimary)),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _nomController,
                        decoration: _inputDeco(context, 'Nom du panier *', hint: 'ex: Panier Famille', icon: Icons.shopping_basket_outlined),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 90,
                      child: TextField(
                        controller: _emojiController,
                        decoration: _inputDeco(context, 'Emoji', hint: '🧺'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _contenuController,
                  maxLines: 2,
                  decoration: _inputDeco(context, 'Contenu (description)', hint: 'ex: Tomates, carottes, salade...', icon: Icons.list_outlined),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _prixController,
                        keyboardType: TextInputType.number,
                        decoration: _inputDeco(context, 'Prix (€) *', hint: '12.90', icon: Icons.euro_outlined),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _ordreController,
                        keyboardType: TextInputType.number,
                        decoration: _inputDeco(context, 'Ordre', hint: '0 = premier', icon: Icons.sort_outlined),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Sélecteur de thème couleur
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: context.containerBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _theme,
                      isExpanded: true,
                      style: TextStyle(color: context.textPrimary, fontSize: 14),
                      icon: Icon(Icons.keyboard_arrow_down, color: context.textSecondary, size: 18),
                      dropdownColor: context.cardBg,
                      items: _themes.entries.map((e) {
                        return DropdownMenuItem(
                          value: e.key,
                          child: Row(
                            children: [
                              Container(width: 14, height: 14, decoration: BoxDecoration(color: e.value.$2, shape: BoxShape.circle)),
                              const SizedBox(width: 10),
                              Text(e.value.$1),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => _theme = v!),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Sélecteur de produits
                GestureDetector(
                  onTap: () => _ouvrirSelecteurProduits(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: context.containerBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.checklist_outlined, color: context.textSecondary, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _selectedProduitIds.isEmpty
                                ? 'Sélectionner les produits du panier'
                                : '${_selectedProduitIds.length} produit(s) sélectionné(s)',
                            style: TextStyle(
                              color: _selectedProduitIds.isEmpty
                                  ? context.textHint
                                  : context.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Icon(Icons.chevron_right, color: context.chevronColor, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _chargement ? null : _ajouter,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E293B),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _chargement
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add, size: 18),
                              SizedBox(width: 8),
                              Text('Ajouter le panier', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
