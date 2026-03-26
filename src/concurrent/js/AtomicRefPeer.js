//
// Copyright (c) 2012, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   02 Nov 2012  Andy Frank  Creation
//   22 Jun 2023  Matthew Giannini  Refactor for ES
//

/**
 * AtomicRefPeer.
 */
class AtomicRefPeer extends sys.Obj {
  constructor() { super(); }

  #val = null;
  val(self, it) {
    if (it === undefined) return this.#val;
    if (!sys.ObjUtil.isImmutable(it)) throw sys.NotImmutableErr.make();
    this.#val = it;
  }

  getAndSet(self, val) {
    if (!sys.ObjUtil.isImmutable(val)) throw sys.NotImmutableErr.make();
    const old = this.#val;
    this.#val = val;
    return old;
  }

  compareAndSet(self, expect, update) {
    if (!sys.ObjUtil.isImmutable(update)) throw sys.NotImmutableErr.make();
    if (this.#val != expect) return false;
    this.#val = update;
    return true;
  }
}
