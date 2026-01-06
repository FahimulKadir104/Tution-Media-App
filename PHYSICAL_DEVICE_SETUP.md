# Device Setup Guide (USB Connection)

## Quick Setup - Works for All Devices!

### Step 1: Start Backend Server

```bash
cd backend
npm start
```

The server will start on `http://localhost:3000`

### Step 2: Set Up Port Forwarding (For Android Only)

#### Windows:
```bash
adb reverse tcp:3000 tcp:3000
```

Or simply run the provided script:
```bash
setup-android.bat
```

#### Mac/Linux:
```bash
adb reverse tcp:3000 tcp:3000
```

### Step 3: Run Your App

- **Web**: `flutter run -d chrome`
- **Android Emulator**: `flutter run` (port forwarding happens automatically)
- **Physical Device (USB)**: `flutter run` (after running adb reverse command above)

## That's It!

The app now uses `localhost:3000` for all platforms. The `adb reverse` command makes your Android device's localhost point to your computer's localhost through the USB connection.

## Troubleshooting

**"adb is not recognized":**
- Make sure Android SDK platform-tools is installed
- Add it to your PATH or use full path: `C:\Users\YourName\AppData\Local\Android\Sdk\platform-tools\adb.exe`

**Connection still fails:**
- Verify backend is running: open `http://localhost:3000` in your browser
- Re-run the adb reverse command
- Restart your app

**USB debugging:**
- Enable Developer Options on your Android device
- Enable USB debugging
- Accept the computer's RSA key when prompted
