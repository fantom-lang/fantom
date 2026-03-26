//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Feb 2009  Andy Frank  Creation
//   20 May 2009  Andy Frank  Refactor to new OO model
//   20 Apr 2023  Matthew Giannini  Refactor to ES
//

/**
 * Endian
 */
class Endian extends Enum {
  constructor(ordinal, name) {
    super();
    Enum.make$(this, ordinal, name);
  }

  static big() { return Endian.vals().get(0); }
  static little() { return Endian.vals().get(1); }

  static #vals = undefined;
  static vals() {
    if (Endian.#vals === undefined) {
      Endian.#vals = List.make(Endian.type$,
        [new Endian(0, "big"), new Endian(1, "little")]).toImmutable();
    }
    return Endian.#vals;
  }

  static fromStr(name, checked=true) {
    return Enum.doFromStr(Endian.type$, Endian.vals(), name, checked);
  }
}
