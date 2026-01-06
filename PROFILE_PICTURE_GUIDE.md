# Profile Picture System - Implementation Guide

## Features Implemented ✅

### 1. **Database Schema**
- Added `profile_picture_url` column to `users` table
- Stores URLs or base64 encoded images

### 2. **Backend API**
- **PUT `/api/profile-picture/update`** - Upload/update profile picture (authenticated)
- **GET `/api/profile-picture/:userId`** - Fetch profile picture URL by user ID

### 3. **User Model (`User.js`)**
- `updateProfilePicture(userId, profilePictureUrl)` - Update user's profile picture
- `getProfilePicture(userId)` - Retrieve profile picture URL

### 4. **Frontend Services**
- `ApiService.updateProfilePicture(token, profilePictureUrl)` - Send to backend
- `ApiService.getProfilePicture(userId)` - Fetch from backend

### 5. **UI Components**
✅ **StudentProfileScreen**
- Clickable circular profile picture (120x120)
- Camera icon overlay for visual guidance
- Image picker integration
- Real-time preview of selected image

✅ **TeacherProfileScreen**
- Same functionality as student profile
- Complete with verified badge integration

✅ **DashboardScreen - Drawer**
- Shows profile picture in UserAccountsDrawerHeader
- Displays actual user profile picture with fallback to initials
- Network image loading with error handling

✅ **ChatScreen - Message Bubbles**
- Profile pictures displayed next to each message
- Sender avatar on message bubbles
- Responder avatar with profile picture
- Fallback to initials if no picture

## Installation Steps

### 1. **Run Flutter Pub Get**
```bash
cd tutionmediaapp
flutter pub get
```

This will install:
- `image_picker: ^1.0.0` - Image selection
- `firebase_storage: ^11.0.0` - Cloud storage for images
- `firebase_core: ^2.24.0` - Firebase initialization

### 2. **Firebase Setup (Optional but Recommended)**
For production, set up Firebase Storage to handle image uploads:

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Initialize Firebase
firebase login
firebase init

# Create storage rules for image uploads
```

### 3. **Update Backend Routes (app.js)**
Routes already added:
```javascript
app.use('/api/profile-picture', profilePictureRoutes);
```

### 4. **Database Migration**
Run this SQL on your backend:
```sql
ALTER TABLE users ADD COLUMN profile_picture_url VARCHAR(500);
```

## Current Implementation Status

### Ready to Use ✅
- Image picker UI
- Profile picture display (drawer, chat, profile screens)
- API endpoints for upload/retrieve
- Database schema updates

### TODO - Image Upload Handling
Currently, the image picker saves locally and uses a placeholder. To complete:

**Option 1: Firebase Storage (Recommended)**
```dart
// In _pickImage() method, upload to Firebase:
final storageRef = FirebaseStorage.instance.ref()
    .child('profile_pictures/${auth.user!.id}.jpg');
await storageRef.putFile(File(_selectedImage!.path));
final url = await storageRef.getDownloadURL();
await ApiService.updateProfilePicture(auth.token!, url);
```

**Option 2: Base64 Upload**
```dart
// Convert image to base64 and upload
final bytes = File(_selectedImage!.path).readAsBytesSync();
final base64Image = 'data:image/jpg;base64,' + base64Encode(bytes);
await ApiService.updateProfilePicture(auth.token!, base64Image);
```

**Option 3: Multipart Form Data**
```dart
// Upload as multipart/form-data to backend
// Backend stores in local directory or cloud storage
```

## Testing the Feature

1. **Navigate to Profile Screen**
   - Tap profile settings in drawer
   - Click on profile picture area
   - Select an image from gallery

2. **View in Other Screens**
   - Drawer header shows updated profile picture
   - Chat messages display user avatars
   - Dashboard shows in conversations list

3. **Backend Verification**
   - Check database: `SELECT profile_picture_url FROM users WHERE id = ?`
   - Verify URLs are stored correctly

## API Examples

### Update Profile Picture
```bash
curl -X PUT http://localhost:3001/api/profile-picture/update \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"profilePictureUrl": "https://example.com/image.jpg"}'
```

### Get Profile Picture
```bash
curl http://localhost:3001/api/profile-picture/1
# Response: {"profilePictureUrl": "https://example.com/image.jpg"}
```

## File Changes Summary

**Backend Files:**
- `models/User.js` - Added profile picture methods
- `controllers/authController.js` - Include in login response
- `controllers/profilePictureController.js` - New controller
- `routes/profilePictureRoutes.js` - New routes
- `app.js` - Added routes
- `init.sql` - Database schema update

**Frontend Files:**
- `pubspec.yaml` - Added packages
- `services/api_service.dart` - New API methods
- `screens/student_profile_screen.dart` - Image picker UI
- `screens/teacher_profile_screen.dart` - Image picker UI
- `screens/dashboard_screen.dart` - Drawer profile display
- `screens/chat_screen.dart` - Message avatar display

## Next Steps

1. **Complete Image Upload Handler**
   - Choose Firebase or alternative storage
   - Implement in `_pickImage()` methods

2. **Add Image Validation**
   - Check file size (< 5MB)
   - Validate image format (JPG, PNG)

3. **Add Compression**
   - Reduce image size before upload
   - Improve load times

4. **Error Handling**
   - Better error messages for upload failures
   - Retry mechanism

5. **Permissions (Android/iOS)**
   - Request camera/gallery permissions
   - Handle permission denials

