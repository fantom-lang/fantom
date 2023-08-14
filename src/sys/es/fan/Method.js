//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 Mar w009  Andy Frank  Creation
//   20 May 2009  Andy Frank  Refactor to new OO model
//   12 Apr 2023  Matthew Giannini  Refactor for ES
//

/**
 * Method.
 */
class Method extends Slot {

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  constructor(parent, name, flags, returns, params, facets, generic=null) {
    super(parent, name, flags, facets);
    this.#returns = returns;
    this.#params  = params;
    this.#name$   = this.name$$(name);
    this.#qname$  = this.parent().qnameJs$() + '.' + this.#name$;
    this.#mask    = (generic != null) ? 0 : Method.#toMask(parent, returns, params);
    this.#generic = generic;
  }

  #returns;
  #params;
  #name$;
  #qname$;
  #mask;
  #generic;

  static GENERIC = 0x01;
  static #toMask(parent, returns, params) {
    // we only use generics in Sys
    if (parent.pod().name() != "sys") return 0;

    let p = returns.isGenericParameter() ? 1 : 0;
    for (let i=0; i<params.size(); ++i)
      p |= params.get(i).type().isGenericParameter() ? 1 : 0;

    let mask = 0;
    if (p != 0) mask |= Method.GENERIC;
    return mask;
  }

//////////////////////////////////////////////////////////////////////////
// Internal Access
//////////////////////////////////////////////////////////////////////////

  qnameJs$() { return this.#qname$; }

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  invoke(instance=null, args=null) {
    let func = null;
    const ns = Type.$registry[this.parent().pod().name()];
    if (this.isCtor() || this.isStatic()) {
      const js = ns != null ? ns[this.parent().name()] : null;
      if (js != null) func = js[this.#name$];
    } 
    else {
      func = instance[this.#name$];
    }
    let vals = [];
    if (args instanceof Array) vals = args;
    else if (args instanceof List) vals = args.__values();

    // if not found, assume this is primitive that needs
    // to map into a static call
    if (func == null && instance != null) {
      // Obj maps to ObjUtil
      let type = this.parent().name();
      if (this.parent().qname() === "sys::Obj") func = ObjUtil[this.#name$];
      else func = ns[type][this.#name$];
      vals.splice(0, 0, instance);
      instance = null;
    }

// TODO FIXIT: if func is null - most likley native
// method hasn't been implemented
if (func == null) {
  ObjUtil.echo("### Method.invoke missing: " + this.#qname$);
}

    return func.apply(instance, vals);
  }
  
  returns() { return this.#returns; }

  params() { return this.#params.ro(); }

  func() {
    let func = null;
    const ns = Type.$registry[this.parent().pod().name()];
    const cls = ns[this.parent().name()];
    func = cls[this.#name$];
    if (func == null) func = cls.prototype[this.#name$];
    if (func == null) throw Err.make(`No method found: ${this.name()}`);
    func["__method"] = this;
    return func;
  }

//////////////////////////////////////////////////////////////////////////
// Generics
//////////////////////////////////////////////////////////////////////////

  isGenericMethod() { return (this.#mask & Method.GENERIC) != 0; }
  isGenericInstance() { return this.#generic != null; }
  getGenericMethod() { return this.#generic; }

//////////////////////////////////////////////////////////////////////////
// Call Conveniences
//////////////////////////////////////////////////////////////////////////

  callOn(target, args) { return this.invoke(target, args); }
  
  call() {
    let instance = null;
    let args = arguments;

    if (!this.isCtor() && !this.isStatic()) {
      instance = args[0];
      args = Array.prototype.slice.call(args).slice(1);
    }

    return this.invoke(instance, List.make(Obj.type$, args));
  }

  callList(args) {
    let instance = null;
    if (!this.isCtor() && !this.isStatic()) {
      instance = args.get(0);
      args = args.getRange(new Range(1, -1));
    }
    return this.invoke(instance, args);
  }

}