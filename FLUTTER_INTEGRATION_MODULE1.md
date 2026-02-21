# Flutter Integration Guide - Module 1: Appointments

## ✅ Backend Status: Waiting for Copilot to Complete

Once your NestJS backend Module 1 is generated and tested, follow these steps to integrate with Flutter.

---

## 📦 Files Created for You

I've already created these files in your Flutter project:

### 1. **Appointment Model**
**Location:** `lib/data/models/appointment_model.dart`

✅ Complete data model with:
- All fields from backend (id, patientId, doctorId, dateTime, type, status, notes)
- `fromJson()` and `toJson()` methods
- Helper methods (formattedDate, formattedTime, statusColor, typeIcon)
- `copyWith()` method for updates

### 2. **Appointment Service**
**Location:** `lib/data/services/appointment_service.dart`

✅ All 6 API endpoints implemented:
- `createAppointment()` - POST /api/appointments
- `getDoctorAppointments()` - GET /api/doctors/:doctorId/appointments
- `getPatientAppointments()` - GET /api/patients/:patientId/appointments
- `getAppointmentById()` - GET /api/appointments/:id
- `updateAppointment()` - PATCH /api/appointments/:id
- `deleteAppointment()` - DELETE /api/appointments/:id

✅ Bonus helper methods:
- `confirmAppointment()` - Quick confirm
- `cancelAppointment()` - Quick cancel
- `completeAppointment()` - Quick complete
- `getTodayAppointments()` - Get today's appointments
- `getUpcomingAppointments()` - Get future appointments

### 3. **Integration Examples**
**Location:** `lib/examples/appointment_integration_examples.dart`

✅ Complete working examples:
- Create appointment screen with date/time picker
- Doctor's appointments list with filters
- Appointment card widget
- Status update buttons
- Quick integration snippets for existing screens

---

## 🔧 Setup Required

### Step 1: Update Base URL

In `lib/data/services/appointment_service.dart`, update line 11:

```dart
static const String baseUrl = 'http://10.0.2.2:3000'; // Android Emulator
```

Change to:
- **Android Emulator:** `http://10.0.2.2:3000`
- **iOS Simulator:** `http://localhost:3000`
- **Real Device:** `http://YOUR_COMPUTER_IP:3000` (e.g., `http://192.168.1.100:3000`)
- **Production:** `https://your-api.com`

### Step 2: Connect Auth Token

In `lib/data/services/appointment_service.dart`, update the `_getToken()` method (lines 16-21):

```dart
Future<String?> _getToken() async {
  // Replace this with your existing auth token retrieval
  // Example from your existing auth service:
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('jwt_token');
  
  // Or if you have a secure storage:
  // return await SecureStorage.read(key: 'jwt_token');
}
```

**Find your existing token storage** - You likely have this in:
- `lib/features/auth/services/auth_service.dart`
- Or wherever you store the JWT after login

---

## 🚀 Integration Steps

### Quick Integration in Doctor Dashboard

**File:** `lib/features/doctor/views/doctor_dashboard_screen.dart`

**Add these imports:**
```dart
import 'package:diab_care/data/services/appointment_service.dart';
import 'package:diab_care/data/models/appointment_model.dart';
```

**Add to your state class:**
```dart
final _appointmentService = AppointmentService();
List<AppointmentModel> _appointments = [];
bool _isLoadingAppointments = false;
```

**Load appointments (in initState or build):**
```dart
Future<void> _loadAppointments() async {
  setState(() => _isLoadingAppointments = true);
  
  try {
    final appointments = await _appointmentService.getDoctorAppointments(
      doctorId, // Your doctor's ID
      status: 'Confirmed', // Optional filter
    );
    
    setState(() {
      _appointments = appointments;
      _isLoadingAppointments = false;
    });
  } catch (e) {
    setState(() => _isLoadingAppointments = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  }
}
```

**Display in your UI:**
```dart
// Show today's appointment count
Text('${_appointments.length} appointments today'),

// Or show a list
ListView.builder(
  itemCount: _appointments.length,
  itemBuilder: (context, index) {
    final apt = _appointments[index];
    return ListTile(
      leading: Text(apt.typeIcon),
      title: Text(apt.patientName),
      subtitle: Text(apt.formattedTime),
      trailing: Chip(label: Text(apt.status)),
      onTap: () {
        // Navigate to appointment details
      },
    );
  },
)
```

---

## 🧪 Testing Steps

### 1. Test Backend First (with Postman/Thunder Client)

Before integrating with Flutter, test your backend:

```bash
# Test 1: Create Appointment
POST http://localhost:3000/api/appointments
Authorization: Bearer YOUR_JWT_TOKEN
Content-Type: application/json

{
  "patientId": "PATIENT_ID_FROM_MONGODB",
  "doctorId": "DOCTOR_ID_FROM_MONGODB",
  "dateTime": "2024-02-25T10:00:00Z",
  "type": "Online",
  "notes": "Test appointment"
}

# Test 2: Get Doctor Appointments
GET http://localhost:3000/api/doctors/DOCTOR_ID/appointments
Authorization: Bearer YOUR_JWT_TOKEN

# Test 3: Get Patient Appointments
GET http://localhost:3000/api/patients/PATIENT_ID/appointments
Authorization: Bearer YOUR_JWT_TOKEN
```

### 2. Test Flutter Integration

Once backend is working:

1. **Update base URL** in appointment_service.dart
2. **Update token method** to use your existing auth
3. **Run Flutter app** on emulator
4. **Try creating an appointment** from the UI
5. **Check MongoDB** to verify it was created
6. **Try loading appointments** list
7. **Try updating status** (Confirm/Cancel)

---

## 📱 Usage Examples

### Example 1: Create Appointment Button

```dart
ElevatedButton(
  onPressed: () async {
    try {
      final appointment = await AppointmentService().createAppointment(
        patientId: currentPatientId,
        doctorId: selectedDoctorId,
        dateTime: DateTime.now().add(Duration(days: 1)),
        type: 'Online',
        notes: 'Follow-up consultation',
      );
      
      print('Created: ${appointment.id}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Appointment created!')),
      );
    } catch (e) {
      print('Error: $e');
    }
  },
  child: Text('Book Appointment'),
)
```

### Example 2: Load and Display Appointments

```dart
FutureBuilder<List<AppointmentModel>>(
  future: AppointmentService().getPatientAppointments(patientId),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return CircularProgressIndicator();
    }
    
    if (snapshot.hasError) {
      return Text('Error: ${snapshot.error}');
    }
    
    final appointments = snapshot.data ?? [];
    
    return ListView.builder(
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final apt = appointments[index];
        return Card(
          child: ListTile(
            title: Text(apt.doctorName),
            subtitle: Text(apt.formattedDateTime),
            trailing: Text(apt.status),
          ),
        );
      },
    );
  },
)
```

### Example 3: Update Appointment Status

```dart
// Confirm button
ElevatedButton(
  onPressed: () async {
    try {
      await AppointmentService().confirmAppointment(appointmentId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Appointment confirmed!')),
      );
      // Reload appointments list
    } catch (e) {
      print('Error: $e');
    }
  },
  child: Text('Confirm'),
)

// Cancel button
OutlinedButton(
  onPressed: () async {
    try {
      await AppointmentService().cancelAppointment(appointmentId);
      // Handle success
    } catch (e) {
      print('Error: $e');
    }
  },
  child: Text('Cancel'),
)
```

---

## ✅ Checklist After Backend is Ready

- [ ] Backend Module 1 generated by Copilot
- [ ] All 6 endpoints tested with Postman
- [ ] Appointments stored in MongoDB
- [ ] Base URL updated in Flutter service
- [ ] Token method connected to existing auth
- [ ] Flutter app can create appointments
- [ ] Flutter app can load appointments
- [ ] Flutter app can update appointment status
- [ ] UI shows appointment data correctly

---

## 🐛 Troubleshooting

### Issue: "Connection refused"
**Solution:** Check base URL. Use `http://10.0.2.2:3000` for Android emulator.

### Issue: "401 Unauthorized"
**Solution:** Check that `_getToken()` method is returning valid JWT token.

### Issue: "404 Not Found"
**Solution:** Verify backend is running on port 3000 and endpoint paths match.

### Issue: "Invalid appointment ID"
**Solution:** Make sure you're using MongoDB ObjectId format (24 hex characters).

### Issue: "Cannot create appointment"
**Solution:** Verify patientId and doctorId exist in MongoDB database.

---

## 📞 Ready to Integrate?

Once your backend Module 1 is complete and tested:

1. ✅ Update the two setup items above (base URL and token method)
2. ✅ Test one endpoint at a time
3. ✅ Start with simple GET requests
4. ✅ Then try POST to create
5. ✅ Finally test UPDATE and DELETE

**All the code is ready - you just need to connect your auth token and test!**

---

## 🎯 Next Module

After Module 1 is working in both backend and Flutter:
- Come back and tell me "Module 1 is complete"
- I'll prepare Module 2 (Conversations & Messages) Flutter integration
- We'll repeat this process for all 5 modules

**You're on the right track! Take your time with Module 1 first.** 🚀

