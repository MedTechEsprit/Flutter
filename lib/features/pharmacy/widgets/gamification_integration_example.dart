// 📋 INTEGRATION EXAMPLE - How to add gamification to pharmacy_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// ignore: unused_import
import 'package:diab_care/core/theme/app_colors.dart';
// ignore: unused_import
import 'package:diab_care/core/theme/app_text_styles.dart';
import 'package:diab_care/features/pharmacy/viewmodels/pharmacy_viewmodel.dart';
import 'package:diab_care/features/pharmacy/widgets/gamification_widgets.dart';
import 'package:diab_care/features/pharmacy/widgets/gamification_popups.dart';

/// Example: How to integrate gamification into existing pharmacy dashboard
class PharmacyDashboardGamificationExample extends StatefulWidget {
  const PharmacyDashboardGamificationExample({super.key});

  @override
  State<PharmacyDashboardGamificationExample> createState() =>
      _PharmacyDashboardGamificationExampleState();
}

class _PharmacyDashboardGamificationExampleState
    extends State<PharmacyDashboardGamificationExample> {
  final ScrollController _scrollController = ScrollController();
  bool _hasLoadedGamification = false;

  @override
  void initState() {
    super.initState();
  }

  void _loadGamificationIfNeeded(PharmacyViewModel viewModel) {
    if (!_hasLoadedGamification && viewModel.isLoggedIn) {
      _hasLoadedGamification = true;
      // 🎮 Load gamification data
      viewModel.loadGamificationData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PharmacyViewModel>(
      builder: (context, viewModel, child) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _loadGamificationIfNeeded(viewModel);
        });

        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          body: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              // ─── APP BAR ───
              SliverAppBar(
                expandedHeight: 100,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text('Dashboard Pharmacie'),
                ),
              ),

              // ─── MAIN CONTENT ───
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ────────────────────────────────────────
                      // 🎮 GAMIFICATION SECTION STARTS HERE
                      // ────────────────────────────────────────

                      // 1️⃣ Points and Badges Overview
                      if (viewModel.gamificationState == LoadingState.loaded &&
                          viewModel.pointsStats != null) ...[
                        PointsAndBadgesSection(
                          stats: viewModel.pointsStats!,
                        ),
                        const SizedBox(height: 16),
                      ] else if (viewModel.gamificationState == LoadingState.loading) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // 2️⃣ Badge Progress Bar
                      if (viewModel.gamificationState == LoadingState.loaded &&
                          viewModel.pointsStats != null &&
                          viewModel.badgeThresholds.isNotEmpty)
                        BadgeProgressBar(
                          currentPoints: viewModel.pointsStats!.currentPoints,
                          currentBadge: viewModel.currentBadge,
                          nextBadge: viewModel.nextBadge,
                          progress: viewModel.badgeProgress['progress'] as int? ?? 0,
                          pointsNeeded: viewModel.badgeProgress['pointsNeeded'] as int? ?? 0,
                        ),
                      const SizedBox(height: 16),

                      // 3️⃣ Unlocked Badges Grid
                      if (viewModel.gamificationState == LoadingState.loaded &&
                          viewModel.pointsStats != null)
                        UnlockedBadgesDisplay(
                          allBadges: viewModel.badgeThresholds,
                          unlockedBadges: viewModel.pointsStats!.unlockedBadges,
                        ),
                      const SizedBox(height: 16),

                      // 4️⃣ Ranking Card
                      if (viewModel.gamificationState == LoadingState.loaded &&
                          viewModel.ranking != null &&
                          viewModel.pointsStats != null)
                        RankingCard(
                          ranking: viewModel.ranking!,
                          stats: viewModel.pointsStats!.statistics,
                        ),

                      // ────────────────────────────────────────
                      // 🎮 GAMIFICATION SECTION ENDS HERE
                      // ────────────────────────────────────────
                      const SizedBox(height: 16),

                      // ... other dashboard sections ...
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ✅ EXAMPLE: How to show gamification pop-ups when responding
// ─────────────────────────────────────────────────────────────

class MedicationRequestActions {
  /// Example: Accept a medication request
  static Future<void> acceptRequest(
    BuildContext context,
    PharmacyViewModel viewModel, {
    required String requestId,
    required double indicativePrice,
    required String preparationDelay,
  }) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Call the ViewModel method
      final result = await viewModel.respondToMedicationRequest(
        requestId: requestId,
        status: 'accepted',
        indicativePrice: indicativePrice,
        preparationDelay: preparationDelay,
      );

      // Close loading dialog
      Navigator.of(context).pop();

      if (result['success']) {
        // 🎮 Show gamification pop-up
        showDialog(
          context: context,
          builder: (context) => GamificationPopup.accepted(
            basePoints: result['basePoints'] as int,
            bonusPoints: result['bonusPoints'] as int,
            responseTime: '${result['responseTime']} min',
            beforePoints: result['beforePoints'] as int,
            afterPoints: result['afterPoints'] as int,
            breakdown: List<String>.from(result['breakdown'] as List),
            onClose: () {
              // Refresh gamification data after pop-up closes
              viewModel.refreshGamificationData();
            },
          ),
        );

        // Show success snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Demande acceptée avec succès!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Show error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: ${result['error']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Exception: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Example: Mark medication as unavailable
  static Future<void> markUnavailable(
    BuildContext context,
    PharmacyViewModel viewModel, {
    required String requestId,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final result = await viewModel.respondToMedicationRequest(
        requestId: requestId,
        status: 'unavailable',
      );

      Navigator.of(context).pop();

      if (result['success']) {
        // 🎮 Show unavailable pop-up
        showDialog(
          context: context,
          builder: (context) => GamificationPopup.unavailable(
            points: result['pointsAwarded'] as int,
            beforePoints: result['beforePoints'] as int,
            afterPoints: result['afterPoints'] as int,
            onClose: () {
              viewModel.refreshGamificationData();
            },
          ),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⏸ Médicament marqué comme indisponible'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Example: Decline a medication request
  static Future<void> declineRequest(
    BuildContext context,
    PharmacyViewModel viewModel, {
    required String requestId,
    String? message,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final result = await viewModel.respondToMedicationRequest(
        requestId: requestId,
        status: 'declined',
        pharmacyMessage: message,
      );

      Navigator.of(context).pop();

      if (result['success']) {
        // 🎮 Show declined pop-up
        showDialog(
          context: context,
          builder: (context) => GamificationPopup.declined(
            beforePoints: result['beforePoints'] as int,
            afterPoints: result['afterPoints'] as int,
            onClose: () {
              viewModel.refreshGamificationData();
            },
          ),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✕ Demande refusée'),
            backgroundColor: Colors.grey,
          ),
        );
      }
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────
// ⭐ EXAMPLE: How to handle patient ratings
// ─────────────────────────────────────────────────────────────

class RatingHandler {
  /// Handle when a patient rates your pharmacy
  static Future<void> handlePatientRating(
    BuildContext context,
    PharmacyViewModel viewModel, {
    required String patientId,
    required String medicationRequestId,
    required int stars,
    String? comment,
    required bool medicationAvailable,
  }) async {
    try {
      final result = await viewModel.submitRating(
        patientId: patientId,
        medicationRequestId: medicationRequestId,
        stars: stars,
        comment: comment,
        medicationAvailable: medicationAvailable,
      );

      if (result['success']) {
        // 🎮 Show rating pop-up
        showDialog(
          context: context,
          builder: (context) => GamificationPopup.rating(
            stars: result['stars'] as int,
            points: result['pointsAwarded'] as int,
            beforePoints: result['beforePoints'] as int,
            afterPoints: result['afterPoints'] as int,
            onClose: () {
              viewModel.refreshGamificationData();
            },
          ),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⭐ Merci pour l\'évaluation!'),
            backgroundColor: Colors.amber,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────
// ⚠️ EXAMPLE: How to handle penalties
// ─────────────────────────────────────────────────────────────

class PenaltyHandler {
  /// Show penalty pop-up when rule violated
  static Future<void> showPenalty(
    BuildContext context, {
    required int penalty,
    required String reason,
    required int beforePoints,
    required int afterPoints,
  }) async {
    showDialog(
      context: context,
      builder: (context) => GamificationPopup.penalty(
        penalty: penalty,
        reason: reason,
        beforePoints: beforePoints,
        afterPoints: afterPoints,
        onClose: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 📝 USAGE IN EXISTING SCREENS
// ─────────────────────────────────────────────────────────────

/*
BEFORE: In pharmacy_requests_screen.dart, medication_request_tile.dart etc.

// Old way:
ElevatedButton(
  onPressed: () => acceptRequest(),
  child: Text('✓ Disponible'),
)

AFTER: With gamification

// New way:
ElevatedButton(
  onPressed: () => MedicationRequestActions.acceptRequest(
    context,
    viewModel,
    requestId: request.id,
    indicativePrice: 50.0,
    preparationDelay: 'immediate',
  ),
  child: Text('✓ Disponible'),
)

The pop-up will automatically show with points breakdown!
*/

