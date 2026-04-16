# 🎮 GAMIFICATION SYSTEM - QUICK START GUIDE

## 📋 Summary of Implementation

Complete gamification system for the pharmacy module has been implemented with:
- ✅ 6 API endpoints integrated
- ✅ 14 data models created
- ✅ 1 complete service with helper methods
- ✅ 5 reusable UI widgets
- ✅ 5 pop-up variants
- ✅ ViewModel integration with full state management
- ✅ Example integration code

---

## 📂 Files Created/Modified

### NEW FILES (6)
```
✅ lib/data/models/gamification_models.dart
✅ lib/core/services/gamification_service.dart
✅ lib/features/pharmacy/widgets/gamification_widgets.dart
✅ lib/features/pharmacy/widgets/gamification_popups.dart
✅ lib/features/pharmacy/widgets/gamification_integration_example.dart
✅ GAMIFICATION_IMPLEMENTATION.md
```

### MODIFIED FILES (2)
```
✅ lib/core/constants/api_constants.dart
✅ lib/features/pharmacy/viewmodels/pharmacy_viewmodel.dart
```

---

## 🚀 Quick Integration Steps

### Step 1: Load Gamification Data in Dashboard
```dart
@override
void initState() {
  super.initState();
  viewModel.loadGamificationData();
}
```

### Step 2: Add Widgets to Dashboard
```dart
// In your CustomScrollView slivers:

// Points & Badges Overview
if (viewModel.pointsStats != null)
  PointsAndBadgesSection(stats: viewModel.pointsStats!),

// Badge Progress
if (viewModel.badgeThresholds.isNotEmpty)
  BadgeProgressBar(
    currentPoints: viewModel.pointsStats!.currentPoints,
    currentBadge: viewModel.currentBadge,
    nextBadge: viewModel.nextBadge,
    progress: viewModel.badgeProgress['progress'] ?? 0,
    pointsNeeded: viewModel.badgeProgress['pointsNeeded'] ?? 0,
  ),

// Unlocked Badges Grid
UnlockedBadgesDisplay(
  allBadges: viewModel.badgeThresholds,
  unlockedBadges: viewModel.pointsStats!.unlockedBadges,
),

// Ranking Card
RankingCard(
  ranking: viewModel.ranking!,
  stats: viewModel.pointsStats!.statistics,
),
```

### Step 3: Show Pop-ups on Actions
```dart
// When accepting a request:
final result = await viewModel.respondToMedicationRequest(
  requestId: requestId,
  status: 'accepted',
  indicativePrice: price,
  preparationDelay: delay,
);

if (result['success']) {
  showDialog(
    context: context,
    builder: (context) => GamificationPopup.accepted(
      basePoints: result['basePoints'],
      bonusPoints: result['bonusPoints'],
      responseTime: '${result['responseTime']} min',
      beforePoints: result['beforePoints'],
      afterPoints: result['afterPoints'],
      breakdown: result['breakdown'],
      onClose: () => viewModel.refreshGamificationData(),
    ),
  );
}
```

---

## 🎨 5 Widget Components

### 1. PointsAndBadgesSection
**Purpose**: Display current points and active badge  
**Location**: Top of dashboard  
**Shows**: Current points, badge emoji, description, today's earnings

### 2. BadgeProgressBar
**Purpose**: Visual progress to next badge  
**Location**: Below points section  
**Shows**: Current badge info, progress bar (0-100%), points needed for next

### 3. UnlockedBadgesDisplay
**Purpose**: Grid of all badge achievements  
**Location**: Middle of dashboard  
**Shows**: All 4 badges (locked/unlocked with checkmarks)

### 4. RankingCard
**Purpose**: Pharmacy position in ranking  
**Location**: Lower dashboard section  
**Shows**: Rank, percentile, acceptance rate, response time, avg rating

### 5. PointsEarnedDialog
**Purpose**: Animation popup showing points earned  
**Location**: Shows on top of screen after action  
**Shows**: Breakdown (base + bonus), before/after progression

---

## 🎯 5 Pop-up Types

### 1. Accepted (✓ Green)
**Trigger**: When `respondToMedicationRequest(status: 'accepted')`  
**Shows**: Base points + bonus breakdown, response time bonus explanation  
**Color**: Green (#4CAF50)

### 2. Unavailable (⏸ Orange)
**Trigger**: When `respondToMedicationRequest(status: 'unavailable')`  
**Shows**: +5 points for honesty + quick response  
**Color**: Orange (#FF9800)

### 3. Declined (✕ Gray)
**Trigger**: When `respondToMedicationRequest(status: 'declined')`  
**Shows**: No points message  
**Color**: Gray (#9E9E9E)

### 4. Rating (⭐ Amber)
**Trigger**: When `submitRating()` - patient rates pharmacy  
**Shows**: Stars count, bonus points earned  
**Color**: Amber (#FFC107)

### 5. Penalty (⚠️ Red)
**Trigger**: When rule violation or medication not found  
**Shows**: Penalty amount, reason for deduction  
**Color**: Red (#F44336)

---

## 🔌 ViewModel Methods Reference

### Gamification Methods
```dart
// Load all gamification data
await viewModel.loadGamificationData();

// Refresh data after action
await viewModel.refreshGamificationData();

// Respond to request (with auto pop-up calculation)
final result = await viewModel.respondToMedicationRequest(
  requestId: 'id',
  status: 'accepted|unavailable|declined',
  indicativePrice: 50.0,
  preparationDelay: 'immediate|30min|1h|2h',
  pharmacyMessage: 'optional',
  pickupDeadline: DateTime,
);

// Submit patient rating (with bonus pop-up)
final result = await viewModel.submitRating(
  patientId: 'id',
  medicationRequestId: 'id',
  stars: 1-5,
  comment: 'optional',
  medicationAvailable: true/false,
  speedRating: 1-5,
  courtesynRating: 1-5,
);
```

### Gamification Getters
```dart
// Current state
viewModel.gamificationState; // LoadingState
viewModel.pointsStats;       // PointsStatsResponse
viewModel.ranking;           // RankingResponse
viewModel.badgeThresholds;   // List<BadgeThreshold>
viewModel.pointsHistory;     // List<PointsHistoryItem>
viewModel.gamificationError; // String?

// Computed properties
viewModel.currentBadge;      // BadgeThreshold?
viewModel.nextBadge;         // BadgeThreshold?
viewModel.badgeProgress;     // Map with progress & pointsNeeded
```

---

## 📊 Data Flow Diagram

```
Dashboard Screen
      ↓
Call: viewModel.loadGamificationData()
      ↓
GamificationService.getPointsStats() ────→ PointsStatsResponse
GamificationService.getRanking()      ────→ RankingResponse
GamificationService.getBadgeThresholds() → List<BadgeThreshold>
GamificationService.getDailyHistory() ──→ List<PointsHistoryItem>
      ↓
Store in ViewModel state
      ↓
notifyListeners() → UI rebuilds
      ↓
Display: PointsAndBadgesSection
        BadgeProgressBar
        UnlockedBadgesDisplay
        RankingCard
```

### When User Takes Action:

```
User clicks "Accept Request"
      ↓
Call: viewModel.respondToMedicationRequest()
      ↓
GamificationService.respondToRequest() 
      ↓
API: PUT /medication-request/:id/respond
      ↓
Backend calculates points:
  - Base: +10
  - Bonus: +20 (if < 30min) = +30 total
      ↓
Response includes:
  {
    pointsAwarded: 30,
    basePoints: 10,
    bonusPoints: 20,
    reason: "Ultra-fast response"
  }
      ↓
ViewModel extracts and builds breakdown
      ↓
Show: GamificationPopup.accepted(
  basePoints: 10,
  bonusPoints: 20,
  breakdown: ["Base: +10", "Bonus: +20 (< 30 min)"],
  ...
)
      ↓
After 4 seconds or manual close:
      ↓
viewModel.refreshGamificationData()
      ↓
Update all UI with new points
```

---

## ⚙️ Configuration & Constants

### API Endpoints (in api_constants.dart)
```dart
static String pointsStats(String pharmacyId) 
  => '/pharmaciens/$pharmacyId/points/stats';

static String pointsRanking(String pharmacyId) 
  => '/pharmaciens/$pharmacyId/points/ranking';

static String pointsHistoryToday(String pharmacyId) 
  => '/pharmaciens/$pharmacyId/points/history/today';

static const String badgeThresholds 
  => '/pharmaciens/points/badges';

static const String createRating 
  => '/ratings';
```

### Auth Headers
All endpoints (except badgeThresholds) require:
```
Authorization: Bearer {token}
Content-Type: application/json
```

---

## 🧪 Testing Scenarios

### Scenario 1: Accept Request
1. Open medication request
2. Click "✓ Accept" button
3. Enter price, delay
4. Verify green pop-up shows with points
5. Verify dashboard points update
6. Verify badge progress updates

### Scenario 2: Mark Unavailable
1. Open medication request
2. Click "⏸ Unavailable" button
3. Verify orange pop-up shows +5 points
4. Verify dashboard updates

### Scenario 3: Decline Request
1. Open medication request
2. Click "✕ Decline" button
3. Verify gray pop-up shows no points
4. Verify no points added

### Scenario 4: Receive Rating
1. Patient rates pharmacy
2. Listen for rating notification
3. Verify amber pop-up shows bonus points
4. Verify dashboard points increase

### Scenario 5: Badge Unlock
1. Accumulate enough points for new badge
2. Next action should show new badge
3. Verify badge appears in UnlockedBadgesDisplay
4. Verify progress bar updates

---

## 🐛 Troubleshooting

### Pop-up doesn't show?
- Check viewModel.respondToMedicationRequest() returns success: true
- Verify GamificationService methods are called
- Check API response format matches models

### Points not updating?
- Call loadGamificationData() after action
- Check authHeaders are correct (Bearer token)
- Verify PharmacyId is not null

### Badge not unlocking?
- Check backend points calculation is correct
- Verify badgeThresholds are loaded
- Check currentBadge logic in ViewModel

### Ranking shows 0?
- Ensure getRanking() is called
- Check pharmacyId is passed correctly
- Verify API returns ranking data

---

## 🎯 Points System Reference

### Response Status → Points Calculation

**ACCEPTED (Médicament Disponible)**
- Base: +10 pts
- < 30 min: +20 bonus (Total: 30)
- 30-60 min: +15 bonus (Total: 25)
- 60-120 min: +5 bonus (Total: 15)
- > 120 min: 0 bonus (Total: 10)

**UNAVAILABLE (Non Disponible)**
- Always: +5 pts (honesty reward)

**DECLINED (Rejet)**
- Always: 0 pts

**RATING (Évaluation)**
- 5 stars: +25 pts
- 4 stars: +15 pts
- 3 stars: +5 pts
- 2 stars: 0 pts
- 1 star: -10 pts (PENALTY)

**PENALTY**
- Medication not found: -10 pts
- Low rating + not available: -10 pts additional

---

## 📈 Badge Levels Reference

| Badge | Emoji | Points | Description |
|-------|-------|--------|-------------|
| None | | 0-49 | Pas de badge |
| Fiable | ⭐ | 50-99 | Répond régulièrement |
| Réactif | 🔥 | 100-199 | Répond très rapidement |
| Excellence | 👑 | 200+ | Pharmacie de premier choix |

---

## 📞 Support

For issues:
1. Check GAMIFICATION_IMPLEMENTATION.md for full docs
2. Review gamification_integration_example.dart for code samples
3. Verify all imports are correct
4. Check ViewModel state with debugPrint logs
5. Test API endpoints with Postman first

---

**✅ Implementation Status**: COMPLETE & READY FOR TESTING  
**🎮 Pharmacy Module**: ONLY affected module  
**👥 Patient/Doctor**: UNTOUCHED  
**📱 Real-time**: YES - Auto refresh after actions  
**🔐 Authentication**: Required (Bearer token)

