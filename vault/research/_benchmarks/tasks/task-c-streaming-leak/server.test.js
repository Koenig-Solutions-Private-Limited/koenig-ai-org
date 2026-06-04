const { EventEmitter } = require('events');
const { handleStream } = require('./stream-handler');

// Correctness criteria for Task C:
// After fix, listener count on dataSource must return to pre-connection level
// after a client disconnects. Test verifies the leak is plugged.

function makeMockReq() {
  const emitter = new EventEmitter();
  return {
    on: (event, cb) => emitter.on(event, cb),
    _emit: (event) => emitter.emit(event),
  };
}

function makeMockRes() {
  return {
    setHeader: jest.fn(),
    flushHeaders: jest.fn(),
    write: jest.fn(),
    end: jest.fn(),
    writableEnded: false,
  };
}

describe('stream-handler memory leak fix', () => {
  it('removes listener from dataSource when client disconnects', () => {
    const DataSource = require('./data-source');
    const ds = new DataSource(10000); // slow interval, no actual fires needed

    const before = ds.listenerCount('data');

    const req = makeMockReq();
    const res = makeMockRes();
    handleStream(req, res, ds);

    expect(ds.listenerCount('data')).toBe(before + 1);

    // Simulate client disconnect
    req._emit('close');

    // After disconnect, listener must be gone
    expect(ds.listenerCount('data')).toBe(before);
  });

  it('does not write to ended response after disconnect', () => {
    const DataSource = require('./data-source');
    const ds = new DataSource(50);
    ds.start();

    const req = makeMockReq();
    const res = makeMockRes();
    handleStream(req, res, ds);

    req._emit('close');
    res.writableEnded = true;

    const writesBefore = res.write.mock.calls.length;
    ds.emit('data', { seq: 99 });
    expect(res.write.mock.calls.length).toBe(writesBefore);

    ds.stop();
  });
});
