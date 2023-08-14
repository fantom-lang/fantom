//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//  01 Aug 2013  Andy Frank  Break out from Method.js to fix dependency order
//  27 Jul 2023  Matthew Giannini Refactor for ES
//

/**
 * MethodFunc.
 */
class MethodFunc extends Obj {
  constructor(method, returns) {
    super();
    this.#method  = method;
    this.#returns = returns;
    this.#type    = null;
  }

  #method;
  #returns;
  #type;
  #params;

  returns() { return this.#returns; }
  arity() { return this.params().size(); }
  params() {
    // lazy-load function params
    if (!this.#params) {
      const mparams = this.#method.params();
      let   fparams = mparams;
      if ((this.#method & (FConst.Static | FConst.Ctor)) == 0) {
        const temp = [];
        temp[0] = new Param("this", this.#method.parent(), 0);
        fparams = List.make(Param.type$, temp.concat(mparams.__values()));
      }
      this.#params = fparams.ro();
    }
    return this.#params;
  }

  method() { return this.#method; }
  isImmutable() { return true; }

  typeof$() {
    // lazy load type and params
    if (!this.#type) {
      const params = this.params();
      const types = [];
      for (let i=0; i<params.size(); i++)
        types.push(params.get(i).type());
      this.#type = new FuncType(types, this.#returns);
    }
    return this.#type;
  }

  call() {
    return this.#method.call.apply(this.#method, arguments);
  }

  callList(args) {
    return this.#method.callList.apply(this.#method, arguments);
  }

  callOn(obj, args) {
    return this.#method.callOn.apply(this.#method, arguments);
  }

  retype(t) {
    if (t instanceof FuncType) {
      const params = [];
      for (let i=0; i < t.pars.length; ++i)
        params.push(new Param(String.fromCharCode(i+65), t.pars()[i], 0));
      const paramList = List.make(Param.type$, params);

      const func = new MethodFunc(this.#method, t.ret());
      func.#type = t;
      func.#params = paramList;
      return func;
    }
    else
      throw ArgErr.make(Str.plus("Not a Func type: ", t));
  }
}