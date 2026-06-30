const express = require('express');
const cookieParser = require('cookie-parser');

const app = express();
app.use(express.json());
app.use(cookieParser());

// In-memory user store (replace with DB in production)
const users = new Map(); // email -> { id, email, passwordHash, refreshTokens: Set }

// TODO: implement POST /auth/register
// Requirements:
//   - Accept { email, password, name }
//   - Hash password with bcrypt (saltRounds=10)
//   - Return 201 with { user: { id, email, name }, accessToken }
//   - Set httpOnly cookie "refreshToken" (sameSite: strict, secure in prod)
//   - Return 400 if email already registered
app.post('/auth/register', (req, res) => {
  res.status(501).json({ error: 'Not implemented' });
});

// TODO: implement POST /auth/login
// Requirements:
//   - Accept { email, password }
//   - Verify password with bcrypt.compare
//   - Issue access token (JWT, 15-min expiry) + refresh token (JWT, 7-day expiry)
//   - Set httpOnly refreshToken cookie; return accessToken in body
//   - Return 401 if credentials invalid
app.post('/auth/login', (req, res) => {
  res.status(501).json({ error: 'Not implemented' });
});

// TODO: implement POST /auth/refresh
// Requirements:
//   - Read refreshToken from httpOnly cookie
//   - Verify token signature + expiry
//   - Rotate: invalidate old refresh token, issue new access + refresh pair
//   - Return 401 if token missing, expired, or already invalidated
app.post('/auth/refresh', (req, res) => {
  res.status(501).json({ error: 'Not implemented' });
});

// TODO: implement POST /auth/logout
// Requirements:
//   - Invalidate the current refreshToken (remove from user's Set)
//   - Clear the httpOnly cookie
//   - Return 204
app.post('/auth/logout', (req, res) => {
  res.status(501).json({ error: 'Not implemented' });
});

// TODO: implement GET /me  (protected route)
// Requirements:
//   - Verify Authorization: Bearer <accessToken>
//   - Return { id, email, name } for authenticated user
//   - Return 401 if token missing or invalid
app.get('/me', (req, res) => {
  res.status(501).json({ error: 'Not implemented' });
});

// CSRF-protected example route (add middleware as part of implementation)
// TODO: add CSRF protection middleware to state-changing endpoints
app.post('/profile/update', (req, res) => {
  res.status(501).json({ error: 'Not implemented' });
});

app.get('/health', (req, res) => res.json({ status: 'ok' }));

const PORT = process.env.PORT || 3001;
app.listen(PORT, () => console.log(`Task B scaffold running on port ${PORT}`));

module.exports = app;
