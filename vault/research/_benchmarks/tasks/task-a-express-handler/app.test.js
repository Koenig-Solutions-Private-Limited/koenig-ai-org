const request = require('supertest');
const app = require('./app');

// Smoke-test suite — enough to verify the refactor doesn't break contracts
// Real DB calls are mocked; runner replaces pool with a test-db connection if desired

jest.mock('pg', () => {
  const mockQuery = jest.fn();
  const mockRelease = jest.fn();
  const mockConnect = jest.fn().mockResolvedValue({ query: mockQuery, release: mockRelease });
  const Pool = jest.fn().mockImplementation(() => ({ query: mockQuery, connect: mockConnect }));
  return { Pool };
});

const { Pool } = require('pg');
const poolInstance = new Pool();

beforeEach(() => {
  poolInstance.query.mockReset();
  poolInstance.connect.mockReset();
  poolInstance.connect.mockResolvedValue({
    query: jest.fn().mockResolvedValue({ rows: [] }),
    release: jest.fn(),
  });
});

describe('GET /health', () => {
  it('returns ok', async () => {
    const res = await request(app).get('/health');
    expect(res.status).toBe(200);
    expect(res.body.status).toBe('ok');
  });
});

describe('POST /users/register', () => {
  it('400 when missing fields', async () => {
    const res = await request(app).post('/users/register').send({ email: 'a@b.com' });
    expect(res.status).toBe(400);
  });

  it('400 when password too short', async () => {
    poolInstance.query.mockResolvedValueOnce({ rows: [] }); // email check
    const res = await request(app).post('/users/register').send({ email: 'a@b.com', password: 'short' });
    expect(res.status).toBe(400);
  });
});

describe('POST /users/login', () => {
  it('401 when user not found', async () => {
    poolInstance.query.mockResolvedValueOnce({ rows: [] });
    const res = await request(app).post('/users/login').send({ email: 'x@x.com', password: 'password123' });
    expect(res.status).toBe(401);
  });
});

describe('GET /products', () => {
  it('returns product list', async () => {
    poolInstance.query
      .mockResolvedValueOnce({ rows: [{ id: 1, name: 'Widget', price: 9.99 }] })
      .mockResolvedValueOnce({ rows: [{ count: '1' }] });
    const res = await request(app).get('/products');
    expect(res.status).toBe(200);
    expect(res.body.products).toHaveLength(1);
  });
});
