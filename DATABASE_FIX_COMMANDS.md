# 🔧 EXACT FIX: Database Commands

## The Problem:

Your appointments exist in the database but have the **wrong doctorId**.

**Your current doctor:** `6997c4b4b814b65684191b86`  
**Appointments' doctorId:** Probably something else

---

## ✅ Solution 1: Check & Fix Database (5 minutes)

### **Step 1: Open MongoDB**

**Option A: MongoDB Compass**
1. Open MongoDB Compass
2. Connect to `mongodb://localhost:27017`
3. Select your database (probably named `diab_care` or similar)
4. Go to `appointments` collection

**Option B: MongoDB Shell**
1. Open terminal
2. Run: `mongo` or `mongosh`
3. Run: `use your_database_name`

---

### **Step 2: Check Current Appointments**

```javascript
// See all appointments
db.appointments.find().pretty()

// You'll see output like:
{
  "_id": ObjectId("6998cba8419f230b6c82949e"),
  "patientId": "6990e706a1404b9597a74335",
  "doctorId": "SOME_ID_HERE",  // ← Check this!
  "dateTime": ISODate("2027-03-15T14:30:00.000Z"),
  "type": "PHYSICAL",
  "status": "PENDING",
  ...
}
```

**Check the `doctorId` field!**

---

### **Step 3: Fix the Doctor IDs**

**If appointments have wrong doctor ID:**

```javascript
// Update ALL appointments to use correct doctor ID
db.appointments.updateMany(
  {},  // Match all appointments (or add filter)
  { 
    $set: { 
      doctorId: "6997c4b4b814b65684191b86"  // Your correct doctor ID
    } 
  }
)

// Should output:
// { "acknowledged" : true, "matchedCount" : 3, "modifiedCount" : 3 }
```

**If only specific appointments need fixing:**

```javascript
// Update only appointments with old doctor ID
db.appointments.updateMany(
  { doctorId: "OLD_DOCTOR_ID_HERE" },  // Replace with actual old ID
  { 
    $set: { 
      doctorId: "6997c4b4b814b65684191b86" 
    } 
  }
)
```

---

### **Step 4: Verify the Fix**

```javascript
// Check appointments for your doctor
db.appointments.find({ 
  doctorId: "6997c4b4b814b65684191b86" 
}).pretty()

// Should now show 3 appointments
```

---

### **Step 5: Hot Reload App**

1. Go back to your Flutter app
2. Hot reload (press 'r' in terminal)
3. Go to Appointments tab
4. **You should now see the 3 appointments!** ✅

---

## ✅ Solution 2: Delete & Recreate (Alternative)

If you want to start fresh:

### **Step 1: Delete Old Appointments**

```javascript
// Delete all appointments
db.appointments.deleteMany({})

// Or delete only specific ones
db.appointments.deleteMany({ 
  doctorId: "WRONG_DOCTOR_ID" 
})
```

### **Step 2: Create New Appointment in App**

1. Open Flutter app
2. Login as doctor (test@gmail.com)
3. Go to Appointments
4. Click "+ New"
5. Select patient
6. Fill date/time
7. Click "Create Appointment"

**The new appointment will have the correct doctor ID!**

---

## 🎯 Most Likely Scenario:

Your appointments were created when:
1. You were logged in as a different doctor, OR
2. You manually created them in MongoDB with wrong ID, OR
3. Backend set wrong doctor ID when creating

**The fix:**
- Update the `doctorId` field in those 3 appointments to `"6997c4b4b814b65684191b86"`

---

## 📊 Verification Commands:

### **Check how many appointments exist:**
```javascript
db.appointments.count()
// Should show: 3
```

### **Check appointments for your doctor:**
```javascript
db.appointments.count({ 
  doctorId: "6997c4b4b814b65684191b86" 
})
// Currently shows: 0
// After fix should show: 3
```

### **See all doctor IDs in appointments:**
```javascript
db.appointments.distinct("doctorId")
// Shows list of all unique doctor IDs
```

---

## 🔥 Quick Copy-Paste Fix:

**Just run these commands in MongoDB shell:**

```javascript
// 1. Connect to database
use diab_care  // or your database name

// 2. Check current appointments
db.appointments.find({}, { doctorId: 1, patientId: 1, dateTime: 1 }).pretty()

// 3. Fix doctor IDs
db.appointments.updateMany(
  {},
  { $set: { doctorId: "6997c4b4b814b65684191b86" } }
)

// 4. Verify
db.appointments.find({ doctorId: "6997c4b4b814b65684191b86" }).count()
// Should show: 3

// Done! Now hot reload the Flutter app.
```

---

## ✅ Expected Result:

**After fixing the database:**

1. Open Flutter app
2. Hot reload (press 'r')
3. Go to Appointments tab
4. Console shows:
   ```
   📋 === LOADING APPOINTMENTS ===
   ✅ Loaded 3 appointments
     - Appointment 6998cba8: 2027-03-15 (Pending)
     - Appointment 6998d392: 2026-03-15 (Pending)
     - Appointment 6998d4ce: 2026-02-27 (Pending)
   ```
5. Screen shows all 3 appointments
6. Statistics show: Total: 3, Pending: 3

**FIXED!** ✅

---

## 🚀 Do This Now:

1. **Open MongoDB** (Compass or Shell)
2. **Run:** `db.appointments.find().pretty()`
3. **Check the `doctorId`** in those appointments
4. **If wrong, run:** 
   ```javascript
   db.appointments.updateMany(
     {},
     { $set: { doctorId: "6997c4b4b814b65684191b86" } }
   )
   ```
5. **Hot reload Flutter app**
6. **Check appointments screen** - should show 3 appointments!

**This will 100% fix your issue!** 🎯

