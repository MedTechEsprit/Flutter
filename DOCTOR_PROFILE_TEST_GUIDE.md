 the # 🧪 COMPLETE TEST GUIDE - Doctor Profile

**Quick Reference for Testing All Features**

---

## ⚡ 1-Minute Quick Test

```bash
flutter run
```

**Then:**
1. Login: `test@gmail.com` / `123456`
2. Tap Profile tab (bottom)
3. Toggle availability switch
4. Tap settings (top right) → Logout

✅ **If all work → Success!**

---

## 📋 Detailed Test Plan

### Test 1: Profile Data Loading ⏱️ 1 minute

**Steps:**
1. Open app
2. Login as doctor
3. Navigate to Profile tab
4. Wait 1-2 seconds

**Expected Results:**
- ✅ Loading spinner shows initially
- ✅ Spinner disappears after data loads
- ✅ Real name appears: "Dr. test test"
- ✅ Real email shows: "test@gmail.com"
- ✅ Real phone shows: "53423429"
- ✅ Avatar shows initials: "TT"
- ✅ Role badge shows: "Medecin"

**Pass Criteria:**
- All real data visible
- No "Dr. Sarah Johnson" hardcoded name
- No loading errors

---

### Test 2: Status Toggle (Active → Inactive) ⏱️ 30 seconds

**Initial State:**
- Status should be "ACTIF" (green)
- Switch should be ON
- Text: "Online (Active)" / "Accepting new patients"

**Steps:**
1. Tap the toggle switch (right side)
2. Wait 1-2 seconds

**Expected Results:**
- ✅ Loading spinner appears on switch
- ✅ Switch doesn't move until response
- ✅ After response:
  - Switch moves to OFF
  - Colors change to grey
  - Text changes to "Offline (Inactive)"
  - Text changes to "Currently unavailable"
  - Success message appears at bottom
- ✅ Backend status updated to "INACTIF"

**Pass Criteria:**
- Toggle works smoothly
- Loading indicator shows
- Success message appears
- Colors/text update correctly

---

### Test 3: Status Toggle (Inactive → Active) ⏱️ 30 seconds

**Initial State:**
- Status should be "INACTIF" (grey)
- Switch should be OFF

**Steps:**
1. Tap the toggle switch again
2. Wait 1-2 seconds

**Expected Results:**
- ✅ Loading spinner appears
- ✅ After response:
  - Switch moves to ON
  - Colors change to green
  - Text changes to "Online (Active)"
  - Text changes to "Accepting new patients"
  - Success message appears
- ✅ Backend status updated to "ACTIF"

**Pass Criteria:**
- Toggle works in reverse
- All visual updates correct
- Success message clear

---

### Test 4: Logout from Settings ⏱️ 30 seconds

**Steps:**
1. Tap settings icon (top right corner)
2. Menu opens
3. See "Logout" option with red icon
4. Tap "Logout"
5. Confirmation dialog appears
6. Tap "Logout" in dialog

**Expected Results:**
- ✅ Settings menu opens
- ✅ Logout option visible and red
- ✅ Confirmation dialog shows
- ✅ Dialog has "Cancel" and "Logout" buttons
- ✅ After confirming:
  - Redirected to login screen
  - Can't go back to profile
  - Must login again to access profile

**Pass Criteria:**
- Settings menu accessible
- Logout option clear
- Confirmation required
- Session cleared completely

---

### Test 5: Error Handling ⏱️ 2 minutes

**Test 5A: No Network**
1. Turn off WiFi/data
2. Try to toggle status
3. **Expected:** Error message appears
4. **Expected:** Old status remains
5. Turn network back on
6. Try again
7. **Expected:** Works correctly

**Test 5B: Session Expired**
1. Wait for token to expire (or manually clear)
2. Try to toggle status
3. **Expected:** Error message or redirect to login

**Pass Criteria:**
- Errors handled gracefully
- Clear error messages
- No app crashes
- Can recover from errors

---

## 🎯 Complete Functionality Checklist

### Data Loading:
- [ ] Profile loads on screen open
- [ ] Shows loading indicator
- [ ] Displays real doctor name
- [ ] Shows real email
- [ ] Shows real phone number
- [ ] Shows role badge
- [ ] Avatar shows initials
- [ ] Optional fields appear if exist (license, clinic)

### Status Toggle:
- [ ] Current status displays correctly
- [ ] Toggle switch is positioned correctly
- [ ] Tap on switch triggers toggle
- [ ] Loading spinner appears during API call
- [ ] Switch doesn't move until response
- [ ] After success:
  - [ ] Switch position updates
  - [ ] Colors change (green ↔ grey)
  - [ ] Text updates (Online ↔ Offline)
  - [ ] Description updates
  - [ ] Success message shows
- [ ] Can toggle multiple times
- [ ] Each toggle calls backend
- [ ] Backend status syncs correctly

### Logout:
- [ ] Settings icon visible (top right)
- [ ] Settings icon tappable
- [ ] Menu opens on tap
- [ ] Logout option visible
- [ ] Logout option is red
- [ ] Logout icon present
- [ ] Tapping logout shows dialog
- [ ] Dialog has clear message
- [ ] Dialog has Cancel button
- [ ] Dialog has Logout button
- [ ] Cancel closes dialog
- [ ] Logout clears session
- [ ] Logout navigates to login
- [ ] Can't go back to profile
- [ ] Must re-login to access

### UI/UX:
- [ ] All animations smooth
- [ ] No lag or stuttering
- [ ] Colors match design
- [ ] Text is readable
- [ ] Icons are clear
- [ ] Buttons are tappable
- [ ] Spacing looks good
- [ ] No UI overlap
- [ ] Bottom navigation visible
- [ ] Status bar looks good

### Error Handling:
- [ ] Network errors caught
- [ ] Timeout errors handled
- [ ] Server errors handled
- [ ] Invalid responses handled
- [ ] Error messages clear
- [ ] Error messages dismissible
- [ ] App doesn't crash on errors
- [ ] Can retry after error

---

## 🐛 Common Issues & Solutions

### Issue: Profile shows "Loading..." forever
**Solution:**
- Check backend is running (http://localhost:3000)
- Check network connection
- Check console for errors
- Verify token is valid

### Issue: Toggle doesn't work
**Solution:**
- Check if toggle is disabled (grey out)
- Check console logs for API errors
- Verify backend endpoint is working
- Test API manually in Swagger

### Issue: Logout doesn't work
**Solution:**
- Check console for errors
- Verify navigation is correct
- Check if dialog appears
- Test AuthViewModel logout method

### Issue: Old hardcoded data still shows
**Solution:**
- Hot restart the app (not hot reload)
- Clear app data
- Rebuild the app
- Check code changes saved

---

## 📊 Success Metrics

**Pass:** All tests green ✅  
**Partial:** Some features work ⚠️  
**Fail:** Critical features broken ❌

### Critical Features (Must Work):
1. Profile loads with real data
2. Status toggle updates backend
3. Logout clears session

### Important Features (Should Work):
4. Loading indicators show
5. Error messages appear
6. Success messages clear

### Nice to Have (Good if Works):
7. Smooth animations
8. Quick response times
9. Perfect UI alignment

---

## ✅ Final Verification

After all tests pass, verify:

1. **In App:**
   - Profile shows your real data
   - Toggle works both directions
   - Logout returns to login

2. **In Swagger:**
   - Check doctor status endpoint
   - Verify `statutCompte` field
   - Confirm it matches app display

3. **In Database:**
   - Check doctor document
   - Verify `statutCompte` updates
   - Check `updatedAt` timestamp

---

## 🎉 Success!

If all tests pass:
- ✅ **Profile feature is complete**
- ✅ **Ready for production**
- ✅ **No blocking issues**

---

**Status:** ✅ **READY TO TEST**  
**Estimated Time:** 5-10 minutes  
**Difficulty:** Easy  
**Expected Result:** All features working perfectly! 🎊

