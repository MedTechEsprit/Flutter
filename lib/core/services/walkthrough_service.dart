import 'package:diab_care/core/services/token_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppUserRole { patient, doctor, pharmacy }

class WalkthroughStepData {
  final String title;
  final String description;
  final String tabLabel;

  const WalkthroughStepData({
    required this.title,
    required this.description,
    required this.tabLabel,
  });
}

class WalkthroughService {
  WalkthroughService._();

  static final WalkthroughService instance = WalkthroughService._();
  static const String _pendingKeyPrefix = 'walkthrough_pending';

  Future<void> markPendingAfterRegistration(AppUserRole role) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _pendingKeyForRole(role);
    await prefs.setBool(key, true);
  }

  Future<bool> consumePendingAfterRegistration(AppUserRole role) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _pendingKeyForRole(role);
    final isPending = prefs.getBool(key) ?? false;
    if (!isPending) return false;

    await prefs.setBool(key, false);
    return true;
  }

  Future<String> _pendingKeyForRole(AppUserRole role) async {
    final tokenService = TokenService();
    final userId = tokenService.userId ?? await tokenService.getUserId();
    final suffix = userId != null && userId.isNotEmpty
        ? '${role.name}_$userId'
        : role.name;
    return '$_pendingKeyPrefix.$suffix';
  }

  String roleTitle(AppUserRole role) {
    switch (role) {
      case AppUserRole.patient:
        return 'Espace Patient';
      case AppUserRole.doctor:
        return 'Espace Medecin';
      case AppUserRole.pharmacy:
        return 'Espace Pharmacien';
    }
  }

  List<WalkthroughStepData> stepsForRole(AppUserRole role) {
    switch (role) {
      case AppUserRole.patient:
        return const [
          WalkthroughStepData(
            title: 'Suivi glycemique intelligent',
            description:
                'Enregistrez vos mesures, visualisez les tendances et reperez rapidement les variations importantes.',
            tabLabel: 'Accueil',
          ),
          WalkthroughStepData(
            title: 'Nutrition et repas',
            description:
                'Ajoutez vos repas, consultez vos historiques et suivez votre impact alimentaire au quotidien.',
            tabLabel: 'Nutrition',
          ),
          WalkthroughStepData(
            title: 'Fonctions IA patient',
            description:
                'Utilisez le hub IA pour le chat sante, l\'analyse alimentaire, les predictions et la detection de patterns.',
            tabLabel: 'IA',
          ),
          WalkthroughStepData(
            title: 'Lien avec les medecins',
            description:
                'Trouvez des medecins, echangez via messages et suivez vos demandes de prise en charge.',
            tabLabel: 'Medecins',
          ),
          WalkthroughStepData(
            title: 'Pharmacies et traitements',
            description:
                'Localisez des pharmacies proches, gerez vos demandes de medicaments et suivez votre profil medical.',
            tabLabel: 'Pharmacies / Profil',
          ),
        ];
      case AppUserRole.doctor:
        return const [
          WalkthroughStepData(
            title: 'Vue clinique globale',
            description:
                'Le tableau de bord vous donne une vue rapide sur votre activite et les signaux importants.',
            tabLabel: 'Accueil',
          ),
          WalkthroughStepData(
            title: 'Gestion des patients',
            description:
                'Consultez vos patients, leurs donnees et les demandes d\'acces pour un suivi structure.',
            tabLabel: 'Patients',
          ),
          WalkthroughStepData(
            title: 'Messagerie medicale',
            description:
                'Communiquez avec vos patients et gardez une trace des echanges cliniques utiles.',
            tabLabel: 'Messages',
          ),
          WalkthroughStepData(
            title: 'Agenda des consultations',
            description:
                'Organisez les rendez-vous, validez les creneaux et suivez votre planning medical.',
            tabLabel: 'Agenda',
          ),
          WalkthroughStepData(
            title: 'Outils experts',
            description:
                'Depuis votre espace medecin, accedez aux fonctions IA docteur et au boost de visibilite.',
            tabLabel: 'Profil',
          ),
        ];
      case AppUserRole.pharmacy:
        return const [
          WalkthroughStepData(
            title: 'Pilotage de la pharmacie',
            description:
                'Le dashboard centralise vos stats, activites et indicateurs essentiels.',
            tabLabel: 'Accueil',
          ),
          WalkthroughStepData(
            title: 'Demandes de medicaments',
            description:
                'Traitez les demandes patients, acceptez ou refusez et mettez a jour les statuts de preparation.',
            tabLabel: 'Demandes',
          ),
          WalkthroughStepData(
            title: 'Communication patient',
            description:
                'Repondez rapidement via le chat pour fluidifier le parcours de soin et de livraison.',
            tabLabel: 'Chat',
          ),
          WalkthroughStepData(
            title: 'Gamification et points',
            description:
                'Ameliorez votre engagement avec le systeme de points, classement et badges pharmacie.',
            tabLabel: 'Accueil / Stats',
          ),
          WalkthroughStepData(
            title: 'Profil professionnel',
            description:
                'Mettez a jour vos informations, disponibilite et donnees visibles par les patients.',
            tabLabel: 'Profil',
          ),
        ];
    }
  }
}
