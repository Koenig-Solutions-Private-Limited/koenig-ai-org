const http = require('http');
const DataSource = require('./data-source');
const { handleStream } = require('./stream-handler');

const dataSource = new DataSource(200);
dataSource.start();

const server = http.createServer((req, res) => {
  if (req.method === 'GET' && req.url === '/stream') {
    handleStream(req, res, dataSource);
    return;
  }

  if (req.method === 'GET' && req.url === '/health') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({
      status: 'ok',
      listenerCount: dataSource.listenerCount('data'),
      ts: Date.now(),
    }));
    return;
  }

  res.writeHead(404);
  res.end('Not found');
});

const PORT = process.env.PORT || 3002;
server.listen(PORT, () => {
  console.log(`Task C streaming server on port ${PORT}`);
  console.log('GET /stream  — SSE stream (leak here)');
  console.log('GET /health  — shows listener count (watch it grow)');
});

module.exports = { server, dataSource };
