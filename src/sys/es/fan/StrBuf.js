//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   29 Dec 2008  Andy Frank  Creation
//   20 May 2009  Andy Frank  Refactor to new OO model
//   25 Apr 2023  Matthew Giannini  Refactor for ES
//

/**
 * StrBuf
 */
class StrBuf extends Obj {

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  constructor() {
    super();
    this.#str = "";
    this.#capacity = null;
  }

  #str;
  #capacity;

  static make() { return new StrBuf(); }

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  add(obj) {
    this.#str += obj==null ? "null" : ObjUtil.toStr(obj);
    return this;
  }

  addChar(ch) {
    this.#str += String.fromCharCode(ch);
    return this;
  }

  capacity(it=undefined) {
    if (it === undefined) {
      if (this.#capacity == null) return this.#str.length;
      return this.#capacity;
    }
    this.#capacity = it;
  }

  clear() {
    this.#str = "";
    return this;
  }

  get(i) {
    if (i < 0) i = this.#str.length+i;
    if (i < 0 || i >= this.#str.length) throw IndexErr.make(i);
    return this.#str.charCodeAt(i);
  }

  getRange(range) {
    const size = this.#str.length;
    const s = range.__start(size);
    const e = range.__end(size);
    if (e+1 < s) throw IndexErr.make(range);
    return this.#str.substr(s, (e-s)+1);
  }

  set(i, ch) {
    if (i < 0) i = this.#str.length+i;
    if (i < 0 || i >= this.#str.length) throw IndexErr.make(i);
    this.#str = this.#str.substring(0,i) + String.fromCharCode(ch) + this.#str.substring(i+1);
    return this;
  }

  join(x, sep=" ") {
    const s = (x == null) ? "null" : ObjUtil.toStr(x);
    if (this.#str.length > 0) this.#str += sep;
    this.#str += s;
    return this;
  }

  insert(i, x) {
    const s = (x == null) ? "null" : ObjUtil.toStr(x);
    if (i < 0) i = this.#str.length+i;
    if (i < 0 || i > this.#str.length) throw IndexErr.make(i);
    this.#str = this.#str.substring(0,i) + s + this.#str.substring(i);
    return this;
  }

  remove(i) {
    if (i < 0) i = this.#str.length+i;
    if (i< 0 || i >= this.#str.length) throw IndexErr.make(i);
    this.#str = this.#str.substring(0,i) + this.#str.substring(i+1);
    return this;
  }

  removeRange(r) {
    const s = r.__start(this.#str.length);
    const e = r.__end(this.#str.length);
    const n = e - s + 1;
    if (s < 0 || n < 0) throw IndexErr.make(r);
    this.#str = this.#str.substring(0,s) + this.#str.substring(e+1);
    return this;
  }

  replaceRange(r, str) {
    const s = r.__start(this.#str.length);
    const e = r.__end(this.#str.length);
    const n = e - s + 1;
    if (s < 0 || n < 0) throw IndexErr.make(r);
    this.#str = this.#str.substr(0,s) + str + this.#str.substr(e+1);
    return this;
  }

  reverse() {
    this.#str = Str.reverse(this.#str);
    return this;
  }

  isEmpty() { return this.#str.length == 0; }

  size() { return this.#str.length; }

  toStr() { return this.#str; }

  out() { return new StrBufOutStream(this); }

}