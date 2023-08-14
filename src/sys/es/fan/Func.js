//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 Mar 2009  Andy Frank  Creation
//   20 May 2009  Andy Frank  Refactor to new OO model
//   07 Apr 2023  Matthew Giannini  Refactor for ES
//

/**
 * Func - A Func when compiled to JS is actually a native closure/function.
 * The purpose of this class is to provide compiler support for instances
 * where Method.func() is used to obtain a Func and then subsequently called.
 */
class Func extends Obj {

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  constructor(params, ret, func) {
    super();
  }

//////////////////////////////////////////////////////////////////////////
// Identity 
//////////////////////////////////////////////////////////////////////////

  // typeof$() { return this.#type; }

  // toImmutable() {
  //   if (this.isImmutable()) return this;
  //   throw NotImmutableErr.make("Func");
  // }

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  static call(f, ...args) { 
    if (f.__method) return f.__method.call(...args); 
    return f(...args);
  }
  static callOn(f, obj, args) { return f.__method.callOn(obj, args); }
  static callList(f, args) { return f.__method.callList(args); }

  static params(f) { 
    let mparams = f.__method.params();
    let fparams = mparams;
    if ((f.__method.flags$() & (FConst.Static | FConst.Ctor)) == 0) {
      const temp = [];
      temp[0] = new Param("this", f.__method.parent(), 0);
      fparams = List.make(Param.type$, temp.concat(mparams.__values()));
    }
    return fparams.ro();
  }
  static arity(f) { return this.params(f).size(); }
  static returns(f) { return f.__method.returns(); }
  static method(f) { return f.__method; }

  //TODO:bind() - never implemented?

  // enterCtor(obj) {}
  // exitCtor() {}
  // checkInCtor(obj) {}

  static toStr(f) { return "sys::Func"; }
  
  // TODO:FIXIT
  // retype(t) {
  //   if (t instanceof FuncType) {
  //     var params = [];
  //     for (let i=0; i < t.pars.length; ++i)
  //       params.push(new Param(String.fromCharCode(i+65), t.pars[i], 0));
  //     let paramList = List.make(Param.type$, params);
  //     return Func.make(paramList, t.ret, this.#func);
  //   }
  //   else
  //     throw ArgErr.make(`Not a Func type ${t}`);
  // }

}