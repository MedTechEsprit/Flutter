# DiabCare - Smart Emulator Fix (Auto-detects Pixel 7/8)
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "   DiabCare - Smart Emulator Fix & Run" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

Set-Location "C:\Users\mimou\Flutter-main"

# Step 1: Clean Flutter
Write-Host "[1/5] Cleaning Flutter build..." -ForegroundColor Yellow
flutter clean | Out-Null
flutter pub get | Out-Null
Write-Host "     Done." -ForegroundColor Green

# Step 2: Detect which Pixel emulator exists
Write-Host "[2/5] Detecting available emulators..." -ForegroundColor Yellow
$avdPath = Join-Path $env:USERPROFILE ".android\avd"

$availableEmulators = @()
if (Test-Path (Join-Path $avdPath "Pixel_8_API_34.avd")) {
    $availableEmulators += "Pixel_8_API_34"
}
if (Test-Path (Join-Path $avdPath "Pixel_7_API_34.avd")) {
    $availableEmulators += "Pixel_7_API_34"
}

# Try other naming patterns
Get-ChildItem -Path $avdPath -Directory | Where-Object { $_.Name -match "Pixel.*8" } | ForEach-Object {
    $name = $_.Name -replace "\.avd$", ""
    if ($availableEmulators -notcontains $name) {
        $availableEmulators += $name
    }
}

if ($availableEmulators.Count -eq 0) {
    Write-Host "     [WARNING] No Pixel emulator found!" -ForegroundColor Red
    Write-Host "     Please create a Pixel 8 emulator in Android Studio:" -ForegroundColor Yellow
    Write-Host "     Tools -> Device Manager -> Create Device -> Pixel 8" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "     For now, I'll try to run on any available emulator..." -ForegroundColor Yellow
} else {
    $targetEmulator = $availableEmulators[0]
    Write-Host "     Found: $targetEmulator" -ForegroundColor Green

    # Step 3: Wipe emulator data
    Write-Host "[3/5] Wiping emulator data..." -ForegroundColor Yellow
    $targetAvdPath = Join-Path $avdPath "$targetEmulator.avd"
    if (Test-Path $targetAvdPath) {
        Remove-Item -Path (Join-Path $targetAvdPath "cache") -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -Path (Join-Path $targetAvdPath "*.lock") -Force -ErrorAction SilentlyContinue
        Write-Host "     Data wiped for $targetEmulator" -ForegroundColor Green
    }

    # Step 4: Stop existing emulator
    Write-Host "[4/5] Stopping existing emulator processes..." -ForegroundColor Yellow
    Get-Process -Name "qemu-system-*" -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep -Seconds 2
    Write-Host "     Done." -ForegroundColor Green
}

# Step 5: Run Flutter
Write-Host "[5/5] Running Flutter app..." -ForegroundColor Yellow
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "   Starting DiabCare on Pixel 8..." -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "If the emulator is not running, start it manually:" -ForegroundColor Yellow
Write-Host "Tools -> Device Manager -> Start Pixel 8" -ForegroundColor Yellow
Write-Host ""

flutter run

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Done!" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

