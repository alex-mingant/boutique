import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../services/profil_service.dart';
import '../theme/app_colors.dart';

// Remplace par ton email admin
const String _emailAdmin = 'enzo.omnes@gmail.com';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  final _profilService = ProfilService();
  String _prenom = '';
  String _nom = '';

  @override
  void initState() {
    super.initState();
    _chargerProfil();
  }

  Future<void> _chargerProfil() async {
    final profil = await _profilService.getProfil();
    if (profil != null && mounted) {
      setState(() {
        _prenom = profil.prenom;
        _nom = profil.nom;
      });
    }
  }

  String get _nomAffiche {
    final plein = '$_prenom $_nom'.trim();
    if (plein.isNotEmpty) return plein;
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    return email.split('@')[0];
  }

  String get _initiale {
    if (_prenom.isNotEmpty) return _prenom[0].toUpperCase();
    if (_nom.isNotEmpty) return _nom[0].toUpperCase();
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    return email.isNotEmpty ? email[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? '';

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
          "Mon Profil",
          style: TextStyle(
            color: context.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // En-tête utilisateur
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: const Color(0xFF1E293B),
                    child: Text(
                      _initiale,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _nomAffiche,
                    style: TextStyle(
                      color: context.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: TextStyle(
                      color: context.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Menu options
            _sectionMenu(context, [
              _itemMenu(
                context,
                icone: Icons.person_outline,
                label: "Gérer le compte",
                onTap: () async {
                  await context.push('/profil/modifier');
                  _chargerProfil();
                },
              ),
              _itemMenu(
                context,
                icone: Icons.receipt_long_outlined,
                label: "Historique de commandes",
                onTap: () => context.push('/commandes'),
              ),
              _itemMenu(
                context,
                icone: Icons.local_offer_outlined,
                label: "Mes codes promos",
                onTap: () => context.push('/profil/promos'),
                isLast: true,
              ),
            ]),

            const SizedBox(height: 16),

            _sectionMenu(context, [
              _itemMenu(
                context,
                icone: Icons.location_on_outlined,
                label: "Mes adresses de livraison",
                onTap: () => context.push('/profil/adresses'),
              ),
              _itemMenu(
                context,
                icone: Icons.credit_card_outlined,
                label: "Mes cartes enregistrées",
                onTap: () => context.push('/profil/cartes'),
              ),
              _itemMenu(
                context,
                icone: Icons.favorite_outline,
                label: "Mes favoris",
                onTap: () => context.push('/profil/favoris'),
                isLast: true,
              ),
            ]),

            // Bouton admin — visible uniquement pour l'email admin
            if (email == _emailAdmin) ...[
              const SizedBox(height: 16),
              _sectionMenu(context, [
                _itemMenu(
                  context,
                  icone: Icons.admin_panel_settings_outlined,
                  label: "Panel Admin",
                  onTap: () => context.push('/admin'),
                  isLast: true,
                ),
              ]),
            ],

            const SizedBox(height: 16),

            _sectionMenu(context, [
              _itemMenu(
                context,
                icone: Icons.logout,
                label: "Se déconnecter",
                couleur: Colors.red,
                onTap: () async {
                  await AuthService().deconnecter();
                  if (context.mounted) context.go('/auth');
                },
                isLast: true,
                afficherChevron: false,
              ),
            ]),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // Conteneur section menu
  Widget _sectionMenu(BuildContext context, List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(children: items),
    );
  }

  // Item de menu
  Widget _itemMenu(
    BuildContext context, {
    required IconData icone,
    required String label,
    required VoidCallback onTap,
    Color? couleur,
    bool isLast = false,
    bool afficherChevron = true,
  }) {
    final couleurEffective = couleur ?? context.textPrimary;
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Icône dans un carré arrondi
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: couleur == Colors.red
                        ? Colors.red[50]
                        : context.containerBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icone, color: couleurEffective, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: couleurEffective,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (afficherChevron)
                  Icon(Icons.chevron_right,
                      color: context.chevronColor, size: 20),
              ],
            ),
          ),
        ),
        if (!isLast)
          Divider(height: 1, indent: 56, color: context.dividerColor),
      ],
    );
  }

}
