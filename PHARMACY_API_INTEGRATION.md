# 🏥 DiabCare - Intégration API Pharmacie

## ✅ Corrections effectuées

### 1. Configuration réseau pour émulateur Android
- **Fichier:** `lib/core/constants/api_constants.dart`
- **URL:** `http://10.0.2.2:3001/api` (pointe vers localhost de la machine hôte)
- **Permission Internet:** Ajoutée dans `AndroidManifest.xml`
- **Cleartext Traffic:** Autorisé pour le développement

### 2. Authentification de la pharmacie
- **Service:** `lib/features/pharmacy/services/pharmacy_auth_service.dart`
- **Endpoint:** `POST /auth/login`
- **Stockage sécurisé:** JWT token et pharmacy ID via `flutter_secure_storage`
- **Logs de débogage:** Ajoutés pour faciliter le diagnostic

### 3. Dashboard de la pharmacie
- **Service:** `lib/features/pharmacy/services/pharmacy_dashboard_service.dart`
- **Endpoint:** `GET /pharmaciens/{pharmacyId}/dashboard`
- **ViewModel:** `lib/features/pharmacy/viewmodels/pharmacy_viewmodel.dart`
- **Écran:** `lib/features/pharmacy/views/pharmacy_dashboard_screen.dart`
- **Chargement automatique:** Le dashboard se charge après le login

### 4. Profil de la pharmacie
- **Écran:** `lib/features/pharmacy/views/pharmacy_profile_screen.dart`
- **Données affichées:**
  - Nom de la pharmacie (`nomPharmacie`)
  - Email
  - Téléphone (`telephonePharmacie`)
  - Adresse (`adressePharmacie`)
  - Numéro d'ordre (`numeroOrdre`)
  - Statut du compte (`statutCompte`)
  - Badge level
  - Note moyenne et nombre d'avis
  - Statistiques (total demandes, acceptées, taux d'acceptation, temps de réponse)

### 5. Gestion des demandes de médicaments
- **Service:** `lib/features/pharmacy/services/medication_request_service.dart`
- **Endpoints:**
  - `GET /medication-request/pharmacy/{pharmacyId}/pending` - Demandes en attente
  - `GET /medication-request/pharmacy/{pharmacyId}/history` - Historique
  - `PUT /medication-request/{requestId}/respond` - Répondre (accepter/refuser)
  - `PUT /medication-request/{requestId}/pickup` - Marquer comme retiré

---

## 🚀 Comment tester

### Prérequis
1. **Backend NestJS démarré** sur le port 3001
2. **Émulateur Android** Pixel 8 Pro lancé
3. **Flutter** installé et configuré

### Étapes

#### 1. Démarrer le backend NestJS
```bash
cd chemin/vers/votre/backend
npm run start:dev
```

Vérifiez que vous voyez :
```
Application is running on: http://localhost:3001
```

#### 2. Tester que le backend fonctionne
Ouvrez un navigateur : `http://localhost:3001/api/docs`
Vous devriez voir la documentation Swagger.

#### 3. Lancer l'application Flutter
```bash
cd "C:\Users\cyrin\Downloads\Flutter-main (1)\Flutter-main"
flutter run
```

#### 4. Se connecter en tant que pharmacie

**Sur l'écran de sélection de rôle:**
- Sélectionner "Pharmacien"

**Sur l'écran de connexion:**
- **Email:** `pharmacie.centrale@diabcare.tn`
- **Mot de passe:** `password123`

#### 5. Vérifier les fonctionnalités

**Dashboard (Premier écran après login) :**
- ✅ Statistiques affichées (total demandes, acceptées, clients, revenu)
- ✅ Graphiques d'évolution
- ✅ Badges et niveaux
- ✅ Performance comparée au secteur
- ✅ Activité récente
- ✅ Derniers avis

**Demandes (Deuxième onglet) :**
- ✅ Liste des demandes en attente
- ✅ Onglets : En attente, Acceptées, Refusées, Expirées
- ✅ Accepter une demande avec prix et délai
- ✅ Refuser une demande
- ✅ Empty state si aucune demande

**Profil (Troisième onglet) :**
- ✅ Nom de la pharmacie affiché
- ✅ Email affiché
- ✅ Téléphone affiché
- ✅ Adresse affichée
- ✅ Numéro d'ordre affiché
- ✅ Badge level avec emoji
- ✅ Note moyenne et nombre d'avis
- ✅ Statistiques rapides
- ✅ Déconnexion

---

## 📊 Logs de débogage

Lors de la connexion, vous verrez dans la console Flutter :

```
🔐 ========== TENTATIVE DE CONNEXION PHARMACIE ==========
📍 URL: http://10.0.2.2:3001/api/auth/login
📧 Email: pharmacie.centrale@diabcare.tn
🔑 Password length: 11
📤 Request body: {"email":"pharmacie.centrale@diabcare.tn","motDePasse":"password123"}
📥 Status code: 200
📥 Response body: {"access_token":"eyJhbGci...","user":{...}}
✅ CONNEXION RÉUSSIE! Pharmacy ID: 69910805fa9cb3ec5e0e95cd
```

---

## ⚠️ Dépannage

### Erreur "Impossible de se connecter au serveur"

**Vérifiez:**
1. Le backend est démarré : `npm run start:dev`
2. Le backend tourne sur `http://localhost:3001`
3. Vous utilisez un **émulateur Android** (pas un appareil physique)

### Erreur "Session expirée"

**Solution:** Le token JWT a expiré. Reconnectez-vous simplement.

### Erreur "Email ou mot de passe incorrect"

**Vérifiez:**
- Email exact : `pharmacie.centrale@diabcare.tn`
- Mot de passe exact : `password123`
- Le compte existe dans MongoDB

### Dashboard vide ou erreur de chargement

**Vérifiez:**
1. Vous êtes bien connecté (token stocké)
2. Le backend répond sur `/pharmaciens/{id}/dashboard`
3. Les logs de débogage dans la console Flutter

### Empty state sur les demandes

C'est **normal** s'il n'y a pas de demandes en cours dans la base de données.

Pour créer des demandes de test :
```bash
cd chemin/vers/backend
node scripts/create-request-for-pharmacy.js
```

---

## 📁 Structure des fichiers modifiés

```
lib/
├── core/
│   └── constants/
│       └── api_constants.dart ✅ URL configurée pour émulateur
├── features/
│   ├── auth/
│   │   ├── viewmodels/
│   │   │   └── auth_viewmodel.dart ✅ Login API pharmacie
│   │   └── views/
│   │       └── login_screen.dart ✅ Initialisation PharmacyViewModel
│   └── pharmacy/
│       ├── models/
│       │   └── pharmacy_api_models.dart ✅ Modèles API
│       ├── services/
│       │   ├── pharmacy_auth_service.dart ✅ Login & JWT storage
│       │   ├── pharmacy_dashboard_service.dart ✅ Dashboard API
│       │   └── medication_request_service.dart ✅ Demandes API
│       ├── viewmodels/
│       │   └── pharmacy_viewmodel.dart ✅ État & logique
│       └── views/
│           ├── pharmacy_dashboard_screen.dart ✅ Dashboard UI
│           ├── pharmacy_requests_screen.dart ✅ Demandes UI
│           └── pharmacy_profile_screen.dart ✅ Profil UI

android/
└── app/
    └── src/
        └── main/
            └── AndroidManifest.xml ✅ Permissions Internet + Cleartext

pubspec.yaml ✅ Dépendances ajoutées (flutter_secure_storage, http)
```

---

## 🔐 Données de test

### Compte pharmacie
```
Email: pharmacie.centrale@diabcare.tn
Mot de passe: password123
```

### Autres comptes de test (si disponibles)
Vérifiez la base de données MongoDB ou le guide d'API pour plus de comptes.

---

## 📝 Notes importantes

1. **Émulateur uniquement:** L'URL `10.0.2.2` ne fonctionne que sur l'émulateur Android
2. **Appareil physique:** Si vous testez sur un vrai appareil, modifiez `api_constants.dart` avec l'IP de votre PC
3. **Backend requis:** L'application NE FONCTIONNE PAS sans le backend NestJS démarré
4. **Token JWT:** Stocké de manière sécurisée via `flutter_secure_storage`
5. **Déconnexion:** Efface le token et les données stockées

---

## ✨ Fonctionnalités implémentées

- ✅ Login pharmacie avec API réelle
- ✅ Stockage sécurisé JWT token
- ✅ Dashboard complet avec API
- ✅ Liste des demandes en attente
- ✅ Accepter/Refuser des demandes
- ✅ Historique des demandes
- ✅ Profil avec données réelles de l'API
- ✅ Déconnexion
- ✅ Gestion des erreurs réseau
- ✅ Gestion session expirée (401)
- ✅ Empty states
- ✅ Pull-to-refresh

---

**Dernière mise à jour:** 15 février 2026  
**Version Flutter:** Compatible avec Flutter 3.x  
**Version Backend:** Compatible avec NestJS 1.0.0

