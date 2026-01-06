@echo off
echo Setting up port forwarding for Android devices via USB...
echo.
adb reverse tcp:3000 tcp:3000
if %errorlevel% equ 0 (
    echo Success! Port 3000 is now forwarded.
    echo Your Android device can now access the backend at localhost:3000
) else (
    echo Failed to set up port forwarding.
    echo Make sure:
    echo - Your device is connected via USB
    echo - USB debugging is enabled
    echo - ADB is installed and in your PATH
)
echo.
pause
