const request = require('supertest');
const app = require('./app');

// These tests define the contract the AI agent must satisfy.
// All tests should pass after a correct implementation.
// runner: run `npm test` before and after — 0 pass before, all pass after = correctness_pass=1

describe('POST /auth/register', () => {
  it('registers a new user and returns accessToken + refreshToken cookie', async () => {
    const res = await request(app)
      .post('/auth/register')
      .send({ email: 'alice@test.com', password: 'Password1!', name: 'Alice' });
    expect(res.status).toBe(201);
    expect(res.body.accessToken).toBeDefined();
    expect(res.headers['set-cookie']).toBeDefined();
    const cookie = res.headers['set-cookie'].find(c => c.startsWith('refreshToken'));
    expect(cookie).toBeDefined();
    expect(cookie).toMatch(/HttpOnly/i);
  });

  it('returns 400 if email already registered', async () => {
    await request(app).post('/auth/register').send({ email: 'dup@test.com', password: 'Password1!', name: 'Dup' });
    const res = await request(app).post('/auth/register').send({ email: 'dup@test.com', password: 'Password1!', name: 'Dup2' });
    expect(res.status).toBe(400);
  });
});

describe('POST /auth/login', () => {
  beforeAll(async () => {
    await request(app).post('/auth/register').send({ email: 'bob@test.com', password: 'Password1!', name: 'Bob' });
  });

  it('returns accessToken for valid credentials', async () => {
    const res = await request(app).post('/auth/login').send({ email: 'bob@test.com', password: 'Password1!' });
    expect(res.status).toBe(200);
    expect(res.body.accessToken).toBeDefined();
  });

  it('returns 401 for wrong password', async () => {
    const res = await request(app).post('/auth/login').send({ email: 'bob@test.com', password: 'wrong' });
    expect(res.status).toBe(401);
  });
});

describe('POST /auth/refresh', () => {
  it('rotates tokens and returns new accessToken', async () => {
    const reg = await request(app).post('/auth/register').send({ email: 'carol@test.com', password: 'Password1!', name: 'Carol' });
    const cookie = reg.headers['set-cookie'].find(c => c.startsWith('refreshToken'));
    const cookieValue = cookie.split(';')[0];
    const res = await request(app).post('/auth/refresh').set('Cookie', cookieValue);
    expect(res.status).toBe(200);
    expect(res.body.accessToken).toBeDefined();
  });

  it('returns 401 without refresh token', async () => {
    const res = await request(app).post('/auth/refresh');
    expect(res.status).toBe(401);
  });
});

describe('GET /me', () => {
  it('returns user for valid access token', async () => {
    const reg = await request(app).post('/auth/register').send({ email: 'dave@test.com', password: 'Password1!', name: 'Dave' });
    const res = await request(app).get('/me').set('Authorization', `Bearer ${reg.body.accessToken}`);
    expect(res.status).toBe(200);
    expect(res.body.email).toBe('dave@test.com');
  });

  it('returns 401 without token', async () => {
    const res = await request(app).get('/me');
    expect(res.status).toBe(401);
  });
});

describe('POST /auth/logout', () => {
  it('invalidates refresh token', async () => {
    const reg = await request(app).post('/auth/register').send({ email: 'eve@test.com', password: 'Password1!', name: 'Eve' });
    const cookie = reg.headers['set-cookie'].find(c => c.startsWith('refreshToken'));
    const cookieValue = cookie.split(';')[0];
    await request(app).post('/auth/logout').set('Cookie', cookieValue).set('Authorization', `Bearer ${reg.body.accessToken}`);
    const refresh = await request(app).post('/auth/refresh').set('Cookie', cookieValue);
    expect(refresh.status).toBe(401);
  });
});
