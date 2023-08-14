//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   02 Jun 09  Andy Frank  Creation
//   13 May 10  Andy Frank  Move from sys to concurrent
//   22 Jun 23  Matthew Giannini  Refactor for ES
//

/**
 * Actor.
 */
class Actor extends sys.Obj {
  constructor() { super(); }

  typeof$() { return Actor.type$; }

  static #locals;

  static locals() {
    if (!Actor.#locals) {
      const k = sys.Str.type$;
      const v = sys.Obj.type$.toNonNullable();
      Actor.#locals = sys.Map.make(k, v);
    }
    return Actor.#locals;
  }
}