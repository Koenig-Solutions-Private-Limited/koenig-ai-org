const express = require('express');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const { Pool } = require('pg');

const app = express();
app.use(express.json());

const pool = new Pool({ connectionString: process.env.DATABASE_URL });
const JWT_SECRET = process.env.JWT_SECRET || 'dev-secret';

// AUTH MIDDLEWARE — inlined, duplicated below for orders too
function authMiddleware(req, res, next) {
  const token = req.headers['authorization']?.split(' ')[1];
  if (!token) return res.status(401).json({ error: 'No token' });
  try {
    req.user = jwt.verify(token, JWT_SECRET);
    next();
  } catch {
    return res.status(401).json({ error: 'Invalid token' });
  }
}

// USERS -----------------------------------------------------------------------

app.post('/users/register', async (req, res) => {
  const { email, password, name, role } = req.body;
  if (!email || !password) return res.status(400).json({ error: 'Missing fields' });
  if (password.length < 8) return res.status(400).json({ error: 'Password too short' });
  if (!email.includes('@')) return res.status(400).json({ error: 'Invalid email' });
  try {
    const exists = await pool.query('SELECT id FROM users WHERE email = $1', [email]);
    if (exists.rows.length > 0) return res.status(409).json({ error: 'Email taken' });
    const hash = await bcrypt.hash(password, 10);
    const result = await pool.query(
      'INSERT INTO users (email, password_hash, name, role, created_at) VALUES ($1, $2, $3, $4, NOW()) RETURNING id, email, name, role',
      [email, hash, name, role || 'user']
    );
    const user = result.rows[0];
    const token = jwt.sign({ userId: user.id, role: user.role }, JWT_SECRET, { expiresIn: '7d' });
    res.status(201).json({ user, token });
  } catch (err) {
    console.error('Register error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

app.post('/users/login', async (req, res) => {
  const { email, password } = req.body;
  if (!email || !password) return res.status(400).json({ error: 'Missing fields' });
  try {
    const result = await pool.query('SELECT * FROM users WHERE email = $1', [email]);
    if (result.rows.length === 0) return res.status(401).json({ error: 'Invalid credentials' });
    const user = result.rows[0];
    const valid = await bcrypt.compare(password, user.password_hash);
    if (!valid) return res.status(401).json({ error: 'Invalid credentials' });
    const token = jwt.sign({ userId: user.id, role: user.role }, JWT_SECRET, { expiresIn: '7d' });
    res.json({ user: { id: user.id, email: user.email, name: user.name, role: user.role }, token });
  } catch (err) {
    console.error('Login error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

app.get('/users/me', authMiddleware, async (req, res) => {
  try {
    const result = await pool.query('SELECT id, email, name, role, created_at FROM users WHERE id = $1', [req.user.userId]);
    if (result.rows.length === 0) return res.status(404).json({ error: 'User not found' });
    res.json(result.rows[0]);
  } catch (err) {
    console.error('Get me error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

app.put('/users/me', authMiddleware, async (req, res) => {
  const { name, email } = req.body;
  if (!name && !email) return res.status(400).json({ error: 'Nothing to update' });
  try {
    const updates = [];
    const values = [];
    let idx = 1;
    if (name) { updates.push(`name = $${idx++}`); values.push(name); }
    if (email) {
      if (!email.includes('@')) return res.status(400).json({ error: 'Invalid email' });
      const exists = await pool.query('SELECT id FROM users WHERE email = $1 AND id != $2', [email, req.user.userId]);
      if (exists.rows.length > 0) return res.status(409).json({ error: 'Email taken' });
      updates.push(`email = $${idx++}`);
      values.push(email);
    }
    values.push(req.user.userId);
    const result = await pool.query(
      `UPDATE users SET ${updates.join(', ')}, updated_at = NOW() WHERE id = $${idx} RETURNING id, email, name, role`,
      values
    );
    res.json(result.rows[0]);
  } catch (err) {
    console.error('Update user error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

app.delete('/users/:id', authMiddleware, async (req, res) => {
  if (req.user.role !== 'admin' && req.user.userId !== parseInt(req.params.id)) {
    return res.status(403).json({ error: 'Forbidden' });
  }
  try {
    await pool.query('DELETE FROM users WHERE id = $1', [req.params.id]);
    res.status(204).send();
  } catch (err) {
    console.error('Delete user error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

// PRODUCTS --------------------------------------------------------------------

app.get('/products', async (req, res) => {
  const { category, minPrice, maxPrice, inStock, page = 1, limit = 20 } = req.query;
  try {
    const conditions = ['deleted_at IS NULL'];
    const values = [];
    let idx = 1;
    if (category) { conditions.push(`category = $${idx++}`); values.push(category); }
    if (minPrice) { conditions.push(`price >= $${idx++}`); values.push(parseFloat(minPrice)); }
    if (maxPrice) { conditions.push(`price <= $${idx++}`); values.push(parseFloat(maxPrice)); }
    if (inStock === 'true') { conditions.push(`stock_qty > 0`); }
    const offset = (parseInt(page) - 1) * parseInt(limit);
    values.push(parseInt(limit), offset);
    const result = await pool.query(
      `SELECT id, name, description, price, category, stock_qty, image_url, created_at FROM products WHERE ${conditions.join(' AND ')} ORDER BY created_at DESC LIMIT $${idx++} OFFSET $${idx}`,
      values
    );
    const countResult = await pool.query(
      `SELECT COUNT(*) FROM products WHERE ${conditions.slice(0, -0).join(' AND ')}`,
      values.slice(0, -2)
    );
    res.json({ products: result.rows, total: parseInt(countResult.rows[0].count), page: parseInt(page), limit: parseInt(limit) });
  } catch (err) {
    console.error('List products error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

app.get('/products/:id', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM products WHERE id = $1 AND deleted_at IS NULL', [req.params.id]);
    if (result.rows.length === 0) return res.status(404).json({ error: 'Product not found' });
    res.json(result.rows[0]);
  } catch (err) {
    console.error('Get product error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

app.post('/products', authMiddleware, async (req, res) => {
  if (req.user.role !== 'admin') return res.status(403).json({ error: 'Forbidden' });
  const { name, description, price, category, stock_qty, image_url } = req.body;
  if (!name || price === undefined) return res.status(400).json({ error: 'Missing required fields' });
  if (price < 0) return res.status(400).json({ error: 'Price cannot be negative' });
  if (stock_qty !== undefined && stock_qty < 0) return res.status(400).json({ error: 'Stock cannot be negative' });
  try {
    const result = await pool.query(
      'INSERT INTO products (name, description, price, category, stock_qty, image_url, created_at) VALUES ($1, $2, $3, $4, $5, $6, NOW()) RETURNING *',
      [name, description, price, category, stock_qty || 0, image_url]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error('Create product error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

app.put('/products/:id', authMiddleware, async (req, res) => {
  if (req.user.role !== 'admin') return res.status(403).json({ error: 'Forbidden' });
  const { name, description, price, category, stock_qty, image_url } = req.body;
  try {
    const exists = await pool.query('SELECT id FROM products WHERE id = $1 AND deleted_at IS NULL', [req.params.id]);
    if (exists.rows.length === 0) return res.status(404).json({ error: 'Product not found' });
    const updates = [];
    const values = [];
    let idx = 1;
    if (name !== undefined) { updates.push(`name = $${idx++}`); values.push(name); }
    if (description !== undefined) { updates.push(`description = $${idx++}`); values.push(description); }
    if (price !== undefined) {
      if (price < 0) return res.status(400).json({ error: 'Price cannot be negative' });
      updates.push(`price = $${idx++}`); values.push(price);
    }
    if (category !== undefined) { updates.push(`category = $${idx++}`); values.push(category); }
    if (stock_qty !== undefined) {
      if (stock_qty < 0) return res.status(400).json({ error: 'Stock cannot be negative' });
      updates.push(`stock_qty = $${idx++}`); values.push(stock_qty);
    }
    if (image_url !== undefined) { updates.push(`image_url = $${idx++}`); values.push(image_url); }
    if (updates.length === 0) return res.status(400).json({ error: 'Nothing to update' });
    values.push(req.params.id);
    const result = await pool.query(
      `UPDATE products SET ${updates.join(', ')}, updated_at = NOW() WHERE id = $${idx} RETURNING *`,
      values
    );
    res.json(result.rows[0]);
  } catch (err) {
    console.error('Update product error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

app.delete('/products/:id', authMiddleware, async (req, res) => {
  if (req.user.role !== 'admin') return res.status(403).json({ error: 'Forbidden' });
  try {
    const exists = await pool.query('SELECT id FROM products WHERE id = $1 AND deleted_at IS NULL', [req.params.id]);
    if (exists.rows.length === 0) return res.status(404).json({ error: 'Product not found' });
    await pool.query('UPDATE products SET deleted_at = NOW() WHERE id = $1', [req.params.id]);
    res.status(204).send();
  } catch (err) {
    console.error('Delete product error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

// ORDERS ----------------------------------------------------------------------

// NOTE: same authMiddleware duplicated — this is one of the refactoring targets
function authMiddlewareDup(req, res, next) {
  const token = req.headers['authorization']?.split(' ')[1];
  if (!token) return res.status(401).json({ error: 'No token' });
  try {
    req.user = jwt.verify(token, JWT_SECRET);
    next();
  } catch {
    return res.status(401).json({ error: 'Invalid token' });
  }
}

app.get('/orders', authMiddlewareDup, async (req, res) => {
  const { status, page = 1, limit = 20 } = req.query;
  try {
    const conditions = [];
    const values = [];
    let idx = 1;
    if (req.user.role !== 'admin') {
      conditions.push(`o.user_id = $${idx++}`);
      values.push(req.user.userId);
    }
    if (status) { conditions.push(`o.status = $${idx++}`); values.push(status); }
    const where = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';
    const offset = (parseInt(page) - 1) * parseInt(limit);
    values.push(parseInt(limit), offset);
    const result = await pool.query(
      `SELECT o.id, o.status, o.total_amount, o.created_at, o.shipping_address,
              u.email as user_email, u.name as user_name
       FROM orders o
       JOIN users u ON u.id = o.user_id
       ${where}
       ORDER BY o.created_at DESC
       LIMIT $${idx++} OFFSET $${idx}`,
      values
    );
    res.json({ orders: result.rows, page: parseInt(page), limit: parseInt(limit) });
  } catch (err) {
    console.error('List orders error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

app.get('/orders/:id', authMiddlewareDup, async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT o.*, u.email as user_email
       FROM orders o JOIN users u ON u.id = o.user_id
       WHERE o.id = $1`,
      [req.params.id]
    );
    if (result.rows.length === 0) return res.status(404).json({ error: 'Order not found' });
    const order = result.rows[0];
    if (req.user.role !== 'admin' && order.user_id !== req.user.userId) {
      return res.status(403).json({ error: 'Forbidden' });
    }
    const items = await pool.query(
      `SELECT oi.*, p.name as product_name, p.image_url
       FROM order_items oi JOIN products p ON p.id = oi.product_id
       WHERE oi.order_id = $1`,
      [req.params.id]
    );
    res.json({ ...order, items: items.rows });
  } catch (err) {
    console.error('Get order error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

app.post('/orders', authMiddlewareDup, async (req, res) => {
  const { items, shipping_address } = req.body;
  if (!items || !Array.isArray(items) || items.length === 0) {
    return res.status(400).json({ error: 'Items required' });
  }
  if (!shipping_address) return res.status(400).json({ error: 'Shipping address required' });
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    let totalAmount = 0;
    const validatedItems = [];
    for (const item of items) {
      if (!item.productId || !item.quantity || item.quantity < 1) {
        await client.query('ROLLBACK');
        return res.status(400).json({ error: 'Invalid item: ' + JSON.stringify(item) });
      }
      const product = await client.query(
        'SELECT id, price, stock_qty, name FROM products WHERE id = $1 AND deleted_at IS NULL FOR UPDATE',
        [item.productId]
      );
      if (product.rows.length === 0) {
        await client.query('ROLLBACK');
        return res.status(400).json({ error: `Product ${item.productId} not found` });
      }
      const p = product.rows[0];
      if (p.stock_qty < item.quantity) {
        await client.query('ROLLBACK');
        return res.status(400).json({ error: `Insufficient stock for ${p.name}` });
      }
      const lineTotal = p.price * item.quantity;
      totalAmount += lineTotal;
      validatedItems.push({ productId: p.id, quantity: item.quantity, unitPrice: p.price, lineTotal });
      await client.query('UPDATE products SET stock_qty = stock_qty - $1 WHERE id = $2', [item.quantity, p.id]);
    }
    const order = await client.query(
      'INSERT INTO orders (user_id, status, total_amount, shipping_address, created_at) VALUES ($1, $2, $3, $4, NOW()) RETURNING *',
      [req.user.userId, 'pending', totalAmount, shipping_address]
    );
    const orderId = order.rows[0].id;
    for (const item of validatedItems) {
      await client.query(
        'INSERT INTO order_items (order_id, product_id, quantity, unit_price) VALUES ($1, $2, $3, $4)',
        [orderId, item.productId, item.quantity, item.unitPrice]
      );
    }
    await client.query('COMMIT');
    res.status(201).json({ ...order.rows[0], items: validatedItems });
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Create order error:', err);
    res.status(500).json({ error: 'Server error' });
  } finally {
    client.release();
  }
});

app.patch('/orders/:id/status', authMiddlewareDup, async (req, res) => {
  if (req.user.role !== 'admin') return res.status(403).json({ error: 'Forbidden' });
  const { status } = req.body;
  const validStatuses = ['pending', 'confirmed', 'shipped', 'delivered', 'cancelled'];
  if (!validStatuses.includes(status)) {
    return res.status(400).json({ error: 'Invalid status: ' + status });
  }
  try {
    const result = await pool.query(
      'UPDATE orders SET status = $1, updated_at = NOW() WHERE id = $2 RETURNING *',
      [status, req.params.id]
    );
    if (result.rows.length === 0) return res.status(404).json({ error: 'Order not found' });
    if (status === 'cancelled') {
      const items = await pool.query('SELECT product_id, quantity FROM order_items WHERE order_id = $1', [req.params.id]);
      for (const item of items.rows) {
        await pool.query('UPDATE products SET stock_qty = stock_qty + $1 WHERE id = $2', [item.quantity, item.product_id]);
      }
    }
    res.json(result.rows[0]);
  } catch (err) {
    console.error('Update order status error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

// HEALTH ----------------------------------------------------------------------
app.get('/health', (req, res) => res.json({ status: 'ok', timestamp: new Date().toISOString() }));

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));

module.exports = app;
