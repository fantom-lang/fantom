//
// Copyright (c) 2015, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   17 Aug 2015  Matthew Giannini  Creation
//   22 Jun 2023  Matthew Giannini  Refactor for ES
//

/**
 * AtomicIntPeer
 */
class AtomicIntPeer extends sys.Obj {
  constructor() { super(); }

  #val = 0;
  val(self, it) {
    if (it === undefined) return this.#val;
    this.#val = it;
  }

  getAndSet(self, val) {
    const old = this.#val;
    this.#val = val;
    return old;
  }

  compareAndSet(self, expect, update) {
    if (this.#val == expect) {
      this.#val = update;
      return true;
    }
    return false;
  }

  getAndIncrement(self) { return this.getAndAdd(self, 1); }

  getAndDecrement(self) { return this.getAndAdd(self, -1); }

  getAndAdd(self, delta) {
    const old = this.#val;
    this.#val = old + delta;
    return old;
  }

  incrementAndGet(self) { return this.addAndGet(self, 1); }

  decrementAndGet(self) { return this.addAndGet(self, -1); }

  addAndGet(self, delta) {
    this.#val = this.#val + delta;
    return this.#val;
  }

  increment(self) { this.add(self, 1); }

  decrement(self) { this.add(self, -1); }

  add(self, delta) { this.#val = this.#val + delta; }
}
