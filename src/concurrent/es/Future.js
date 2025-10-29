//
// Copyright (c) 2010, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 Mar 2010  Andy Frank         Creation
//   13 May 2010  Andy Frank         Move from sys to concurrent
//   22 Jun 2023  Matthew Giannini   Refactor for ES
//   22 Jun 2025  Brian Frank        Integrate promise support
//

/**
 * Future.
 */
class Future extends sys.Obj {

  constructor() { super(); }

  static make$(self, w) {
    self.#wraps = w;
  }

  static makeCompletable() {
    const x = Promise.withResolvers();
    const f = new Future();
    f.#status  = FutureStatus.pending();
    f.#promise = x.promise;
    f.#resolve = x.resolve;
    f.#reject  = x.reject;
    return f;
  }

  static makePromise(promise) {
    const f = new Future();
    f.#status  = FutureStatus.pending();
    f.#promise = promise;
    promise.then(
      (r) => { f.#res = r; f.#status = FutureStatus.ok();  },
      (e) => { f.#err = e; f.#status = FutureStatus.err(); }
    );
    return f;
  }

  typeof() {
    return Future.type$;
  }

  status() {
    if (this.#wraps) return this.#wraps.status();

    if (!this.#status) throw sys.Err.make("Not completable future")
    return this.#status;
  }

  get(timeout) {
    if (this.#wraps) return this.#wraps.get(timeout);

    if (this.#status != FutureStatus.ok()) throw sys.Err.make("Future status not ok: " + this.#status);
    return this.#res
  }

  err() {
    if (this.#wraps) return this.#wraps.err();

    return this.#err
  }

  complete(val) {
    if (this.#wraps) { this.#wraps.complete(val); return this; }

    if (!this.#resolve) throw sys.Err.make("Not completable future")
    this.#status = FutureStatus.ok();
    this.#resolve(val);
    return this;
  }

  completeErr(err) {
    if (this.#wraps) { this.#wraps.completeErr(err); return this; }

    if (!this.#reject) throw sys.Err.make("Not completable future")
    this.#status = FutureStatus.err();
    this.#reject(err);
    return this;
  }

  cancel() {
    throw sys.UnsupportedErr.make("Cancel not supported in JS")
  }

  then(onOk, onErr) {
    return this.wrap(Future.makePromise(this.promise().then(onOk, onErr)));
  }

  promise() {
    if (this.#wraps) { return this.#wraps.promise(); }

    if (!this.#promise) throw sys.Err.make("Future not backed by Promise");
    return this.#promise;
  }

  wraps() {
    return this.#wraps;
  }

  wrap(future) {
    return future;
  }

  #status  = null;
  #promise = null;
  #resolve = null;
  #reject  = null;
  #res     = null;
  #err     = null;
  #wraps   = null;

}

