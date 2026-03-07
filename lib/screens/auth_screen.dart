import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final AuthService _authService = AuthService();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _motDePasseController = TextEditingController();

  bool _estConnexion = true;
  bool _chargement = false;
  bool _afficherMotDePasse = false;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(() => setState(() {}));
    _motDePasseController.addListener(() => setState(() {}));
  }

  static const _bg = Color(0xFFF2F2F2);
  static const _dark = Color(0xFF1A1A1A);
  static const _fieldBorder = Color(0xFFDDDDDD);

  void _basculerMode() {
    setState(() {
      _estConnexion = !_estConnexion;
      _erreur = null;
    });
  }

  void _afficherResetMotDePasse() {
    final emailReset =
        TextEditingController(text: _emailController.text.trim());
    bool envoi = false;
    bool succes = false;
    String? erreurReset;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDDDDD),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                "Mot de passe oublié ?",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _dark,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "Entrez votre email pour recevoir un lien de réinitialisation.",
                style: TextStyle(fontSize: 13, color: Color(0xFF888888)),
              ),
              const SizedBox(height: 20),
              _buildField(
                controller: emailReset,
                hint: "exemple@email.com",
                icon: Icons.mail_outline,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              if (erreurReset != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline,
                        color: Color(0xFFDC2626), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(erreurReset!,
                          style: const TextStyle(
                              color: Color(0xFFDC2626), fontSize: 13)),
                    ),
                  ]),
                ),
              if (succes)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: const Row(children: [
                    Icon(Icons.check_circle,
                        color: Color(0xFF16A34A), size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Email envoyé ! Vérifiez votre boîte mail.",
                        style:
                            TextStyle(color: Color(0xFF16A34A), fontSize: 13),
                      ),
                    ),
                  ]),
                ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: envoi || succes
                      ? null
                      : () async {
                          final email = emailReset.text.trim();
                          if (email.isEmpty) return;
                          setModalState(() {
                            envoi = true;
                            erreurReset = null;
                          });
                          try {
                            await _authService
                                .reinitialiserMotDePasse(email);
                            setModalState(() {
                              envoi = false;
                              succes = true;
                            });
                          } catch (e) {
                            setModalState(() {
                              envoi = false;
                              erreurReset = e.toString();
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _dark,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: envoi
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          "Envoyer le lien",
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _connecterSocial(Future<dynamic> Function() methode) async {
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    try {
      final result = await methode();
      if (result != null && mounted) context.go('/');
    } catch (e) {
      if (mounted) setState(() => _erreur = e.toString());
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  Future<void> _soumettre() async {
    setState(() {
      _chargement = true;
      _erreur = null;
    });

    try {
      if (_estConnexion) {
        await _authService.connecter(
          email: _emailController.text.trim(),
          motDePasse: _motDePasseController.text.trim(),
        );
      } else {
        await _authService.inscrire(
          email: _emailController.text.trim(),
          motDePasse: _motDePasseController.text.trim(),
        );
      }
      if (mounted) context.go('/');
    } catch (e) {
      setState(() => _erreur = e.toString());
    } finally {
      setState(() => _chargement = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _motDePasseController.dispose();
    super.dispose();
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    Widget? suffix,
  }) {
    final filled = controller.text.isNotEmpty;
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      style: const TextStyle(fontSize: 15, color: _dark),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 14),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 14, right: 10),
          child: Icon(icon,
              color: filled ? _dark : const Color(0xFFAAAAAA), size: 20),
        ),
        prefixIconConstraints: const BoxConstraints(),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: filled ? _dark : _fieldBorder,
            width: filled ? 1.5 : 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: filled ? _dark : _fieldBorder,
            width: filled ? 1.5 : 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _dark, width: 1.5),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              // Titre
              Text(
                _estConnexion
                    ? "Connectez-vous\nà votre compte"
                    : "Créer\nun compte",
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: _dark,
                  height: 1.2,
                ),
              ),

              const SizedBox(height: 36),

              // Champ email
              _buildField(
                controller: _emailController,
                hint: "exemple@email.com",
                icon: Icons.mail_outline,
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 14),

              // Champ mot de passe
              _buildField(
                controller: _motDePasseController,
                hint: "Mot de passe",
                icon: Icons.lock_outline,
                obscure: !_afficherMotDePasse,
                suffix: IconButton(
                  icon: Icon(
                    _afficherMotDePasse
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: const Color(0xFFAAAAAA),
                    size: 20,
                  ),
                  onPressed: () => setState(
                      () => _afficherMotDePasse = !_afficherMotDePasse),
                ),
              ),

              // Mot de passe oublié
              if (_estConnexion)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _afficherResetMotDePasse,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      "Mot de passe oublié ?",
                      style: TextStyle(
                        color: Color(0xFF666666),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
              else
                const SizedBox(height: 16),

              // Erreur
              if (_erreur != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline,
                        color: Color(0xFFDC2626), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_erreur!,
                          style: const TextStyle(
                              color: Color(0xFFDC2626), fontSize: 13)),
                    ),
                  ]),
                ),
              ],

              // Bouton principal
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _chargement ? null : _soumettre,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _dark,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _chargement
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          _estConnexion ? "Se connecter" : "S'inscrire",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),

              // Basculer mode
              Center(
                child: GestureDetector(
                  onTap: _basculerMode,
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 14),
                      children: [
                        TextSpan(
                          text: _estConnexion
                              ? "Pas encore de compte ? "
                              : "Déjà un compte ? ",
                          style: const TextStyle(color: Color(0xFF888888)),
                        ),
                        TextSpan(
                          text: _estConnexion ? "S'inscrire" : "Se connecter",
                          style: const TextStyle(
                            color: _dark,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 36),

              // Séparateur
              Row(
                children: [
                  Expanded(
                      child: Divider(color: Colors.grey.withValues(alpha: 0.3))),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      "Continuer avec",
                      style: TextStyle(
                        color: Color(0xFF999999),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(
                      child: Divider(color: Colors.grey.withValues(alpha: 0.3))),
                ],
              ),

              const SizedBox(height: 20),

              // Bouton Google
              _boutonSocial(
                label: "GOOGLE",
                couleur: const Color(0xFFF5C6C6),
                textColor: const Color(0xFFC0392B),
                onTap: () => _connecterSocial(_authService.connecterAvecGoogle),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _boutonSocial({
    required String label,
    required Color couleur,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: _chargement ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: couleur,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}
