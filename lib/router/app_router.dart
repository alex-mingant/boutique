import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../screens/accueil_screen.dart';
import '../screens/detail_screen.dart';
import '../screens/panier_screen.dart';
import '../screens/auth_screen.dart';
import '../screens/profil_screen.dart';
import '../models/produit.dart';
import '../screens/commandes_screen.dart';
import '../screens/admin_screen.dart';
import '../screens/sous_categorie_screen.dart';
import '../screens/recherche_screen.dart';
import '../screens/modifier_compte_screen.dart';
import '../screens/adresses_screen.dart';
import '../screens/promos_screen.dart';
import '../screens/favoris_screen.dart';
import '../screens/cartes_screen.dart';

// ⚙️ Remplace par ton email admin
const String _emailAdmin = 'enzo.omnes@gmail.com';

final appRouter = GoRouter(
  initialLocation: '/',

  redirect: (context, state) {
    final user = FirebaseAuth.instance.currentUser;
    final estConnecte = user != null;
    final versAuth = state.matchedLocation == '/auth';

    if (!estConnecte && !versAuth) return '/auth';
    if (estConnecte && versAuth) return '/';

    // Protège /admin : redirige vers l'accueil si pas admin
    if (state.matchedLocation == '/admin' && user?.email != _emailAdmin) {
      return '/';
    }

    return null;
  },

  routes: [
    GoRoute(
      path: '/auth',
      name: 'auth',
      builder: (context, state) => const AuthScreen(),
    ),
    GoRoute(
      path: '/',
      name: 'accueil',
      builder: (context, state) =>  AccueilScreen(),
    ),
    GoRoute(
      path: '/produit/:id',
      name: 'detail',
      builder: (context, state) {
        final produit = state.extra as Produit;
        return DetailScreen(produit: produit);
      },
    ),
    GoRoute(
      path: '/panier',
      name: 'panier',
      builder: (context, state) => const PanierScreen(),
      
    ),

    GoRoute(
  path: '/commandes',
  name: 'commandes',
  builder: (context, state) => const CommandesScreen(),
),
    
     GoRoute(
      path: '/profil',
      name: 'profil',
      builder: (context, state) => const ProfilScreen(),
    ),

    GoRoute(
  path: '/admin',
  name: 'admin',
  builder: (context, state) => const AdminScreen(),
),
GoRoute(
  path: '/recherche',
  name: 'recherche',
  builder: (context, state) => const RechercheScreen(),
),
        GoRoute(
  path: '/categorie/:categorie',
  name: 'sousCategorie',
  builder: (context, state) {
    final categorie = state.pathParameters['categorie']!;
    return SousCategorieScreen(categorie: categorie);
  },
),

GoRoute(
  path: '/profil/modifier',
  name: 'modifierCompte',
  builder: (context, state) => const ModifierCompteScreen(),
),
GoRoute(
  path: '/profil/adresses',
  name: 'adresses',
  builder: (context, state) => const AdressesScreen(),
),
GoRoute(
  path: '/profil/favoris',
  name: 'favoris',
  builder: (context, state) => const FavorisScreen(),
),
GoRoute(
  path: '/profil/promos',
  name: 'promos',
  builder: (context, state) => const PromosScreen(),
),
GoRoute(
  path: '/profil/cartes',
  name: 'cartes',
  builder: (context, state) => const CartesScreen(),
),
],
);

