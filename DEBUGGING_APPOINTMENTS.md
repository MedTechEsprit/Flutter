# 🔍 DEBUGGING GUIDE - Appointments Issues

## 📊 Issues Being Debugged:

### **Issue 1: No appointments loading from database**
- You have appointments in DB but screen shows empty or error
- Need to check if API is being called correctly
- Need to verify token and role are correct

### **Issue 2: Patient search not working**
- Typing "Gha" doesn't show results
- Need to check if doctor has patients in DB
- Need to verify API endpoint is correct

### **Issue 3: Create appointment button does nothing**
- Button doesn't create appointment even though API works
- Need to check console logs for errors
- Need to verify all fields are filled correctly

---

## 🔧 What I Fixed:

### **1. Added Comprehensive Logging**

#### **In appointments_screen.dart:**
Now you'll see detailed logs when loading appointments:
```
📋 === LOADING APPOINTMENTS ===
🏥 Doctor ID: 6997c4b4b814b65684191b86
🔑 Token exists: true
🔑 Token preview: eyJhbGciOiJIUzI1NiI...
👤 User role: Medecin
📡 Fetching appointments...
✅ Loaded 1 appointments
  - Appointment 6998cba8419f230b6c82949e: 2027-03-15 14:30:00.000Z (Pending)
📊 Fetching statistics...
✅ Stats loaded: Total 1, Pending 1
✅ === APPOINTMENTS LOADED SUCCESSFULLY ===
```

Or if error:
```
❌ === ERROR LOADING APPOINTMENTS ===
❌ Error: Exception: Accès refusé...
❌ Stack trace: ...
```

#### **In appointment_service.dart:**
```
📡 [AppointmentService] getDoctorAppointments called
   Doctor ID: 6997c4b4b814b65684191b86
   Status filter: none
   Headers: Content-Type, Authorization
   Request URL: http://10.0.2.2:3000/api/appointments/doctor/6997c4b4b814b65684191b86
   Response status: 200
   Response body preview: [{"_id":"6998cba8419f230b6c82949e"...
✅ Successfully parsed 1 appointments
```

#### **In patient search:**
```
🔍 Searching for patients: Gha
🔑 Token: eyJhbGciOiJIUzI1NiI...
🏥 Doctor ID: 6997c4b4b814b65684191b86
📡 Request URL: http://10.0.2.2:3000/api/doctors/6997c4b4b814b65684191b86/patients?search=Gha&limit=5
📥 Response status: 200
📥 Response body: {"patients":[...]}
✅ Found 3 patients
  Patient: Ghalya Dupont (user@example.com)
  Patient: Ghani Ahmed (ghani@example.com)
```

### **2. Fixed Patient Name Extraction**
**Before:**
```dart
'name': '${p['nom'] ?? p['prenom'] ?? 'Unknown'} ${p['prenom'] ?? ''}'
// Could show: "Jean Jean" or "null Jean"
```

**After:**
```dart
final nom = p['nom'] ?? '';
final prenom = p['prenom'] ?? '';
final name = '$prenom $nom'.trim();
final finalName = name.isEmpty ? 'Unknown' : name;
// Shows: "Jean Dupont" correctly
```

### **3. Added Error Messages to User**
Now if patient search fails, user sees:
```
❌ Error searching patients: 403
```

Instead of silent failure.

---

## 🧪 How to Test & Debug:

### **Step 1: Hot Reload**
```bash
# In terminal where flutter run is active:
Press 'r' for hot reload
```

### **Step 2: Open Developer Console**
- **VS Code**: View → Debug Console
- **Android Studio**: Run → Flutter → Show Console
- **Terminal**: Should already be visible

### **Step 3: Test Appointments Loading**

1. **Login as Médecin** (test@gmail.com)
2. **Go to Appointments tab**
3. **Watch console for logs**

**Expected logs:**
```
📋 === LOADING APPOINTMENTS ===
🏥 Doctor ID: 6997c4b4b814b65684191b86
🔑 Token exists: true
👤 User role: Medecin
📡 Fetching appointments...
📡 [AppointmentService] getDoctorAppointments called
   Request URL: http://10.0.2.2:3000/api/appointments/doctor/...
   Response status: 200
✅ Loaded 1 appointments
✅ === APPOINTMENTS LOADED SUCCESSFULLY ===
```

**If you see error:**
```
❌ === ERROR LOADING APPOINTMENTS ===
❌ Error: Exception: Accès refusé. Rôle requis: MEDECIN ou PATIENT ou PHARMACIEN
```

**This means:** Token doesn't have correct role. See "Fix Role Issue" below.

**If you see:**
```
❌ Error: Exception: Doctor ID not found. Please login again.
```

**This means:** User ID not stored correctly. See "Fix Login Issue" below.

### **Step 4: Test Patient Search**

1. **Click "+ New" button**
2. **Type "Gha" in search field**
3. **Watch console for logs**

**Expected logs:**
```
🔍 Searching for patients: Gha
🔑 Token: eyJhbGciOiJIUzI1NiI...
🏥 Doctor ID: 6997c4b4b814b65684191b86
📡 Request URL: http://10.0.2.2:3000/api/doctors/.../patients?search=Gha&limit=5
📥 Response status: 200
✅ Found 3 patients
  Patient: Ghalya Dupont (user@example.com)
```

**If you see:**
```
❌ Error: 403 - {"message":"Accès refusé..."}
```

**This means:** Token doesn't have correct role or doctor doesn't have access.

**If you see:**
```
✅ Found 0 patients
```

**This means:** Doctor has no patients in database matching "Gha".

### **Step 5: Test Create Appointment**

1. **Search and select a patient**
2. **Fill date/time and type**
3. **Click "Create Appointment"**
4. **Watch console for logs**

**Expected logs:**
```
🔵 Creating appointment with:
  Patient ID: 6990e706a1404b9597a74335
  Doctor ID: 6997c4b4b814b65684191b86
  DateTime: 2026-02-21T14:00:00.000Z
  Type: ONLINE
✅ Appointment created successfully: 6998cba8419f230b6c82949e
```

---

## 🔥 Common Issues & Fixes:

### **Issue: "Accès refusé. Rôle requis: MEDECIN"**

**Problem:** Token doesn't have correct role stored.

**Solution:**

1. **Check what role is stored:**
   Look in console for: `👤 User role: Medecin` or `Patient` or `null`

2. **If role is wrong or null:**
   
   **Option A: Logout and Login Again**
   ```
   1. Go to Profile
   2. Logout
   3. Select "Médecin" role
   4. Login with test@gmail.com
   ```

   **Option B: Check backend response**
   - The backend should return `"role": "Medecin"` in login response
   - If it returns `"role": "Medecin"` → Flutter should save it
   - If it returns something else → Backend needs fix

3. **Verify role is saved:**
   After login, check console for:
   ```
   👤 User role: Medecin
   ```

### **Issue: "Doctor ID not found"**

**Problem:** User ID not stored after login.

**Solution:**

1. **Check backend login response structure:**
   ```json
   {
     "token": "eyJhbGciOi...",
     "user": {
       "_id": "6997c4b4b814b65684191b86",  // ← Must have this
       "email": "test@gmail.com",
       "role": "Medecin"
     }
   }
   ```

2. **Check TokenService.saveAuthData():**
   File: `lib/core/services/token_service.dart`
   
   Should extract `_id` from user data:
   ```dart
   final userId = userData['_id']?.toString() ?? 
                  userData['id']?.toString();
   ```

3. **Logout and login again** to re-save data.

### **Issue: Patient search returns empty**

**Problem:** Doctor has no patients in database.

**Solution:**

1. **Add test patients to doctor in backend:**
   ```bash
   # Use your backend API or database directly
   # Add patients to doctor's patientIds array
   ```

2. **Or use a different doctor account** that has patients.

3. **Or create patient requests:**
   - Login as Patient
   - Request doctor
   - Login as Doctor
   - Accept request

### **Issue: Create button does nothing**

**Problem:** Check console logs for the actual error.

**Solution:**

Look for logs starting with:
```
🔵 Creating appointment with:
```

If you see:
```
❌ Error creating appointment: ...
```

The error message will tell you what's wrong:
- "Patient not found" → Wrong patient ID
- "Server is not accessible" → Backend offline
- "Accès refusé" → Token/role issue

---

## 📝 Testing Checklist:

### **Before Testing:**
- [ ] Hot reload completed
- [ ] Console/Debug window open
- [ ] Backend running on http://localhost:3000
- [ ] Logged in as Médecin role

### **Test 1: Load Appointments**
- [ ] Open Appointments screen
- [ ] See logs: `📋 === LOADING APPOINTMENTS ===`
- [ ] See logs: `✅ Loaded X appointments`
- [ ] **OR** see logs: `❌ === ERROR LOADING APPOINTMENTS ===`
- [ ] If error, note the error message
- [ ] Appointments display on screen **OR** error message shows

### **Test 2: Patient Search**
- [ ] Click "+ New" button
- [ ] Type "Gha" in search field
- [ ] See logs: `🔍 Searching for patients: Gha`
- [ ] See logs: `✅ Found X patients`
- [ ] **OR** see logs: `❌ Search error: ...`
- [ ] Dropdown shows patients **OR** error message shows

### **Test 3: Create Appointment**
- [ ] Select a patient from dropdown
- [ ] Fill date/time
- [ ] Select type (Online/Physical)
- [ ] Click "Create Appointment"
- [ ] See logs: `🔵 Creating appointment with:`
- [ ] See logs: `✅ Appointment created successfully`
- [ ] **OR** see logs: `❌ Error creating appointment:`
- [ ] Success message shows **OR** error message shows
- [ ] New appointment appears in list

---

## 🎯 What to Do Right Now:

1. **Hot reload** the app (press 'r')
2. **Open console/debug window** to see logs
3. **Login as Médecin** (test@gmail.com)
4. **Go to Appointments tab**
5. **Look at console logs** and **copy them**
6. **Tell me what you see:**
   - ✅ Appointments loaded successfully?
   - ❌ Error loading appointments? What's the error?
   - ✅ Patient search works?
   - ❌ Patient search fails? What's the error?
   - ✅ Create appointment works?
   - ❌ Create fails? What's the error?

---

## 📞 What to Report:

**Copy and send me the console logs, especially:**

1. **When loading appointments:**
   ```
   📋 === LOADING APPOINTMENTS ===
   ... (all the logs)
   ✅ === APPOINTMENTS LOADED SUCCESSFULLY ===
   OR
   ❌ === ERROR LOADING APPOINTMENTS ===
   ```

2. **When searching patients:**
   ```
   🔍 Searching for patients: Gha
   ... (all the logs)
   ✅ Found X patients
   OR
   ❌ Search error: ...
   ```

3. **When creating appointment:**
   ```
   🔵 Creating appointment with:
   ... (all the logs)
   ✅ Appointment created successfully
   OR
   ❌ Error creating appointment: ...
   ```

**This will help me fix the exact issue!** 🎯

---

## 🚀 Expected Outcome:

After hot reload, you should see:
1. ✅ Detailed console logs showing what's happening
2. ✅ Clear error messages if something fails
3. ✅ Ability to identify exactly what's wrong
4. ✅ Fix the root cause based on logs

**Hot reload now and check the console!** 📱🔍

