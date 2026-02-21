# ✅ Patient Requests Feature - Complete Implementation

## 📦 **Files Created**

### 1. Data Model
**File:** `lib/data/models/patient_request_model.dart`
- `PatientRequestModel` - Main request model
- `PatientInfo` - Embedded patient information
- Status helpers: `isPending`, `isAccepted`, `isDeclined`

### 2. API Service
**File:** `lib/data/services/patient_request_service.dart`

**Methods:**
- `getPatientRequests(String doctorId)` → `List<PatientRequestModel>`
- `acceptPatientRequest(String doctorId, String requestId)` → `PatientRequestModel`
- `declinePatientRequest(String doctorId, String requestId, {String? declineReason})` → `PatientRequestModel`

### 3. UI Screen
**File:** `lib/features/doctor/views/patient_requests_screen.dart`
- Full-featured patient requests management screen
- Accept/Decline actions with confirmation dialogs
- Pull to refresh
- Error handling & retry
- Empty state
- Loading states

### 4. Dashboard Integration
**File:** `lib/features/doctor/views/doctor_dashboard_screen.dart`
- Shows real count of pending requests
- "New Patient Requests" banner with dynamic text
- Navigates to `PatientRequestsScreen` on tap

---

## 🔗 **API Endpoints Consumed**

### 1. GET /api/doctors/{doctorId}/patient-requests
**Purpose:** Fetch pending patient requests for a doctor

**Request:**
```
GET http://localhost:3000/api/doctors/6997c4b4b814b65684191b86/patient-requests
Headers: Authorization: Bearer {token}
```

**Response:**
```json
[
  {
    "_id": "6998e6deee01d859d56fc551",
    "patientId": {
      "_id": "6990e706a1404b9597a74335",
      "nom": "Dupont",
      "prenom": "Jean",
      "email": "user@example.com",
      "telephone": "+33612345678",
      "role": "PATIENT"
    },
    "doctorId": "6997c4b4b814b65684191b86",
    "status": "pending",
    "requestDate": "2026-02-20T22:57:34.064Z",
    "urgentNote": "string",
    "createdAt": "2026-02-20T22:57:34.072Z",
    "updatedAt": "2026-02-20T22:57:34.072Z"
  }
]
```

### 2. POST /api/doctors/{id}/patient-requests/{requestId}/accept
**Purpose:** Accept a patient request and add patient to doctor's list

**Request:**
```
POST http://localhost:3000/api/doctors/{doctorId}/patient-requests/{requestId}/accept
Headers: Authorization: Bearer {token}
```

**Response:**
```json
{
  "_id": "6998e6deee01d859d56fc551",
  "patientId": "6990e706a1404b9597a74335",
  "doctorId": "6997c4b4b814b65684191b86",
  "status": "accepted",
  "requestDate": "2026-02-20T22:57:34.064Z",
  "urgentNote": "string",
  "createdAt": "2026-02-20T22:57:34.072Z",
  "updatedAt": "2026-02-20T23:08:13.854Z"
}
```

### 3. POST /api/doctors/{id}/patient-requests/{requestId}/decline
**Purpose:** Decline a patient request with optional reason

**Request:**
```
POST http://localhost:3000/api/doctors/{doctorId}/patient-requests/{requestId}/decline
Headers: Authorization: Bearer {token}
Content-Type: application/json

{
  "declineReason": "Not accepting new patients at this time"
}
```

**Response:**
```json
{
  "_id": "6998e6deee01d859d56fc551",
  "patientId": "6990e706a1404b9597a74335",
  "doctorId": "6997c4b4b814b65684191b86",
  "status": "declined",
  "requestDate": "2026-02-20T22:57:34.064Z",
  "urgentNote": "string",
  "createdAt": "2026-02-20T22:57:34.072Z",
  "updatedAt": "2026-02-20T23:10:45.123Z"
}
```

---

## 🎨 **UI Features**

### **Dashboard Banner**
- Orange gradient banner with icon
- Shows pending count dynamically:
  - "No pending requests" (when 0)
  - "1 patient waiting for approval" (when 1)
  - "5 patients waiting for approval" (when >1)
- Tap to navigate to full requests screen
- Real-time count from API

### **Patient Requests Screen**

**Header:**
- Title: "Patient Requests"
- Refresh icon button
- Badge showing count: "X New"

**Request Cards:**
- **Patient avatar** - First letter of first name with gradient background
- **Patient info:**
  - Full name
  - Email
  - Phone (if available)
  - Request time ("2 hours ago", "3 days ago", etc.)
- **Urgent badge** - Red badge if `urgentNote` exists
- **Urgent note section** - Red-bordered expandable section showing the note
- **Action buttons:**
  - **Decline** - Red outlined button → Opens dialog with optional reason
  - **Accept** - Green filled button → Instantly accepts

**States:**
- **Loading:** Circular progress indicator
- **Error:** Error icon + message + Retry button
- **Empty:** Inbox icon + "No pending requests"
- **Pull to refresh:** Swipe down to reload

---

## 🎯 **User Flow**

### **Accepting a Patient Request**
1. Doctor opens app → Dashboard
2. Sees "3 patients waiting for approval" banner
3. Taps banner → Patient Requests Screen
4. Sees list of 3 pending requests with patient details
5. Taps **Accept** on a request
6. Success message: "Jean Dupont accepted as patient"
7. Request disappears from list (count updates to 2)
8. Dashboard banner updates to "2 patients waiting for approval"

### **Declining a Patient Request**
1. Doctor taps **Decline** button
2. Dialog appears: "Decline request from Jean Dupont?"
3. Optional text field: "Reason (optional)"
4. Doctor can:
   - Enter reason (e.g., "Not accepting new patients")
   - Or leave blank
5. Taps **Decline** button in dialog
6. Success message: "Request declined"
7. Request disappears from list
8. Count updates on dashboard

---

## 🔐 **Authentication**

All requests use the doctor's JWT token:
- Token stored via `TokenService`
- Doctor ID extracted from token using `getUserId()`
- Authorization header: `Bearer {token}`

---

## 📊 **Dashboard Integration**

### **Data Loading Flow**

```dart
_loadDoctorData() {
  1. Get doctor ID from JWT token
  2. Fetch doctor profile (GET /api/medecins/:id)
  3. Fetch appointment stats (GET /api/appointments/doctor/:id/stats)
  4. Fetch patient requests (GET /api/doctors/:id/patient-requests)  // NEW
  5. Filter for pending requests only
  6. Update state with counts
}
```

### **Banner Display Logic**

```dart
_pendingRequestsCount == 0
  ? 'No pending requests'
  : '$_pendingRequestsCount patient${_pendingRequestsCount == 1 ? "" : "s"} waiting for approval'
```

---

## ✅ **Testing Checklist**

- ✅ Dashboard shows real pending count
- ✅ Tap banner navigates to requests screen
- ✅ Requests load from API
- ✅ Accept button works
- ✅ Decline button works
- ✅ Decline with reason works
- ✅ Decline without reason works
- ✅ Success messages display
- ✅ Error handling works
- ✅ Pull to refresh works
- ✅ Empty state displays when no requests
- ✅ Urgent note displays correctly
- ✅ Time ago calculation works ("2 hours ago", etc.)
- ✅ Avatar shows first letter of first name
- ✅ Count updates after accept/decline

---

## 🚀 **Module Status**

✅ **COMPLETE** - All patient request features implemented and working!

**Next Features to Implement:**
- Push notifications for new requests
- Request history (accepted/declined)
- Patient profile view from request
- Bulk actions (accept/decline multiple)

---

**Date Completed:** February 21, 2026
**Status:** ✅ Production Ready

