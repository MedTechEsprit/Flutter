# 🔍 JWT TOKEN DEBUGGING - Find the Real Doctor ID

## 🎯 What I Added:

I added comprehensive JWT token debugging to see **exactly** what doctor ID is in your token and what we should be using.

### **New Console Logs:**

When you open the appointments screen, you'll now see:

```
📋 === LOADING APPOINTMENTS ===
👤 User Data: {_id: 6997c4b4b814b65684191b86, email: test@gmail.com, role: Medecin, ...}
🏥 Doctor ID (getUserId): 6997c4b4b814b65684191b86
🏥 Doctor ID (getDoctorId): 6997c4b4b814b65684191b86
🔑 Token exists: true
🔑 Token preview: eyJhbGciOiJIUzI1NiIs...
🔓 JWT Payload: {sub: 6997c4b4b814b65684191b86, email: test@gmail.com, role: Medecin, iat: ..., exp: ...}
   sub (subject): 6997c4b4b814b65684191b86
   role: Medecin
   email: test@gmail.com
```

This will show us:
1. ✅ What user data is stored
2. ✅ What doctor ID we're using
3. ✅ What's actually in the JWT token
4. ✅ If there's a mismatch anywhere

---

## 🧪 Test NOW:

### **Step 1: Hot Reload**
```
Press 'r' in terminal
```

### **Step 2: Go to Appointments**
```
1. Open Appointments tab
2. Look at console logs
3. Find the section starting with 📋
```

### **Step 3: Check the Logs**

Look for these specific lines:
```
👤 User Data: {...}
🏥 Doctor ID (getUserId): ???
🏥 Doctor ID (getDoctorId): ???
🔓 JWT Payload: {...}
   sub (subject): ???
```

### **Step 4: Compare IDs**

**The doctor ID we're using:**
```
🏥 Doctor ID (getUserId): 6997c4b4b814b65684191b86
```

**The JWT token's subject (should be same):**
```
   sub (subject): 6997c4b4b814b65684191b86
```

**The API request:**
```
📡 Request URL: http://10.0.2.2:3000/api/appointments/doctor/6997c4b4b814b65684191b86
```

**All three should match!**

---

## 🎯 What to Look For:

### **Scenario A: IDs Match (Most Likely)**
```
🏥 Doctor ID: 6997c4b4b814b65684191b86
🔓 JWT sub: 6997c4b4b814b65684191b86
📡 API URL: .../doctor/6997c4b4b814b65684191b86
📥 Response: {"data":[],"total":0}
```

**If this happens:**
- ✅ We're using the correct doctor ID
- ❌ The appointments in database have **different** doctor ID
- **Solution:** Check database appointments, they must have wrong doctorId

---

### **Scenario B: JWT sub is Different**
```
🏥 Doctor ID: 6997c4b4b814b65684191b86
🔓 JWT sub: 1234567890abcdef  ← Different!
⚠️ WARNING: getUserId and getDoctorId return different values!
```

**If this happens:**
- ❌ We're using wrong doctor ID
- ✅ JWT has the real doctor ID
- **Solution:** We need to use JWT's `sub` field

---

### **Scenario C: Backend Returns Different Doctor ID**
```
When creating appointment:
Request: {doctorId: "6997c4b4b814b65684191b86", ...}
Response: {doctorId: {_id: "DIFFERENT_ID", ...}, ...}
```

**If this happens:**
- ❌ Backend is changing/overwriting the doctor ID
- **Solution:** Fix backend to use authenticated user's ID

---

## 🔧 Based on Logs, We'll Fix:

### **If Issue is in Flutter:**
```dart
// Change from:
_doctorId = await _tokenService.getUserId();

// To:
_doctorId = await _tokenService.getDoctorId();
// Or decode JWT and use 'sub' field
```

### **If Issue is in Backend:**
```typescript
// Backend should get doctor ID from JWT token:
@UseGuards(JwtAuthGuard)
async getDoctorAppointments(@Req() req) {
  const doctorId = req.user.sub; // From JWT
  return this.appointmentsService.findByDoctor(doctorId);
}
```

### **If Issue is in Database:**
```
The 3 appointments have wrong doctorId field.
Need to:
1. Check actual doctorId in those appointments
2. Update them to correct ID
3. Or delete and recreate
```

---

## 📊 Expected Console Output:

```
📋 === LOADING APPOINTMENTS ===
👤 User Data: {_id: 6997c4b4b814b65684191b86, nom: test, prenom: test, email: test@gmail.com, telephone: +33612345678, role: Medecin, ...}
🏥 Doctor ID (getUserId): 6997c4b4b814b65684191b86
🏥 Doctor ID (getDoctorId): 6997c4b4b814b65684191b86
🔑 Token exists: true
🔑 Token preview: eyJhbGciOiJIUzI1NiIs...
🔓 JWT Payload: {sub: 6997c4b4b814b65684191b86, email: test@gmail.com, role: Medecin, iat: 1771623106, exp: 1772227906}
   sub (subject): 6997c4b4b814b65684191b86
   role: Medecin
   email: test@gmail.com
👤 User role: Medecin
📡 Fetching appointments...
📡 [AppointmentService] getDoctorAppointments called
   Doctor ID: 6997c4b4b814b65684191b86
   Status filter: none
   Headers: Content-Type, Authorization
   Request URL: http://10.0.2.2:3000/api/appointments/doctor/6997c4b4b814b65684191b86?page=1&limit=100
   Response status: 200
   Response body preview: {"data":[],"total":0,"page":1,"limit":100}
✅ Successfully parsed 0 appointments
✅ Loaded 0 appointments
```

**This tells us:**
- ✅ Using correct doctor ID: `6997c4b4b814b65684191b86`
- ✅ JWT is correct
- ✅ API call is correct
- ❌ Database has no appointments for this doctor

---

## 🚀 Next Steps After Checking Logs:

### **1. If IDs are all correct:**
Check database directly:
```javascript
// In MongoDB
db.appointments.find({ doctorId: "6997c4b4b814b65684191b86" })

// Or if ObjectId:
db.appointments.find({ doctorId: ObjectId("6997c4b4b814b65684191b86") })

// See all appointments:
db.appointments.find()
```

### **2. If IDs don't match:**
Fix the code to use the correct ID from JWT

### **3. If appointments exist but API returns empty:**
Backend query has a bug

---

## 🎯 ACTION NOW:

**HOT RELOAD AND CHECK CONSOLE!**

1. Press **'r'** in terminal
2. Go to **Appointments** tab
3. **Copy the full console output**
4. **Send it to me**

The logs will show us **EXACTLY** where the issue is! 🔍

I'll then know if we need to:
- ✅ Fix Flutter code
- ✅ Fix backend code
- ✅ Fix database data

**Hot reload now!** 🚀

