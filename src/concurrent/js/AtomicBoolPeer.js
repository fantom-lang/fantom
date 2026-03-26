//
// Copyright (c) 2015, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   17 Aug 2015  Matthew Giannini  Creation
//   22 Jun 2023  Matthew Giannini  Refactor for ES
//

/**
 * AtomicBoolPeer
 */
class AtomicBoolPeer extends sys.Obj {
  constructor() { super(); }

  #val = false;
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
}