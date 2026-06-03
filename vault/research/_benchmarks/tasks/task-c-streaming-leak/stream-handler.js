// PLANTED LEAK: listener registered on `dataSource` per request but never removed on disconnect.
// Over time, disconnected clients accumulate as ghost listeners on the shared DataSource.
// Node.js default MaxListenersExceededWarning fires at 10 concurrent historical connections.
// Fix: call dataSource.removeListener('data', handler) inside the 'close' event handler.

function handleStream(req, res, dataSource) {
  res.setHeader('Content-Type', 'text/event-stream');
  res.setHeader('Cache-Control', 'no-cache');
  res.setHeader('Connection', 'keep-alive');
  res.flushHeaders();

  const handler = (payload) => {
    if (res.writableEnded) return;
    res.write(`data: ${JSON.stringify(payload)}\n\n`);
  };

  // LEAK: this listener is added every time a client connects but is never removed
  dataSource.on('data', handler);

  req.on('close', () => {
    // MISSING: dataSource.removeListener('data', handler);
    res.end();
  });
}

module.exports = { handleStream };
