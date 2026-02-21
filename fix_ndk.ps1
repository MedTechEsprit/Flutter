# Fix corrupted NDK 27 download
# Run this script once in PowerShell, then try flutter run again

$ndkPath = "C:\Users\mimou\AppData\Local\Android\sdk\ndk\27.0.12077973"

if (Test-Path $ndkPath) {
    Write-Host "Deleting corrupted NDK at: $ndkPath" -ForegroundColor Yellow
    Remove-Item -Recurse -Force $ndkPath
    Write-Host "Deleted successfully!" -ForegroundColor Green
} else {
    Write-Host "NDK 27 folder not found at: $ndkPath" -ForegroundColor Cyan
}

# List remaining NDK versions
$ndkRoot = "C:\Users\mimou\AppData\Local\Android\sdk\ndk"
Write-Host "`nInstalled NDK versions:" -ForegroundColor Cyan
Get-ChildItem $ndkRoot | Select-Object Name | Format-Table -AutoSize

Write-Host "`nDone! Now run: flutter run" -ForegroundColor Green

