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

  // ── New medical fields ─────────────────────────────────────────
  final double? glycemieAJeunMoyenne;
  final String? frequenceMesureGlycemie;
  final bool prendInsuline;
  final String? typeInsuline;
  final double? doseQuotidienneInsuline;
  final int? frequenceInjection;
  final List<String> antidiabetiquesOraux;
  final List<String> traitements;
  final bool utiliseCapteurGlucose;
  final bool antecedentsFamiliauxDiabete;
  final bool hypertension;
  final bool maladiesCardiovasculaires;
  final bool problemesRenaux;
  final bool problemesOculaires;
  final bool neuropathieDiabetique;
  final bool piedDiabetique;
  final bool ulceres;
  final bool hypoglycemiesFrequentes;
  final bool hyperglycemiesFrequentes;
  final bool hospitalisationsRecentes;
  final double? cholesterolTotal;
  final double? hdl;
  final double? ldl;
  final double? triglycerides;
  final double? creatinine;
  final double? microAlbuminurie;
  final List<String> allergies;
  final List<String> maladiesChroniques;
  final String? niveauActivitePhysique;
  final String? habitudesAlimentaires;
  final String? tabac;
  final bool profilMedicalComplete;

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
    super.avatarUrl,
    // new
    this.glycemieAJeunMoyenne,
    this.frequenceMesureGlycemie,
    this.prendInsuline = false,
    this.typeInsuline,
    this.doseQuotidienneInsuline,
    this.frequenceInjection,
    this.antidiabetiquesOraux = const [],
    this.traitements = const [],
    this.utiliseCapteurGlucose = false,
    this.antecedentsFamiliauxDiabete = false,
    this.hypertension = false,
    this.maladiesCardiovasculaires = false,
    this.problemesRenaux = false,
    this.problemesOculaires = false,
    this.neuropathieDiabetique = false,
    this.piedDiabetique = false,
    this.ulceres = false,
    this.hypoglycemiesFrequentes = false,
    this.hyperglycemiesFrequentes = false,
    this.hospitalisationsRecentes = false,
    this.cholesterolTotal,
    this.hdl,
    this.ldl,
    this.triglycerides,
    this.creatinine,
    this.microAlbuminurie,
    this.allergies = const [],
    this.maladiesChroniques = const [],
    this.niveauActivitePhysique,
    this.habitudesAlimentaires,
    this.tabac,
    this.profilMedicalComplete = false,
  }) : super(role: 'patient');

  factory PatientModel.fromJson(Map<String, dynamic> json) {
    final nom = json['nom']?.toString() ?? '';
    final prenom = json['prenom']?.toString() ?? '';
    final fullName = '$prenom $nom'.trim();

    // Medical sub-document
    final med = (json['profilMedical'] as Map<String, dynamic>?) ?? {};

    // Compute height/weight/bmi from sub-document
    final taille = _toDouble(med['taille']);
    final poids = _toDouble(med['poids']);
    double? bmi;
    if (taille != null && taille > 0 && poids != null && poids > 0) {
      bmi = poids / ((taille / 100) * (taille / 100));
    }

    // Compute age from dateNaissance (root level)
    int age = 0;
    if (json['dateNaissance'] != null) {
      final dob = DateTime.tryParse(json['dateNaissance'].toString());
      if (dob != null) {
        age = DateTime.now().difference(dob).inDays ~/ 365;
      }
    }

    // Map diabetes type for display (root level)
    String diabetesType = '-';
    final td = json['typeDiabete']?.toString() ?? '';
    if (td == 'TYPE_1') diabetesType = 'Type 1';
    else if (td == 'TYPE_2') diabetesType = 'Type 2';
    else if (td == 'GESTATIONNEL') diabetesType = 'Gestationnel';
    else if (td == 'PRE_DIABETE') diabetesType = 'Pré-diabète';
    else if (td == 'AUTRE') diabetesType = 'Autre';
    else if (td.isNotEmpty) diabetesType = td;

    return PatientModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: fullName.isNotEmpty ? fullName : 'Patient',
      email: json['email']?.toString() ?? '',
      phone: json['telephone']?.toString() ?? '',
      age: age,
      diabetesType: diabetesType,
      bloodType: json['groupeSanguin']?.toString() ?? '-',
      status: 'Stable',
      emergencyContact: med['contactUrgence']?.toString(),
      diagnosisDate: med['dateDiagnostic'] != null ? DateTime.tryParse(med['dateDiagnostic'].toString()) : null,
      hba1c: _toDouble(med['dernierHba1c']),
      bmi: bmi,
      height: taille,
      weight: poids,
      glycemieAJeunMoyenne: _toDouble(med['glycemieAJeunMoyenne']),
      frequenceMesureGlycemie: med['frequenceMesureGlycemie']?.toString(),
      prendInsuline: med['prendInsuline'] == true,
      typeInsuline: med['typeInsuline']?.toString(),
      doseQuotidienneInsuline: _toDouble(med['doseQuotidienneInsuline']),
      frequenceInjection: _toInt(med['frequenceInjection']),
      antidiabetiquesOraux: _toStringList(med['antidiabetiquesOraux']),
      traitements: _toStringList(med['traitements']),
      utiliseCapteurGlucose: med['utiliseCapteurGlucose'] == true,
      antecedentsFamiliauxDiabete: med['antecedentsFamiliauxDiabete'] == true,
      hypertension: med['hypertension'] == true,
      maladiesCardiovasculaires: med['maladiesCardiovasculaires'] == true,
      problemesRenaux: med['problemesRenaux'] == true,
      problemesOculaires: med['problemesOculaires'] == true,
      neuropathieDiabetique: med['neuropathieDiabetique'] == true,
      piedDiabetique: med['piedDiabetique'] == true,
      ulceres: med['ulceres'] == true,
      hypoglycemiesFrequentes: med['hypoglycemiesFrequentes'] == true,
      hyperglycemiesFrequentes: med['hyperglycemiesFrequentes'] == true,
      hospitalisationsRecentes: med['hospitalisationsRecentes'] == true,
      cholesterolTotal: _toDouble(med['cholesterolTotal']),
      hdl: _toDouble(med['hdl']),
      ldl: _toDouble(med['ldl']),
      triglycerides: _toDouble(med['triglycerides']),
      creatinine: _toDouble(med['creatinine']),
      microAlbuminurie: _toDouble(med['microAlbuminurie']),
      allergies: _toStringList(med['allergies']),
      maladiesChroniques: _toStringList(med['maladiesChroniques']),
      niveauActivitePhysique: med['niveauActivitePhysique']?.toString(),
      habitudesAlimentaires: med['habitudesAlimentaires']?.toString(),
      tabac: med['tabac']?.toString(),
      profilMedicalComplete: med['profilMedicalComplete'] == true,
    );
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  static List<String> _toStringList(dynamic v) {
    if (v is List) return v.map((e) => e.toString()).toList();
    return [];
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
    super.avatarUrl,
  }) : super(role: 'doctor');
}

class PharmacyUserModel extends UserModel {
  final String address;
  final String license;
  final bool isOpen;
  final double rating;
  final int totalReviews;

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
    super.avatarUrl,
  }) : super(role: 'pharmacy');
}
