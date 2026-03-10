# ma_boutique

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Build iOS sans Mac local (GitHub Actions)

Un workflow est disponible dans `.github/workflows/ios-build.yml`.

### 1) Build iOS de validation (sans signature)

- Exécuté automatiquement sur `push` vers `main` et sur `pull_request`.
- Produit un artifact `ios-simulator-runner-app` (`Runner.app`) via:
	- `flutter build ios --simulator --debug`

Ce mode valide la compilation iOS sans certificat Apple.

### 2) Build `.ipa` signé (optionnel)

Lance le workflow manuellement (`Run workflow`) et active `build_signed_ipa=true`.

Ajoute ces secrets GitHub dans **Settings > Secrets and variables > Actions** :

- `BUILD_CERTIFICATE_BASE64` : certificat iOS `.p12` encodé en base64
- `P12_PASSWORD` : mot de passe du `.p12`
- `BUILD_PROVISION_PROFILE_BASE64` : provisioning profile `.mobileprovision` encodé base64
- `KEYCHAIN_PASSWORD` : mot de passe temporaire du keychain CI
- `EXPORT_OPTIONS_PLIST_BASE64` : contenu du `ExportOptions.plist` encodé base64

Le job génère ensuite l’artifact `ios-signed-ipa`.

### Encodage base64 (PowerShell)

Exemple pour générer les valeurs de secrets:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("C:\path\certificat.p12"))
[Convert]::ToBase64String([IO.File]::ReadAllBytes("C:\path\profil.mobileprovision"))
[Convert]::ToBase64String([IO.File]::ReadAllBytes("C:\path\ExportOptions.plist"))
```
