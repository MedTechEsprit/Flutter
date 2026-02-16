class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role; // 'patient', 'doctor', 'pharmacy'
  final String? avatarUrl;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.avatarUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: '${json['prenom'] ?? ''} ${json['nom'] ?? ''}'.trim(),
      email: json['email'] ?? '',
      phone: json['telephone'] ?? '',
      role: (json['role'] ?? 'patient').toString().toLowerCase(),
      avatarUrl: json['photoProfil'],
    );
  }
}

class PatientModel extends UserModel {
  final int age;
  final String diabetesType;
  final String bloodType;
  final String status;
  final String? emergencyContact;
  final DateTime? diagnosisDate;
  final double? currentGlucose;
  final double? hba1c;
  final double? bmi;
  final double? height;
  final double? weight;
  final String? nom;
  final String? prenom;
  final String? sexe;
  final DateTime? dateNaissance;
  final List<String>? allergies;
  final List<String>? maladiesChroniques;
  final double? objectifGlycemieMin;
  final double? objectifGlycemieMax;
  final String? traitementActuel;
  final String? typeInsuline;
  final int? frequenceInjection;
  final String? niveauActivitePhysique;

  PatientModel({
    required super.id,
    required super.name,
    required super.email,
    required super.phone,
    required this.age,
    required this.diabetesType,
    required this.bloodType,
    required this.status,
    this.emergencyContact,
    this.diagnosisDate,
    this.currentGlucose,
    this.hba1c,
    this.bmi,
    this.height,
    this.weight,
    this.nom,
    this.prenom,
    this.sexe,
    this.dateNaissance,
    this.allergies,
    this.maladiesChroniques,
    this.objectifGlycemieMin,
    this.objectifGlycemieMax,
    this.traitementActuel,
    this.typeInsuline,
    this.frequenceInjection,
    this.niveauActivitePhysique,
    super.avatarUrl,
  }) : super(role: 'patient');

  factory PatientModel.fromJson(Map<String, dynamic> json) {
    final dateNaissanceStr = json['dateNaissance'];
    DateTime? dateNaissance;
    int age = 0;
    if (dateNaissanceStr != null) {
      dateNaissance = DateTime.tryParse(dateNaissanceStr.toString());
      if (dateNaissance != null) {
        age = DateTime.now().difference(dateNaissance).inDays ~/ 365;
      }
    }

    final dateDiagStr = json['dateDiagnostic'];
    DateTime? diagnosisDate;
    if (dateDiagStr != null) {
      diagnosisDate = DateTime.tryParse(dateDiagStr.toString());
    }

    // Calcul IMC si taille et poids disponibles
    final taille = (json['taille'] as num?)?.toDouble();
    final poids = (json['poids'] as num?)?.toDouble();
    double? bmi;
    if (taille != null && taille > 0 && poids != null && poids > 0) {
      final tailleM = taille / 100;
      bmi = poids / (tailleM * tailleM);
      bmi = double.parse(bmi.toStringAsFixed(1));
    }

    // Mapper le type de diabète
    String diabetesType = '-';
    final td = json['typeDiabete'];
    if (td != null) {
      switch (td.toString()) {
        case 'TYPE_1':
          diabetesType = 'Type 1';
          break;
        case 'TYPE_2':
          diabetesType = 'Type 2';
          break;
        case 'GESTATIONNEL':
          diabetesType = 'Gestationnel';
          break;
        default:
          diabetesType = td.toString();
      }
    }

    return PatientModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: '${json['prenom'] ?? ''} ${json['nom'] ?? ''}'.trim(),
      email: json['email'] ?? '',
      phone: json['telephone'] ?? '',
      age: age,
      diabetesType: diabetesType,
      bloodType: json['groupeSanguin'] ?? '-',
      status: json['statutCompte'] == 'ACTIF' ? 'Stable' : 'Attention',
      emergencyContact: json['contactUrgence'],
      diagnosisDate: diagnosisDate,
      currentGlucose: (json['currentGlucose'] as num?)?.toDouble(),
      hba1c: (json['hba1c'] as num?)?.toDouble(),
      bmi: bmi,
      height: taille,
      weight: poids,
      nom: json['nom'],
      prenom: json['prenom'],
      sexe: json['sexe'],
      dateNaissance: dateNaissance,
      allergies: (json['allergies'] as List?)?.map((e) => e.toString()).toList(),
      maladiesChroniques: (json['maladiesChroniques'] as List?)?.map((e) => e.toString()).toList(),
      objectifGlycemieMin: (json['objectifGlycemieMin'] as num?)?.toDouble(),
      objectifGlycemieMax: (json['objectifGlycemieMax'] as num?)?.toDouble(),
      traitementActuel: json['traitementActuel'],
      typeInsuline: json['typeInsuline'],
      frequenceInjection: json['frequenceInjection'] as int?,
      niveauActivitePhysique: json['niveauActivitePhysique'],
      avatarUrl: json['photoProfil'],
    );
  }
}

class DoctorModel extends UserModel {
  final String specialty;
  final String license;
  final String hospital;
  final bool isAvailable;
  final int totalPatients;
  final double satisfactionRate;
  final int yearsExperience;
  final String? description;
  final double? tarifConsultation;

  DoctorModel({
    required super.id,
    required super.name,
    required super.email,
    required super.phone,
    required this.specialty,
    required this.license,
    required this.hospital,
    this.isAvailable = true,
    this.totalPatients = 0,
    this.satisfactionRate = 0.0,
    this.yearsExperience = 0,
    this.description,
    this.tarifConsultation,
    super.avatarUrl,
  }) : super(role: 'doctor');

  factory DoctorModel.fromJson(Map<String, dynamic> json) {
    return DoctorModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: 'Dr. ${json['prenom'] ?? ''} ${json['nom'] ?? ''}'.trim(),
      email: json['email'] ?? '',
      phone: json['telephone'] ?? '',
      specialty: json['specialite'] ?? 'Médecin',
      license: json['numeroOrdre'] ?? '',
      hospital: json['clinique'] ?? json['adresseCabinet'] ?? '',
      isAvailable: json['statutCompte'] == 'ACTIF',
      totalPatients: (json['listePatients'] as List?)?.length ?? 0,
      satisfactionRate: (json['noteMoyenne'] as num?)?.toDouble() ?? 0.0,
      yearsExperience: (json['anneesExperience'] as num?)?.toInt() ?? 0,
      description: json['description'],
      tarifConsultation: (json['tarifConsultation'] as num?)?.toDouble(),
      avatarUrl: json['photoProfil'],
    );
  }
}

class PharmacyUserModel extends UserModel {
  final String address;
  final String license;
  final bool isOpen;
  final double rating;
  final int totalReviews;
  final String? telephonePharmacie;

  PharmacyUserModel({
    required super.id,
    required super.name,
    required super.email,
    required super.phone,
    required this.address,
    required this.license,
    this.isOpen = true,
    this.rating = 0.0,
    this.totalReviews = 0,
    this.telephonePharmacie,
    super.avatarUrl,
  }) : super(role: 'pharmacy');

  factory PharmacyUserModel.fromJson(Map<String, dynamic> json) {
    return PharmacyUserModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['nomPharmacie'] ?? '${json['prenom'] ?? ''} ${json['nom'] ?? ''}'.trim(),
      email: json['email'] ?? '',
      phone: json['telephone'] ?? '',
      address: json['adressePharmacie'] ?? '',
      license: json['numeroOrdre'] ?? '',
      isOpen: json['statutCompte'] == 'ACTIF',
      rating: (json['noteMoyenne'] as num?)?.toDouble() ?? 0.0,
      totalReviews: 0,
      telephonePharmacie: json['telephonePharmacie'],
      avatarUrl: json['photoProfil'],
    );
  }
}
