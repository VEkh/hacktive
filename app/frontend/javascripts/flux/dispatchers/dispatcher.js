const Promise = require('es6-promise').Promise;
import assign from 'object-assign';

var _callbacks = [];
var _promises = [];

const Dispatcher = function() {};
Dispatcher.prototype = assign({}, Dispatcher.prototype, {
  dispatch: function(payload) {
    // First create array of promises for callbacks to reference.
    var resolves = [];
    var rejects = [];
    _promises = _callbacks.map(function(_, i) {
      return new Promise(function(resolve, reject) {
        resolves[i] = resolve;
        rejects[i] = reject;
      });
    });

    // Dispatch to callbacks and resolve/reject promises.
    _callbacks.forEach(function(callback, i) {
      // Callback can return an obj, to resolve, or a promise, to chain.
      // See waitFor() for why this might be useful.
      Promise.resolve(callback(payload)).then(function() {
        resolves[i](payload);
      }, function() {
        rejects[i](new Error('Dispatcher callback unsuccessful'));
      });
    });
    _promises = [];
  },


  // Register a Store's callback so that it may be invoked by an action.
  register: function(callback) {
    _callbacks.push(callback);
    return _callbacks.length - 1; // index
  }
});

module.exports = Dispatcher;
