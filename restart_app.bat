@echo off
echo ========================================
echo RESTART FLUTTER APP - FIX TOKEN STORAGE
echo ========================================
echo.

echo [1/3] Cleaning build...
flutter clean
timeout /t 2 /nobreak > nul

echo [2/3] Getting dependencies...
flutter pub get
timeout /t 2 /nobreak > nul

echo [3/3] Running app...
echo.
echo ⚠️ IMPORTANT: Apres le demarrage, connectez-vous avec:
echo    Email: syrine@gmail.com
echo    Password: syrine123
echo.
echo 👀 VERIFIEZ LES LOGS:
echo    - Vous devez voir: 💾💾💾 DEBUT DU STOCKAGE 💾💾💾
echo    - Vous devez voir: 📋 ========== FETCHING PENDING REQUESTS ==========
echo.
flutter run

pause

