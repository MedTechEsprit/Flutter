# 🐛 GUIDE DE DÉBOGAGE - Dashboard Pharmacie

## ❌ PROBLÈMES IDENTIFIÉS

### 1. Dashboard affiche des 0 au lieu des vraies valeurs
**Symptôme vu dans screenshot:**
```
📥 Demandes reçues: 3
✅ Acceptées: 0  ← DEVRAIT ÊTRE 2
👥 Clients: 0
💰 Revenu: 0 TND  ← OK si pas de revenu
```

**Message d'avertissement:**
> "Les statistiques détaillées seront bientôt disponibles"

Cela indique que le dashboard est en **mode erreur** et affiche le fallback.

---

## 🔍 ÉTAPES DE DÉBOGAGE

### Étape 1: Vérifier la réponse du backend

Ouvrez la console Flutter et cherchez:
```
🔄 PharmacyDashboardService.loadDashboard() appelé
🌐 URL: http://10.0.2.2:3001/api/pharmaciens/{ID}/dashboard
📥 Status: 200
📊 Pharmacy points: ???  ← DOIT AFFICHER UN NOMBRE
📊 Total requests: ???
📊 Accepted: ???
📊 Declined: ???
```

**Si vous voyez des `null` ou `0` partout:**
→ Le backend ne retourne pas les bonnes données

**Si vous voyez des vrais chiffres:**
→ Le problème est dans le mapping Flutter

### Étape 2: Tester l'endpoint manuellement

```bash
# Windows PowerShell
$token = "VOTRE_TOKEN_JWT"
$pharmacyId = "69910c81599fdacc840728aa"

curl "http://10.0.2.2:3001/api/pharmaciens/$pharmacyId/dashboard" `
  -H "Authorization: Bearer $token" `
  -H "Content-Type: application/json"
```

**Réponse attendue:**
```json
{
  "pharmacy": {
    "_id": "69910c81599fdacc840728aa",
    "nomPharmacie": "Pharmacie Syrine Abid",
    "points": 45,  ← DOIT ÊTRE > 0
    "badgeLevel": "bronze",
    "totalRequestsReceived": 3,
    "totalRequestsAccepted": 2,  ← DOIT ÊTRE 2
    "totalRequestsDeclined": 1,
    "totalClients": 0,
    "totalRevenue": 0,
    "averageRating": 0,
    "averageResponseTime": 0
  },
  "stats": {
    "totalRequestsReceived": 3,
    "totalRequestsAccepted": 2,  ← IMPORTANT
    "totalRequestsDeclined": 1,
    "totalClients": 0,
    "totalRevenue": 0,
    "acceptanceRate": 66.67,
    "responseRate": 100,
    "averageResponseTime": 5
  },
  "pendingRequestsCount": 0,
  "badgeProgression": {
    "currentPoints": 45,
    "currentBadge": "bronze",
    "pointsToNextLevel": 5,
    "nextBadgeName": "silver"
  }
}
```

### Étape 3: Vérifier si le backend incrémente les compteurs

**Dans le backend, vérifier le code de `/respond`:**

```javascript
// Après acceptation d'une demande, le backend DOIT incrémenter:
await Pharmacien.findByIdAndUpdate(pharmacyId, {
  $inc: {
    totalRequestsReceived: 1,  // ou déjà fait à la création
    totalRequestsAccepted: 1,   // ← IMPORTANT
    points: pointsEarned
  }
});
```

**Si ce code n'existe pas → Le backend ne met PAS à jour les compteurs!**

---

## 🔧 SOLUTIONS

### Solution 1: Backend ne retourne pas les bonnes données

**Fichier backend à vérifier:** `controllers/pharmacienController.js`

```javascript
// GET /api/pharmaciens/:id/dashboard
exports.getDashboard = async (req, res) => {
  try {
    const pharmacyId = req.params.id;
    
    // IMPORTANT: Fetch avec les dernières données
    const pharmacy = await Pharmacien.findById(pharmacyId)
      .select('nom prenom email nomPharmacie points badgeLevel totalRequestsReceived totalRequestsAccepted totalRequestsDeclined totalClients totalRevenue averageRating averageResponseTime');
    
    if (!pharmacy) {
      return res.status(404).json({ message: 'Pharmacie non trouvée' });
    }
    
    // Log pour debug
    console.log('📊 Dashboard data:', {
      points: pharmacy.points,
      totalRequestsAccepted: pharmacy.totalRequestsAccepted,
      totalRequestsDeclined: pharmacy.totalRequestsDeclined
    });
    
    res.json({
      pharmacy: pharmacy,
      stats: {
        totalRequestsReceived: pharmacy.totalRequestsReceived || 0,
        totalRequestsAccepted: pharmacy.totalRequestsAccepted || 0,
        totalRequestsDeclined: pharmacy.totalRequestsDeclined || 0,
        totalClients: pharmacy.totalClients || 0,
        totalRevenue: pharmacy.totalRevenue || 0,
        acceptanceRate: pharmacy.totalRequestsReceived > 0 
          ? (pharmacy.totalRequestsAccepted / pharmacy.totalRequestsReceived * 100) 
          : 0,
        responseRate: 100,
        averageResponseTime: pharmacy.averageResponseTime || 0
      },
      pendingRequestsCount: await MedicationRequest.countDocuments({
        'pharmacyResponses.pharmacyId': pharmacyId,
        'pharmacyResponses.status': 'pending'
      }),
      badgeProgression: calculateBadgeProgression(pharmacy.points)
    });
  } catch (error) {
    console.error('❌ Error in getDashboard:', error);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};
```

### Solution 2: Backend n'incrémente pas les compteurs

**Fichier backend:** `controllers/medicationRequestController.js`

Dans la fonction `respondToRequest`:

```javascript
// Après avoir accepté/refusé une demande
if (status === 'accepted') {
  // Incrémenter les compteurs
  await Pharmacien.findByIdAndUpdate(pharmacyId, {
    $inc: {
      totalRequestsAccepted: 1,  // ← AJOUTER CECI
      points: pointsEarned
    }
  });
} else if (status === 'declined') {
  await Pharmacien.findByIdAndUpdate(pharmacyId, {
    $inc: {
      totalRequestsDeclined: 1,  // ← AJOUTER CECI
      points: 5  // Points pour avoir répondu
    }
  });
}
```

### Solution 3: Forcer le rafraîchissement dans Flutter

**Fichier:** `lib/features/pharmacy/viewmodels/pharmacy_viewmodel.dart`

```dart
/// Accepter une demande
Future<Map<String, dynamic>> acceptRequest({
  required String requestId,
  required double price,
  String? preparationDelay,
  String? message,
  DateTime? pickupDeadline,
}) async {
  debugPrint('✅ Accepting request $requestId with price $price');
  
  final result = await _requestService.respondToRequest(
    requestId: requestId,
    status: 'accepted',
    indicativePrice: price,
    preparationDelay: preparationDelay,
    pharmacyMessage: message,
    pickupDeadline: pickupDeadline,
  );

  if (result['success'] == true) {
    debugPrint('✅ Request accepted, refreshing ALL data...');
    
    // IMPORTANT: Attendre un peu pour que le backend mette à jour
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Recharger TOUT
    await loadDashboard();  // ← Doit recharger les stats
    await loadAllRequests();
    await loadActivityFeed();
    
    debugPrint('🎯 Refresh complete');
  }

  return result;
}
```

---

## 🧪 TESTS À FAIRE

### Test 1: Vérifier la DB MongoDB directement

```bash
# Connectez-vous à MongoDB
mongosh

# Utilisez la base de données
use diabcare

# Vérifiez les données de votre pharmacie
db.pharmaciens.findOne({ _id: ObjectId("69910c81599fdacc840728aa") })

# Vous devriez voir:
{
  "points": 45,  ← Doit être > 0
  "totalRequestsAccepted": 2,  ← Doit être 2
  "totalRequestsDeclined": 1,
  "totalRequestsReceived": 3
}
```

**Si ces champs sont à 0 dans la DB:**
→ Le backend n'incrémente PAS les compteurs lors de l'acceptation/rejet!

### Test 2: Accepter une demande et vérifier

1. **Ouvrez 2 terminaux**
   - Terminal 1: Backend avec logs
   - Terminal 2: Flutter avec logs

2. **Acceptez une demande**

3. **Vérifiez les logs backend:**
```
✅ Request accepted
📊 Incrementing pharmacy stats...
📊 New points: 45 → 55 (+10)
📊 Accepted count: 2 → 3
```

4. **Vérifiez les logs Flutter:**
```
✅ Request accepted, refreshing data...
📊 loadDashboard() appelé
📊 Pharmacy points: 55  ← Doit changer
📊 Accepted: 3  ← Doit augmenter
```

---

## 📋 CHECKLIST DE VÉRIFICATION

### Backend
- [ ] Endpoint `/dashboard` retourne les vraies données
- [ ] Champs `totalRequestsAccepted` et `totalRequestsDeclined` existent dans le schéma
- [ ] `/respond` incrémente `totalRequestsAccepted` après acceptation
- [ ] `/respond` incrémente `totalRequestsDeclined` après rejet
- [ ] `/respond` incrémente `points` correctement
- [ ] Les données dans MongoDB sont à jour

### Flutter
- [ ] `loadDashboard()` est appelé après acceptation
- [ ] Les logs montrent les bonnes valeurs reçues du backend
- [ ] Le ViewModel mappe correctement les données
- [ ] Le widget affiche les données du ViewModel
- [ ] Le rafraîchissement fonctionne (pull to refresh)

---

## 🎯 COMMANDES UTILES

### Réinitialiser les stats d'une pharmacie (pour test)
```javascript
// Dans MongoDB
db.pharmaciens.updateOne(
  { _id: ObjectId("69910c81599fdacc840728aa") },
  { 
    $set: {
      points: 0,
      totalRequestsReceived: 0,
      totalRequestsAccepted: 0,
      totalRequestsDeclined: 0,
      totalClients: 0,
      totalRevenue: 0
    }
  }
)
```

### Incrémenter manuellement (pour test)
```javascript
db.pharmaciens.updateOne(
  { _id: ObjectId("69910c81599fdacc840728aa") },
  { 
    $inc: {
      totalRequestsAccepted: 2,
      totalRequestsDeclined: 1,
      points: 30
    }
  }
)
```

### Vérifier les demandes acceptées par cette pharmacie
```javascript
db.medicationrequests.find({
  "pharmacyResponses.pharmacyId": "69910c81599fdacc840728aa",
  "pharmacyResponses.status": "accepted"
}).pretty()
```

---

## 🔍 LOGS ATTENDUS (COMPLET)

```
// Lors du chargement du dashboard
🔄 PharmacyDashboardService.loadDashboard() appelé
🔑 Token: Present (235 chars)
🆔 PharmacyId: 69910c81599fdacc840728aa
🌐 URL: http://10.0.2.2:3001/api/pharmaciens/69910c81599fdacc840728aa/dashboard
📥 Status: 200
📥 Response body length: 2500
✅ Dashboard chargé avec succès
📄 Data keys: [pharmacy, stats, monthlyStats, pendingRequestsCount, ...]
📊 Pharmacy points: 45  ← DOIT ÊTRE > 0
📊 Total requests: 3
📊 Accepted: 2  ← DOIT ÊTRE 2
📊 Declined: 1
✅ Model created successfully

// Après acceptation d'une demande
✅ Accepting request 673e1f7a8b with price 50
📡 API: PUT /medication-request/673e1f7a8b/respond
📥 Status: 200
✅ Request accepted, refreshing data...
🔄 PharmacyDashboardService.loadDashboard() appelé
📊 Pharmacy points: 55  ← DOIT AUGMENTER (+10)
📊 Accepted: 3  ← DOIT AUGMENTER (+1)
🎯 Refresh complete
```

---

## ❓ FAQ DÉBOGAGE

### Q: J'accepte des demandes mais les compteurs restent à 0
**R:** Le backend n'incrémente pas les compteurs. Ajoutez le code d'incrémentation dans `/respond`.

### Q: Le dashboard charge mais affiche 0 partout
**R:** Les données ne sont pas dans MongoDB. Le backend ne met pas à jour la collection `pharmaciens`.

### Q: Je vois "Les statistiques seront bientôt disponibles"
**R:** Le dashboard est en mode erreur. Vérifiez les logs pour voir l'exception.

### Q: Les points n'augmentent pas
**R:** Vérifiez que le backend calcule et incrémente les points dans `/respond`.

---

**💡 ASTUCE PRINCIPALE:**
Le problème est probablement dans le **BACKEND** qui ne met pas à jour les champs `totalRequestsAccepted` et `totalRequestsDeclined` lors de l'acceptation/rejet d'une demande!

Vérifiez le code backend dans `respondToRequest()` et assurez-vous qu'il fait un `$inc` sur ces champs.

