//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   11 Dec 2008  Andy Frank  Creation
//   20 May 2009  Andy Frank  Refactor to new OO model
//   31 Mar 2023  Matthew Giannini  Refactor to ES
//

/**
 * Obj
 */
class Obj {

  /** Simple counter-based hash for object that do not override hash() */
  static #hashCounter = 0;
  #hash;

  equals(that) { return this === that; }

  compare(that) {
    if (this < that) return -1;
    if (this > that) return 1;
    return 0;
  }

  hash() {
    if (this.#hash === undefined) this.#hash = Obj.#hashCounter++;
    return this.#hash;
  }

  with$(f) {
    f(this);
    return this;
  }

  isImmutable() { return this.typeof$().isConst(); }

  toImmutable() {
    if (this.isImmutable()) return this;
    throw NotImmutableErr.make(this.typeof$().toStr());
  }

  toStr() { return `${this.typeof$()}@${this.hash()}`; }

  toString() { return "" + this.toStr(); }

  trap(name, args=null) { return ObjUtil.doTrap(this, name, args, this.typeof$()); }
}
