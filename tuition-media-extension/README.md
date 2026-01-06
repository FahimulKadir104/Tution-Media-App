# Tuition Media Chrome Extension

A simple Chrome extension for quick tuition post management.

## Features

### For Students
- **Quick Post Creation**: Create tuition posts directly from the extension
  - Add title, description, class level, subjects, salary, and location
  - Instant submission to backend
  - Form validation

### For Teachers
- **Browse Posts**: View all available tuition posts
  - See student requirements at a glance
  - Class level, subjects, salary, and location details
- **Quick Response**: Respond to posts with one click
  - Modal popup for easy response submission
  - Direct communication with students

## Installation

1. Open Chrome and navigate to `chrome://extensions/`
2. Enable **Developer mode** (toggle in top right)
3. Click **Load unpacked**
4. Select the `tuition-media-extension` folder
5. The extension icon will appear in your toolbar

## Usage

### First Time Setup
1. Click the extension icon in Chrome toolbar
2. Sign in with your Tuition Media account (email and password)
3. Based on your role, you'll see:
   - **Students**: Post creation form
   - **Teachers**: Available posts list

### For Students
1. Fill in all required fields:
   - Post title
   - Description
   - Class level (dropdown)
   - Subjects
   - Salary (in BDT)
   - Location
2. Click **Create Post**
3. Success message will appear, form will reset

### For Teachers
1. Browse through available posts
2. Click **Respond** on any post
3. Enter your response message in the modal
4. Click **Send Response**
5. Your response will be sent to the student

## Requirements

- Backend server running on `http://localhost:3000`
- Active internet connection
- Google Chrome browser
- Valid Tuition Media account (Student or Teacher)

## API Endpoints Used

- `POST /api/auth/login` - User authentication
- `POST /api/post` - Create new post (Students)
- `GET /api/post/all` - Fetch all posts (Teachers)
- `POST /api/response` - Send response to post (Teachers)

## File Structure

```
tuition-media-extension/
├── manifest.json          # Extension configuration
├── popup.html            # Main UI
├── popup.css             # Styling
├── popup.js              # Logic
├── background.js         # Background script
├── icons/                # Extension icons
└── README.md             # This file
```

## Troubleshooting

**Login fails:**
- Verify backend server is running on `http://localhost:3000`
- Check email and password are correct
- Ensure you have registered account

**Posts not loading:**
- Check internet connection
- Verify backend server is accessible
- Check browser console for errors (F12)

**Cannot create post:**
- Ensure all fields are filled
- Check salary is a valid number
- Verify you are logged in as a Student

**Cannot respond to post:**
- Ensure you are logged in as a Teacher
- Check response message is not empty
- Verify backend is accessible

## Security Notes

- Login tokens are stored in `chrome.storage.local`
- Use HTTPS in production environment
- Never share your access tokens
- Logout when using shared computers

## Version

1.0.0 - Initial release with core student/teacher features
