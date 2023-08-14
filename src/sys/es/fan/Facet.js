//
// Copyright (c) 2011 Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   03 Jan 2011  Andy Frank  Creation
//   12 Apr 2023  Matthew Giannini  Refactor for ES
//

/*************************************************************************
 * Facet
 ************************************************************************/

class Facet extends Obj {
  constructor() { super(); }
}

/*************************************************************************
 * Deprecated
 ************************************************************************/

class Deprecated extends Obj {
  constructor(f=null) { 
    super(); 
    if (f != null) f(this);
  }

  #msg;

  msg() { return this.#msg; }
  __msg(it) { this.#msg = it; }

  static make(f=null) { return new Deprecated(f); }
  
  toStr() { return fanx_ObjEncoder.encode(this); }
}

/*************************************************************************
 * FacetMeta
 ************************************************************************/

class FacetMeta extends Obj {
  constructor(f=null) { 
    super(); 
    this.#inherited = false;
    if (f != null) f(this);
  }

  #inherited;

  inherited() { return this.#inherited; }
  __inherited(it) { this.#inherited = it; }

  static make(f=null) { return new FacetMeta(f); }
  
  toStr() { return fanx_ObjEncoder.encode(this); }
}

/*************************************************************************
 * Js
 ************************************************************************/

class Js extends Obj {
  constructor() { super(); }
  static #defVal;
  static defVal() { 
    if (!Js.#defVal) Js.#defVal = new Js();
    return Js.#defVal;
  }
  
  toStr() { return this.typeof$().qname(); }
}

/*************************************************************************
 * NoDoc
 ************************************************************************/

class NoDoc extends Obj {
  constructor() { super(); }
  static #defVal;
  static defVal() { 
    if (!NoDoc.#defVal) NoDoc.#defVal = new NoDoc();
    return NoDoc.#defVal;
  }
  
  toStr() { return this.typeof$().qname(); }
}

/*************************************************************************
 * Operator
 ************************************************************************/

class Operator extends Obj {
  constructor() { super(); }
  static #defVal;
  static defVal() {
    if (!Operator.#defVal) Operator.#defVal = new Operator();
    return Operator.#defVal;
  }
  
  toStr() { return this.typeof$().qname(); }
}

/*************************************************************************
 * Serializable
 ************************************************************************/

class Serializable extends Obj {
  constructor(f=null) { 
    super(); 
    this.#simple = false;
    this.#collection = false;
    if (f != null) f(this);
  }

  #simple;
  #collection;

  simple() { return this.#simple; }
  __simple(it) { this.#simple = it; }

  collection() { return this.#collection; }
  __collection(it) { this.#collection = it; }

  static make(f=null) { return new Serializable(f); }
  
  toStr() { return fanx_ObjEncoder.encode(this); }
}

/*************************************************************************
 * Transient
 ************************************************************************/

class Transient extends Obj {
  constructor() { super(); }
  static #defVal;
  static defVal() {
    if (!Transient.#defVal) Transient.#defVal = new Transient();
    return Transient.#defVal;
  }
  
  toStr() { return this.typeof$().qname(); }
}

