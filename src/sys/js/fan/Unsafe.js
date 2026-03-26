//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//  04 Jun 2010  Brian Frank  Creation
//  25 Apr 2023  Matthew Giannini Refactor for ES
//

/**
 * Unsafe.
 */
class Unsafe extends Obj {

  constructor(val) {
    super();
    this.#val = val;
  }

  #val;

  static make(val) { return new Unsafe(val); }

  

  val() { return this.#val; }

}