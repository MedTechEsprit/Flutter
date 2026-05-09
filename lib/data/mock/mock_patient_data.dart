import '../models/glucose_reading_model.dart';
import '../models/user_model.dart';
import '../models/message_model.dart';

class MockPatientData {
  static PatientModel getCurrentPatient() {
    return PatientModel(
      id: 'P001',
      name: 'Ahmed Benali',
      email: 'ahmed.benali@email.com',
      phone: '+216 55 123 456',
      age: 45,
      diabetesType: 'Type 2',
      bloodType: 'O+',
      status: 'Stable',
      emergencyContact: 'Fatma Benali - +216 55 789 012',
      diagnosisDate: DateTime(2020, 3, 15),
      currentGlucose: 125,
      hba1c: 6.8,
      bmi: 27.5,
      height: 175,
      weight: 84,
    );
  }

  static List<GlucoseReading> getGlucoseReadings() {
    final now = DateTime.now();
    return [
      GlucoseReading(id: 'G001', patientId: 'P001', value: 95, timestamp: now.subtract(const Duration(hours: 2)), type: 'fasting', source: 'glucometer'),
      GlucoseReading(id: 'G002', patientId: 'P001', value: 145, timestamp: now.subtract(const Duration(hours: 5)), type: 'after_meal', source: 'manual'),
      GlucoseReading(id: 'G003', patientId: 'P001', value: 110, timestamp: now.subtract(const Duration(hours: 10)), type: 'before_meal', source: 'glucometer'),
      GlucoseReading(id: 'G004', patientId: 'P001', value: 130, timestamp: now.subtract(const Duration(hours: 14)), type: 'bedtime', source: 'manual'),
      GlucoseReading(id: 'G005', patientId: 'P001', value: 88, timestamp: now.subtract(const Duration(days: 1, hours: 2)), type: 'fasting', source: 'glucometer'),
      GlucoseReading(id: 'G006', patientId: 'P001', value: 165, timestamp: now.subtract(const Duration(days: 1, hours: 5)), type: 'after_meal', source: 'manual'),
      GlucoseReading(id: 'G007', patientId: 'P001', value: 102, timestamp: now.subtract(const Duration(days: 1, hours: 10)), type: 'fasting', source: 'glucometer'),
      GlucoseReading(id: 'G008', patientId: 'P001', value: 155, timestamp: now.subtract(const Duration(days: 2, hours: 3)), type: 'after_meal', source: 'manual'),
      GlucoseReading(id: 'G009', patientId: 'P001', value: 92, timestamp: now.subtract(const Duration(days: 2, hours: 8)), type: 'fasting', source: 'glucometer'),
      GlucoseReading(id: 'G010', patientId: 'P001', value: 140, timestamp: now.subtract(const Duration(days: 3, hours: 4)), type: 'after_meal', source: 'manual'),
      GlucoseReading(id: 'G011', patientId: 'P001', value: 98, timestamp: now.subtract(const Duration(days: 3, hours: 10)), type: 'fasting', source: 'glucometer'),
      GlucoseReading(id: 'G012', patientId: 'P001', value: 178, timestamp: now.subtract(const Duration(days: 4, hours: 5)), type: 'after_meal', source: 'manual'),
      GlucoseReading(id: 'G013', patientId: 'P001', value: 105, timestamp: now.subtract(const Duration(days: 5, hours: 2)), type: 'fasting', source: 'glucometer'),
      GlucoseReading(id: 'G014', patientId: 'P001', value: 135, timestamp: now.subtract(const Duration(days: 6, hours: 6)), type: 'before_meal', source: 'manual'),
    ];
  }

  static List<GlucoseReading> getWeeklyReadings() {
    final now = DateTime.now();
    return List.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      return GlucoseReading(
        id: 'W${i + 1}',
        patientId: 'P001',
        value: 90 + (i * 8.0) + (i % 2 == 0 ? 15 : -5),
        timestamp: day,
        type: 'fasting',
        source: 'glucometer',
      );
    });
  }

  static List<DoctorModel> getAvailableDoctors() {
    return [
      DoctorModel(
        id: 'D001',
        name: 'Dr. Sarah Johnson',
        email: 'sarah.johnson@medical.com',
        phone: '+216 71 234 567',
        specialty: 'Diabétologue',
        license: 'MD-123456',
        hospital: 'Hôpital Central',
        isAvailable: true,
        totalPatients: 248,
        satisfactionRate: 89,
        yearsExperience: 12,
      ),
      DoctorModel(
        id: 'D002',
        name: 'Dr. Mohamed Karray',
        email: 'mohamed.karray@medical.com',
        phone: '+216 71 345 678',
        specialty: 'Endocrinologue',
        license: 'MD-234567',
        hospital: 'Clinique Les Oliviers',
        isAvailable: true,
        totalPatients: 180,
        satisfactionRate: 92,
        yearsExperience: 15,
      ),
      DoctorModel(
        id: 'D003',
        name: 'Dr. Amira Trabelsi',
        email: 'amira.trabelsi@medical.com',
        phone: '+216 71 456 789',
        specialty: 'Diabétologue',
        license: 'MD-345678',
        hospital: 'Hôpital Régional',
        isAvailable: false,
        totalPatients: 120,
        satisfactionRate: 95,
        yearsExperience: 8,
      ),
    ];
  }

  static List<PharmacyUserModel> getAvailablePharmacies() {
    return [
      PharmacyUserModel(
        id: 'PH001',
        name: 'Pharmacie Centrale',
        email: 'pharmacie.centrale@email.com',
        phone: '+216 71 123 456',
        address: '12 Rue de la République, Tunis',
        license: 'PH-001234',
        isOpen: true,
        rating: 4.7,
        totalReviews: 156,
      ),
      PharmacyUserModel(
        id: 'PH002',
        name: 'Pharmacie Ibn Sina',
        email: 'pharmacie.ibnsina@email.com',
        phone: '+216 71 234 567',
        address: '45 Avenue Habib Bourguiba, Tunis',
        license: 'PH-002345',
        isOpen: true,
        rating: 4.5,
        totalReviews: 98,
      ),
      PharmacyUserModel(
        id: 'PH003',
        name: 'Pharmacie du Lac',
        email: 'pharmacie.lac@email.com',
        phone: '+216 71 345 678',
        address: '8 Rue du Lac, Les Berges du Lac',
        license: 'PH-003456',
        isOpen: false,
        rating: 4.8,
        totalReviews: 220,
      ),
    ];
  }

  static List<ConversationModel> getConversations() {
    final now = DateTime.now();
    return [
      ConversationModel(
        id: 'C001',
        doctorId: 'D001',
        doctorName: 'Dr. Sarah Johnson',
        patientId: 'P001',
        patientName: 'Ahmed Benali',
        lastMessage: 'Vos résultats sont encourageants, continuez ainsi.',
        lastMessageTime: now.subtract(const Duration(hours: 2)),
        unreadCount: 1,
      ),
      ConversationModel(
        id: 'C002',
        doctorId: 'D002',
        doctorName: 'Dr. Mohamed Karray',
        patientId: 'P001',
        patientName: 'Ahmed Benali',
        lastMessage: 'N\'oubliez pas votre rendez-vous de demain.',
        lastMessageTime: now.subtract(const Duration(days: 1)),
        unreadCount: 0,
      ),
    ];
  }

  static List<MessageModel> getMessages(String conversationId) {
    final now = DateTime.now();
    return [
      MessageModel(id: 'M001', senderId: 'D001', receiverId: 'P001', content: 'Bonjour Ahmed, comment allez-vous aujourd\'hui ?', timestamp: now.subtract(const Duration(hours: 5)), isRead: true, senderName: 'Dr. Sarah Johnson'),
      MessageModel(id: 'M002', senderId: 'P001', receiverId: 'D001', content: 'Bonjour Docteur, je me sens bien. Mon glucose est stable.', timestamp: now.subtract(const Duration(hours: 4, minutes: 30)), isRead: true, senderName: 'Ahmed Benali'),
      MessageModel(id: 'M003', senderId: 'D001', receiverId: 'P001', content: 'Très bien ! J\'ai vu vos dernières mesures. Votre taux à jeun est excellent.', timestamp: now.subtract(const Duration(hours: 4)), isRead: true, senderName: 'Dr. Sarah Johnson'),
      MessageModel(id: 'M004', senderId: 'P001', receiverId: 'D001', content: 'Merci Docteur. J\'ai suivi le régime que vous m\'avez recommandé.', timestamp: now.subtract(const Duration(hours: 3)), isRead: true, senderName: 'Ahmed Benali'),
      MessageModel(id: 'M005', senderId: 'D001', receiverId: 'P001', content: 'Vos résultats sont encourageants, continuez ainsi.', timestamp: now.subtract(const Duration(hours: 2)), isRead: false, senderName: 'Dr. Sarah Johnson'),
    ];
  }

  static List<Map<String, dynamic>> getRecommendations(double currentGlucose) {
    final List<Map<String, dynamic>> recommendations = [];

    if (currentGlucose > 180) {
      recommendations.addAll([
        {'icon': '🚶', 'title': 'Activité physique', 'description': 'Faites une marche de 30 minutes pour aider à réduire votre glycémie.', 'priority': 'high'},
        {'icon': '💧', 'title': 'Hydratation', 'description': 'Buvez beaucoup d\'eau pour aider à éliminer le glucose excédentaire.', 'priority': 'high'},
        {'icon': '💊', 'title': 'Vérifiez vos médicaments', 'description': 'Assurez-vous d\'avoir pris vos médicaments selon la prescription.', 'priority': 'high'},
      ]);
    } else if (currentGlucose > 130) {
      recommendations.addAll([
        {'icon': '🥗', 'title': 'Alimentation équilibrée', 'description': 'Privilégiez les légumes verts et les protéines maigres au prochain repas.', 'priority': 'medium'},
        {'icon': '🏃', 'title': 'Activité légère', 'description': 'Une marche de 15 minutes après le repas aide à stabiliser la glycémie.', 'priority': 'medium'},
      ]);
    } else if (currentGlucose < 70) {
      recommendations.addAll([
        {'icon': '🍬', 'title': 'Sucre rapide', 'description': 'Prenez 15g de sucre rapide (jus de fruit, bonbon) immédiatement.', 'priority': 'critical'},
        {'icon': '⏰', 'title': 'Recontrôlez', 'description': 'Revérifiez votre glycémie dans 15 minutes.', 'priority': 'critical'},
      ]);
    } else {
      recommendations.addAll([
        {'icon': '✅', 'title': 'Glycémie normale', 'description': 'Votre glycémie est dans la plage cible. Continuez ainsi !', 'priority': 'normal'},
        {'icon': '🥦', 'title': 'Continuez vos bonnes habitudes', 'description': 'Maintenez une alimentation équilibrée et une activité régulière.', 'priority': 'normal'},
        {'icon': '📊', 'title': 'Suivi régulier', 'description': 'Continuez à mesurer votre glycémie régulièrement.', 'priority': 'normal'},
      ]);
    }

    return recommendations;
  }
}
