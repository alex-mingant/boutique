import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get utilisateurActuel => _auth.currentUser;
  Stream<User?> get etatConnexion => _auth.authStateChanges();

  // Inscription
  Future<UserCredential?> inscrire({
    required String email,
    required String motDePasse,
  }) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: motDePasse,
      );
    } on FirebaseAuthException catch (e) {
      throw _getMessage(e.code);
    }
  }

  // Connexion email/mot de passe
  Future<UserCredential?> connecter({
    required String email,
    required String motDePasse,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: motDePasse,
      );
    } on FirebaseAuthException catch (e) {
      throw _getMessage(e.code);
    }
  }

  // Connexion Google
  Future<UserCredential?> connecterAvecGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return null; // annulé par l'utilisateur

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    try {
      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _getMessage(e.code);
    }
  }

  // Déconnexion
  Future<void> deconnecter() async {
    await GoogleSignIn().signOut();
    await _auth.signOut();
  }

  // Réinitialiser le mot de passe
  Future<void> reinitialiserMotDePasse(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _getMessage(e.code);
    }
  }

  String _getMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Aucun compte trouvé avec cet email.';
      case 'wrong-password':
        return 'Mot de passe incorrect.';
      case 'email-already-in-use':
        return 'Cet email est déjà utilisé.';
      case 'weak-password':
        return 'Le mot de passe doit faire au moins 6 caractères.';
      case 'invalid-email':
        return 'Adresse email invalide.';
      case 'account-exists-with-different-credential':
        return 'Un compte existe déjà avec cet email.';
      default:
        return 'Une erreur est survenue. Réessaie.';
    }
  }
}
