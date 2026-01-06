# Tuition Media App

A comprehensive Flutter application for connecting students with tutors, built with Node.js backend.

## Features

- **User Authentication**: JWT-based login and registration for students and teachers
- **Profile Management**: Detailed profiles for both user types
- **Tuition Posts**: Students can create posts for tuition requirements
- **Teacher Responses**: Teachers can respond to posts with proposals
- **Real-time Messaging**: Chat functionality between students and teachers
- **Modern UI**: Material 3 design with responsive layout

## Tech Stack

### Backend
- Node.js
- Express.js
- MySQL
- JWT Authentication
- bcrypt Password Hashing

### Frontend
- Flutter
- Provider (State Management)
- HTTP Client
- Shared Preferences

## Setup Instructions

### Backend Setup

1. Navigate to backend directory:
   ```bash
   cd backend
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Set up MySQL database and run the SQL script:
   ```sql
   -- Run init.sql in your MySQL database
   ```

4. Update environment variables in `.env`:
   ```
   DB_HOST=localhost
   DB_USER=your_db_user
   DB_PASSWORD=your_db_password
   DB_NAME=tuition_media_app
   JWT_SECRET=your_jwt_secret
   PORT=3000
   ```

5. Start the backend server:
   ```bash
   npm run dev
   ```

### Frontend Setup

1. Navigate to Flutter project:
   ```bash
   cd tutionmediaapp
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. For Android emulator, update API URL in `lib/services/api_service.dart`:
   ```dart
   static const String baseUrl = 'http://10.0.2.2:3000/api';
   ```

4. Run the app:
   ```bash
   flutter run
   ```

## API Endpoints

### Authentication
- `POST /api/auth/register` - User registration
- `POST /api/auth/login` - User login

### Profiles
- `POST /api/student/profile` - Create/update student profile
- `GET /api/student/profile` - Get student profile
- `POST /api/teacher/profile` - Create/update teacher profile
- `GET /api/teacher/profile` - Get teacher profile

### Posts
- `POST /api/posts` - Create tuition post (student)
- `GET /api/posts` - Get posts (filtered by role)
- `DELETE /api/posts/:id` - Delete post (student)

### Responses
- `POST /api/posts/:postId/respond` - Respond to post (teacher)
- `GET /api/posts/:postId/responses` - Get responses (student)

### Messaging
- `GET /api/messages` - Get user conversations
- `POST /api/messages/:postId/start` - Start conversation
- `GET /api/messages/:conversationId/messages` - Get messages
- `POST /api/messages/:conversationId/messages` - Send message

## Database Schema

- `users` - User authentication data
- `student_profiles` - Student profile information
- `teacher_profiles` - Teacher profile information
- `tuition_posts` - Tuition requirements
- `responses` - Teacher responses to posts
- `conversations` - Chat conversations
- `messages` - Individual messages

## Features Overview

### For Students
- Register and create detailed profile
- Post tuition requirements with subject, class, salary, location
- View responses from teachers
- Chat with interested teachers

### For Teachers
- Register and create comprehensive profile
- Browse open tuition posts
- Respond to posts with salary proposals
- Chat with students

## Security
- Password hashing with bcrypt
- JWT token authentication
- Role-based access control
- Input validation and sanitization

## Contributing
1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License
This project is licensed under the MIT License.# Tution-Media-App
