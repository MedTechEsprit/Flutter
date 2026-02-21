# ⚡ QUICK REFERENCE CARD

**Everything You Need to Know in 2 Minutes**

---

## 🚀 Run the App
```bash
flutter run
```

---

## 🔐 Login Credentials
```
Email: test@gmail.com
Password: 123456
Role: Medecin (Doctor)
```

---

## 📱 Main Features

### 1. Appointments Tab
**What you can do:**
- ➕ Create new appointments
- 📋 View in list or calendar
- ✏️ Edit appointments (all fields)
- 🗑️ Delete appointments
- ✅ Accept/Decline appointments
- 🔍 Filter by status
- 📊 View statistics

**Quick Actions:**
- Tap `+ New` → Create appointment
- Tap ⋮ menu → Edit/Delete/Accept/Decline
- Tap appointment card → View details
- Switch tabs → List/Calendar view
- Tap status filters → Filter list

---

### 2. Profile Tab
**What you can do:**
- 👤 View your profile
- 🔄 Toggle availability (Active/Inactive)
- 🚪 Logout

**Quick Actions:**
- Toggle switch → Change status
- Tap settings icon → Logout menu
- Confirm → Logout

---

### 3. Dashboard Tab
**What you can do:**
- 📊 View statistics
- 📝 See patient requests
- 📈 Check overview

**Quick Actions:**
- Tap "Patient Requests" → Manage requests
- View stats cards

---

### 4. Patients Tab
**What you can do:**
- 👥 View your patients
- 🔍 Search patients
- ➕ Add new patients

**Quick Actions:**
- Type in search → Filter list
- Tap `+` button → Add patient

---

## 🔄 Common Workflows

### Create Appointment:
1. Go to Appointments
2. Tap `+ New`
3. Search patient (type name)
4. Select patient
5. Pick date/time
6. Choose type (Online/Physical)
7. Add notes (optional)
8. Tap "Create Appointment"

### Edit Appointment:
1. Find appointment in list
2. Tap ⋮ menu
3. Select "Edit"
4. Change any field
5. Tap "Update Appointment"

### Toggle Availability:
1. Go to Profile
2. Find availability toggle
3. Tap switch
4. Wait 1-2 seconds
5. ✅ Status updated!

### Logout:
1. Go to Profile
2. Tap settings icon (top right)
3. Select "Logout"
4. Confirm in dialog
5. 👋 Back to login!

---

## 🐛 Troubleshooting

**Problem: App won't start**
→ Check backend is running on port 3000

**Problem: Can't login**
→ Verify credentials: test@gmail.com / 123456

**Problem: Data not loading**
→ Check network connection

**Problem: Changes not saving**
→ Check console for errors

**Problem: Token expired**
→ Logout and login again

---

## 📊 Status Codes

**Appointment Status:**
- 🟠 **Pending** - Waiting for confirmation
- 🟢 **Confirmed** - Confirmed by doctor
- 🔵 **Completed** - Appointment finished
- 🔴 **Cancelled** - Cancelled

**Appointment Type:**
- 🎥 **Online** - Video consultation
- 🏥 **Physical** - In-person visit

**Doctor Status:**
- 🟢 **ACTIF** - Online, accepting patients
- ⚫ **INACTIF** - Offline, unavailable

---

## 💡 Pro Tips

1. **Use filters** - Quickly find appointments by status
2. **Calendar view** - See appointments by date
3. **Quick edit** - Tap ⋮ menu for fast actions
4. **Search patients** - Type to find patients instantly
5. **Toggle status** - Manage availability easily
6. **Logout safely** - Always logout when done

---

## 📚 Documentation

**Detailed Guides:**
- `COMPLETE_IMPLEMENTATION_SUMMARY.md` - Full overview
- `DOCTOR_PROFILE_TEST_GUIDE.md` - Profile testing
- `QUICK_TEST_GUIDE.md` - Appointment testing
- `FULL_UPDATE_SUCCESS.md` - Update feature details

**Quick Guides:**
- `SUCCESS_SUMMARY.md` - Feature summary
- `DOCTOR_PROFILE_SUCCESS.md` - Profile success
- This file - Quick reference

---

## 🎯 Key Endpoints

**Backend Base URL:**
```
http://localhost:3000/api
```

**Main Endpoints:**
- `/appointments` - Appointment management
- `/medecins/:id` - Doctor profile
- `/doctors/:id/patient-requests` - Patient requests
- `/patients/search/by-name-or-email` - Patient search

---

## ✅ Quick Checklist

**Before starting:**
- [ ] Backend running
- [ ] Emulator/device ready
- [ ] Network connected

**After login:**
- [ ] See appointments screen
- [ ] Create test appointment
- [ ] Edit an appointment
- [ ] Toggle availability
- [ ] Check profile data
- [ ] Logout successfully

---

## 🎉 You're Ready!

Everything is set up and working!  
Just run `flutter run` and start testing! 🚀

---

**Status:** ✅ **READY TO USE**  
**Time to test:** 5-10 minutes  
**Difficulty:** Easy  
**Fun factor:** High! 😊

