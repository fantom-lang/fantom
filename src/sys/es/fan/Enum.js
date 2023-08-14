//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Feb 2009  Andy Frank  Creation
//   20 May 2009  Andy Frank  Refactor to new OO model
//   17 Apr 2023  Matthew Giannini  Refactor for ES
//

/**
 * Enum
 */
class Enum extends Obj {

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  constructor() { super(); }

  #ordinal;
  #name;

  static make(ordinal, name) {
    // should never be used
    throw new Error("this should never be used");
  }

  static make$(self, ordinal, name) {
    if (name == null) throw NullErr.make();
    self.#ordinal = ordinal;
    self.#name = name;
  }

  static doFromStr(t, vals, name, checked=true) {
    // the compiler marks the value fields with the Enum flag
    const slot = t.slot(name, false);
    if (slot != null && (slot.flags$() & FConst.Enum) != 0) {
      const v = vals.find((it) => { return it.name() == name; });
      if (v != null) return v;
    }
    if (!checked) return null;
    throw ParseErr.makeStr(t.qname(), name);
  }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  equals(that) { return this == that; }

  compare(that) {
    if (this.#ordinal < that.#ordinal) return -1;
    if (this.#ordinal == that.#ordinal) return 0;
    return +1;
  }

  toStr() { return this.#name; }
  ordinal() { return this.#ordinal; }
  name() { return this.#name; }

}