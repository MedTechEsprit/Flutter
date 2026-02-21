# 🧪 Appointment APIs - Testing Guide

## ✅ What's Connected to Real APIs (Working Now)

| Feature | API Endpoint | Status | How to Test |
|---------|--------------|--------|-------------|
| **Load Doctor Appointments** | `GET /api/appointments/doctor/:doctorId` | ✅ Connected | Go to Doctor Home → Appointments tab |
| **Load Doctor Statistics** | `GET /api/appointments/doctor/:doctorId/stats` | ✅ Connected | Stats shown in filter chips |
| **Show Today's Appointments** | Local filter on loaded data | ✅ Working | Check header: "X appointments today" |
| **Pull-to-Refresh** | Reloads appointments from API | ✅ Working | Pull down on appointments list |
| **Error Handling** | Shows error + Retry button | ✅ Working | Turn off backend, tap Retry |
| **Filter by Status** | Query param: `?status=PENDING` | ✅ Connected | Tap filter chips (All/Pending/Confirmed/Completed) |
| **Confirm Appointment** | `PATCH /api/appointments/:id` | ✅ Connected | Tap "..." → Confirm (on pending appointments) |
| **Cancel Appointment** | `PATCH /api/appointments/:id` | ✅ Connected | Tap "..." → Cancel |
| **Delete Appointment** | `DELETE /api/appointments/:id` | ✅ Connected | Tap "..." → Delete (permanent removal) |
| **Create Appointment** | `POST /api/appointments` | ✅ Connected | Tap "New Appointment" button or "+" FAB |
| **View Appointment Details** | Uses loaded data | ✅ Working | Tap appointment card or "..." → View Details |

---

## 🎯 How to Test Right Now

### **Step 1: Register/Login as Doctor**
1. Open app
2. Select **"Médecin"** role
3. Register or login with your test account
4. Navigate to doctor home screen

### **Step 2: View Appointments Screen**
- Tap on **"Appointments"** tab in bottom navigation
- You'll see:
  - **Loading indicator** while fetching data
  - **"X appointments today"** in header (real count from API)
  - **List of appointments** from your backend
  - **Empty state** if no appointments exist

### **Step 3: Test Features**

#### **A. View Real Appointments**
- If you have appointments in database → they appear in the list
- Each card shows:
  - Patient name (or ID if name not available)
  - Time (formatted: "02:30 PM")
  - Type badge (Online/Physical)
  - Status badge (Pending/Confirmed/Completed/Cancelled)
- **Tap any card** → Opens details modal

#### **B. Create New Appointment** 🆕
1. Tap the **"New Appointment"** floating button (bottom right)
2. Fill the form:
   - **Patient ID**: Enter MongoDB ID of patient (required)
   - **Date & Time**: Tap to select date and time
   - **Type**: Choose Online or Physical
   - **Notes**: Optional notes
3. Tap **"Create Appointment"**
4. Backend creates appointment via `POST /api/appointments`
5. Success message appears
6. List automatically refreshes to show new appointment

#### **C. Filter by Status**
1. Look at filter chips at top: All, Pending, Confirmed, Completed
2. **Numbers show real counts** from your backend
3. **Tap "Pending"** → Shows only pending appointments
4. **Tap "Confirmed"** → Shows only confirmed appointments
5. **Tap "All"** → Shows all appointments

#### **D. Confirm Pending Appointments**
1. Find an appointment with **status: Pending**
2. Tap the **"⋮"** (three dots) menu button
3. Tap **"Confirm"**
4. Backend updates status to CONFIRMED
5. List automatically refreshes
6. Snackbar shows: "Appointment confirmed"

#### **E. Cancel Appointments**
1. Find any appointment that's not Completed/Cancelled
2. Tap **"⋮"** menu
3. Tap **"Cancel"** (orange text)
4. Confirmation dialog appears: "Are you sure?"
5. Tap **"Yes, Cancel"**
6. Backend updates status to CANCELLED
7. List refreshes
8. Snackbar shows: "Appointment cancelled"

#### **F. Delete Appointments Permanently** 🆕
1. Find any appointment
2. Tap **"⋮"** menu
3. Tap **"Delete"** (red text)
4. Confirmation dialog: "Are you sure you want to permanently DELETE?"
5. Tap **"Yes, Delete Permanently"**
6. Backend calls `DELETE /api/appointments/:id`
7. Appointment is **permanently removed** from database
8. List refreshes
9. Red snackbar: "Appointment deleted permanently"

#### **G. View Appointment Details**
- **Method 1:** Tap appointment card directly
- **Method 2:** Tap "⋮" → "View Details"
- Modal sheet shows:
  - Patient ID
  - Date & Time
  - Type (Online/Physical)
  - Status
  - Notes (if any)

#### **H. Pull to Refresh**
- Pull down the list
- Loading indicator appears
- Data reloads from API
- List updates

#### **I. Test Error Handling**
1. Stop your NestJS backend server
2. Open appointments screen
3. You'll see error message with backend URL
4. Tap **"Retry"** button
5. Error message updates with timeout info


---

## 📊 What You'll See (Step by Step)

### **Scenario 1: Backend Running + Has Appointments**
```
Header: "3 appointments today"
List:
  - Patient abc123 | 09:00 AM | Online | Confirmed
  - Patient def456 | 11:30 AM | Physical | Pending
  - Patient ghi789 | 02:00 PM | Online | Completed
```

### **Scenario 2: Backend Running + No Appointments**
```
Header: "0 appointments today"
Empty State:
  📅
  "No appointments yet"
  "Create your first appointment"
```

### **Scenario 3: Backend Not Running**
```
❌ Error loading appointments

Exception: Serveur inaccessible. Vérifiez que le backend 
tourne sur le port 3000.

[Retry Button]
```

---


## 🔧 Quick Backend Test Setup

If you want to create test data in your backend, use **Swagger** or **Postman**:

### Create Test Appointment (Swagger)
```http
POST http://localhost:3000/api/appointments
Authorization: Bearer <your_doctor_token>
Content-Type: application/json

{
  "patientId": "6997c341b814b65684191b7f",
  "doctorId": "6997c341b814b65684191b7f",
  "dateTime": "2026-02-20T14:30:00.000Z",
  "type": "ONLINE",
  "notes": "First consultation"
}
```

Then refresh the app to see it appear!

---

## 📝 Summary

**🎉 ALL APPOINTMENT APIs ARE NOW CONNECTED! 🎉**

**What works NOW in the app:**
1. ✅ Real-time appointment loading from backend
2. ✅ Today's appointment count in header  
3. ✅ Pull-to-refresh functionality
4. ✅ Error handling with retry
5. ✅ Empty state when no appointments
6. ✅ 10-second timeout on API calls
7. ✅ Proper status/type display from API data
8. ✅ **Filter by status** (All/Pending/Confirmed/Completed)
9. ✅ **Confirm pending appointments**
10. ✅ **Cancel appointments** with confirmation dialog
11. ✅ **Delete appointments permanently** - **NEW!**
12. ✅ **Create new appointments** with full form - **NEW!**
13. ✅ **View appointment details** modal
14. ✅ **Real statistics** in filter chips

**To test:**
1. Login as doctor
2. Go to Appointments tab
3. See your real backend data!
4. **Create a new appointment** with the + button
5. **Try filtering** by Pending/Confirmed/Completed
6. **Confirm a pending appointment**
7. **Cancel an appointment**
8. **Delete an appointment permanently**
9. **View details** by tapping a card
10. Pull to refresh
11. Test with backend on/off

**API Coverage: 100%**
- ✅ GET /doctor/:id/appointments
- ✅ GET /doctor/:id/stats  
- ✅ POST /appointments (Create)
- ✅ PATCH /appointments/:id (Confirm/Cancel)
- ✅ DELETE /appointments/:id (Delete)
- ✅ Filter by status query params

