//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   18 May 2009  Andy Frank  Creation
//   20 May 2009  Andy Frank  Refactor to new OO model
//   12 Apr 2023  Matthew Giannini  Refactor to ES
//

/**
 * Param.
 */
class Param extends Obj {

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  constructor(name, type, hasDefault) {
    super();
    this.#name = name;
    this.#type = (type instanceof Type) ? type : Type.find(type);
    this.#hasDefault = hasDefault;
  }

  static #noParams = undefined
  static noParams$() {
    if (Param.#noParams === undefined) Param.#noParams = List.make(Param.type$, []).toImmutable();
    return Param.#noParams;
  }

  #name;
  #type;
  #hasDefault;

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  name() { return this.#name; }
  type() { return this.#type; }
  hasDefault() { return this.#hasDefault; }
  
  toStr() { return this.#type.toStr() + " " + this.#name; }

}