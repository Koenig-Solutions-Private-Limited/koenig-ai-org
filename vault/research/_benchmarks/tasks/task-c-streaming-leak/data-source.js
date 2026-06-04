const { EventEmitter } = require('events');

class DataSource extends EventEmitter {
  constructor(intervalMs = 200) {
    super();
    this.intervalMs = intervalMs;
    this._timer = null;
    this._counter = 0;
  }

  start() {
    if (this._timer) return;
    this._timer = setInterval(() => {
      this._counter++;
      this.emit('data', {
        seq: this._counter,
        value: Math.random() * 1000,
        ts: Date.now(),
      });
    }, this.intervalMs);
  }

  stop() {
    if (this._timer) {
      clearInterval(this._timer);
      this._timer = null;
    }
  }
}

module.exports = DataSource;
