# Tuition Media App Backend

A Node.js Express backend for a Tuition Media App with JWT authentication and MySQL database.

## Features

- User authentication with JWT
- Role-based access (STUDENT, TEACHER)
- Student and Teacher profiles
- Tuition posts by students
- Teacher responses to posts

## Setup

1. Install dependencies:
   ```
   npm install
   ```

2. Set up MySQL database:
   - Create a MySQL database
   - Run the `init.sql` script to create tables

3. Configure environment variables:
   - Copy `.env` file and update with your database credentials and JWT secret

4. Start the server:
   ```
   npm run dev
   ```

## API Endpoints

### Authentication
- POST /api/auth/register
- POST /api/auth/login

### Student
- POST /api/student/profile
- GET /api/student/profile

### Teacher
- POST /api/teacher/profile
- GET /api/teacher/profile

### Posts
- POST /api/posts (student only)
- GET /api/posts (open posts for teachers, own posts for students)
- DELETE /api/posts/:id (student only)

### Responses
- POST /api/posts/:postId/respond (teacher only)
- GET /api/posts/:postId/responses (student owns post)

## Technologies

- Node.js
- Express.js
- MySQL
- JWT
- bcrypt