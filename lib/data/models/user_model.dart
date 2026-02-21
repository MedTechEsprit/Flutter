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
  final String status; // 'Stable', 'Attention', 'Critical'
  final String? emergencyContact;
  final DateTime? diagnosisDate;
  final double? currentGlucose;
  final double? hba1c;
  final double? bmi;
  final double? height;
  final double? weight;

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
  }) : super(role: 'patient');
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
