// API Configuration
// Use machine IP for Chrome (works from any machine on the network)
// For emulator: change to http://10.0.2.2:3000
// For local: http://localhost:3000
const API_BASE = 'http://192.168.43.62:3000/api';
const STORAGE_KEYS = {
  TOKEN: 'tuition_token',
  USER: 'tuition_user',
};

let currentPostId = null;

// Initialize
document.addEventListener('DOMContentLoaded', () => {
  checkAuthStatus();
  setupEventListeners();
});

// Check Authentication Status
function checkAuthStatus() {
  chrome.storage.local.get([STORAGE_KEYS.TOKEN, STORAGE_KEYS.USER], (result) => {
    if (result[STORAGE_KEYS.TOKEN] && result[STORAGE_KEYS.USER]) {
      const user = result[STORAGE_KEYS.USER];
      if (user.role === 'STUDENT') {
        showStudentView();
      } else if (user.role === 'TEACHER') {
        showTeacherView();
        loadPosts();
      }
    } else {
      showLogin();
    }
  });
}

// Show Views
function showLogin() {
  document.getElementById('loginContainer').style.display = 'block';
  document.getElementById('studentContainer').style.display = 'none';
  document.getElementById('teacherContainer').style.display = 'none';
}

function showStudentView() {
  document.getElementById('loginContainer').style.display = 'none';
  document.getElementById('studentContainer').style.display = 'block';
  document.getElementById('teacherContainer').style.display = 'none';
}

function showTeacherView() {
  document.getElementById('loginContainer').style.display = 'none';
  document.getElementById('studentContainer').style.display = 'none';
  document.getElementById('teacherContainer').style.display = 'block';
}

// Setup Event Listeners
function setupEventListeners() {
  // Login
  document.getElementById('loginBtn').addEventListener('click', handleLogin);
  document.getElementById('loginEmail').addEventListener('keypress', (e) => {
    if (e.key === 'Enter') handleLogin();
  });
  document.getElementById('loginPassword').addEventListener('keypress', (e) => {
    if (e.key === 'Enter') handleLogin();
  });

  // Student
  document.getElementById('createPostBtn').addEventListener('click', handleCreatePost);
  document.getElementById('logoutBtnStudent').addEventListener('click', handleLogout);

  // Teacher
  document.getElementById('logoutBtnTeacher').addEventListener('click', handleLogout);
  document.getElementById('submitResponseBtn').addEventListener('click', handleSubmitResponse);
  
  // Modal
  document.querySelector('.close').addEventListener('click', closeModal);
}

// Login Handler
async function handleLogin() {
  const email = document.getElementById('loginEmail').value.trim();
  const password = document.getElementById('loginPassword').value;
  
  if (!email || !password) {
    showError('loginError', 'Please fill all fields');
    return;
  }
  
  try {
    const response = await fetch(`${API_BASE}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password }),
    });
    
    const data = await response.json();
    
    if (data.token && data.user) {
      chrome.storage.local.set({
        [STORAGE_KEYS.TOKEN]: data.token,
        [STORAGE_KEYS.USER]: data.user,
      }, () => {
        checkAuthStatus();
      });
    } else {
      showError('loginError', data.message || 'Login failed');
    }
  } catch (error) {
    showError('loginError', 'Connection error');
  }
}

// Logout Handler
function handleLogout() {
  chrome.storage.local.remove([STORAGE_KEYS.TOKEN, STORAGE_KEYS.USER], () => {
    showLogin();
  });
}

// Student: Create Post
async function handleCreatePost() {
  const subject = document.getElementById('postTitle').value.trim();
  const description = document.getElementById('postDescription').value.trim();
  const classLevel = document.getElementById('postClassLevel').value;
  const daysPerWeek = document.getElementById('postDaysPerWeek').value;
  const salary = document.getElementById('postSalary').value;
  const location = document.getElementById('postLocation').value.trim();
  
  // Clear messages
  document.getElementById('studentError').textContent = '';
  document.getElementById('studentSuccess').textContent = '';
  
  if (!subject || !description || !classLevel || !daysPerWeek || !salary || !location) {
    showError('studentError', 'Please fill all fields');
    return;
  }
  
  try {
    const result = await chrome.storage.local.get(STORAGE_KEYS.TOKEN);
    const token = result[STORAGE_KEYS.TOKEN];
    
    const response = await fetch(`${API_BASE}/posts`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`,
      },
      body: JSON.stringify({
        subject,
        description,
        class_level: classLevel,
        days_per_week: parseInt(daysPerWeek),
        salary: parseInt(salary),
        location,
      }),
    });
    
    const data = await response.json();
    
    if (response.ok) {
      showSuccess('studentSuccess', 'Post created successfully!');
      // Clear form
      document.getElementById('postTitle').value = '';
      document.getElementById('postDescription').value = '';
      document.getElementById('postClassLevel').value = '';
      document.getElementById('postDaysPerWeek').value = '';
      document.getElementById('postSalary').value = '';
      document.getElementById('postLocation').value = '';
    } else {
      showError('studentError', data.message || 'Failed to create post');
    }
  } catch (error) {
    showError('studentError', 'Connection error');
  }
}

// Teacher: Load Posts
async function loadPosts() {
  const postsList = document.getElementById('postsList');
  postsList.innerHTML = '<div class="empty-state"><p>Loading posts...</p></div>';
  
  try {
    const result = await chrome.storage.local.get(STORAGE_KEYS.TOKEN);
    const token = result[STORAGE_KEYS.TOKEN];
    
    const response = await fetch(`${API_BASE}/posts`, {
      headers: {
        'Authorization': `Bearer ${token}`,
      },
    });
    
    const data = await response.json();
    const posts = Array.isArray(data) ? data : data.posts || [];
    
    if (posts.length === 0) {
      postsList.innerHTML = '<div class="empty-state"><p>No posts available</p></div>';
      return;
    }
    
    // Filter out posts teacher has already responded to
    const filteredPosts = [];
    for (const post of posts) {
      try {
        const hasRespondedResponse = await fetch(`${API_BASE}/posts/${post.id}/hasResponded`, {
          headers: {
            'Authorization': `Bearer ${token}`,
          },
        });
        const hasRespondedData = await hasRespondedResponse.json();
        if (!hasRespondedData.hasResponded) {
          filteredPosts.push(post);
        }
      } catch (error) {
        // If check fails, include the post anyway
        filteredPosts.push(post);
      }
    }
    
    if (filteredPosts.length === 0) {
      postsList.innerHTML = '<div class="empty-state"><p>No new posts to respond to</p></div>';
      return;
    }
    
    postsList.innerHTML = filteredPosts.map(post => `
      <div class="post-card">
        <div class="post-title">${escapeHtml(post.subject)}</div>
        <div class="post-detail"><strong>Class:</strong> ${escapeHtml(post.class_level)}</div>
        <div class="post-detail"><strong>Days/Week:</strong> ${post.days_per_week}</div>
        <div class="post-detail"><strong>Salary:</strong> ${post.salary} BDT</div>
        <div class="post-detail"><strong>Location:</strong> ${escapeHtml(post.location)}</div>
        <div class="post-detail"><strong>Posted by:</strong> ${escapeHtml(post.student_name || 'Student')}</div>
        <button class="respond-btn" data-post-id="${post.id}">Respond</button>
      </div>
    `).join('');
    
    // Add event listeners to respond buttons
    document.querySelectorAll('.respond-btn').forEach(btn => {
      btn.addEventListener('click', (e) => {
        currentPostId = e.target.dataset.postId;
        openModal();
      });
    });
  } catch (error) {
    postsList.innerHTML = '<div class="empty-state"><p>Error loading posts</p></div>';
  }
}

// Teacher: Submit Response
async function handleSubmitResponse() {
  const proposedSalary = document.getElementById('proposedSalary').value;
  const message = document.getElementById('responseMessage').value.trim();
  document.getElementById('teacherError').textContent = '';
  
  if (!message) {
    showError('teacherError', 'Please enter a message');
    return;
  }
  
  if (!currentPostId) {
    showError('teacherError', 'Invalid post');
    return;
  }
  
  try {
    const result = await chrome.storage.local.get(STORAGE_KEYS.TOKEN);
    const token = result[STORAGE_KEYS.TOKEN];
    
    // 1. Submit the response
    const response = await fetch(`${API_BASE}/posts/${currentPostId}/respond`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`,
      },
      body: JSON.stringify({
        proposed_salary: proposedSalary ? parseInt(proposedSalary) : null,
        message,
      }),
    });
    
    const data = await response.json();
    
    if (response.ok) {
      // 2. Create a conversation for messaging
      try {
        await fetch(`${API_BASE}/messages/${currentPostId}/start`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${token}`,
          },
        });
      } catch (error) {
        // Conversation creation error is not critical
        console.log('Conversation creation warning:', error);
      }
      
      closeModal();
      document.getElementById('responseMessage').value = '';
      document.getElementById('proposedSalary').value = '';
      alert('Response sent successfully!');
      loadPosts(); // Refresh posts
    } else {
      showError('teacherError', data.message || 'Failed to send response');
    }
  } catch (error) {
    showError('teacherError', 'Connection error');
  }
}

// Modal Functions
function openModal() {
  document.getElementById('responseModal').style.display = 'flex';
}

function closeModal() {
  document.getElementById('responseModal').style.display = 'none';
  document.getElementById('responseMessage').value = '';
  document.getElementById('proposedSalary').value = '';
  document.getElementById('teacherError').textContent = '';
}

// Utility Functions
function showError(elementId, message) {
  document.getElementById(elementId).textContent = message;
}

function showSuccess(elementId, message) {
  document.getElementById(elementId).textContent = message;
}

function escapeHtml(text) {
  const div = document.createElement('div');
  div.textContent = text;
  return div.innerHTML;
}
