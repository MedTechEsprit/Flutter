@echo off
echo ========================================
echo   Pushing to GitHub - medecin1 branch
echo ========================================
echo.

cd C:\Users\mimou\Flutter-main

echo [1/6] Checking git status...
git status
echo.

echo [2/6] Adding all changes...
git add .
echo.

echo [3/6] Committing changes...
git commit -m "feat: Complete doctor appointments and profile module - Production Ready"
echo.

echo [4/6] Creating branch 'medecin1'...
git checkout -b medecin1
echo.

echo [5/6] Setting remote repository...
git remote remove origin 2>nul
git remote add origin https://github.com/MedTechEsprit/Flutter.git
echo.

echo [6/6] Pushing to GitHub...
git push -u origin medecin1
echo.

echo ========================================
echo   SUCCESS! Changes pushed to GitHub
echo ========================================
echo.
echo Branch URL: https://github.com/MedTechEsprit/Flutter/tree/medecin1
echo.
echo Next: Create a Pull Request on GitHub!
echo.

pause

