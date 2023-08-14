//
// Copyright (c) 2010, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   19 Mar 2010  Andy Frank  Creation
//   25 Apr 2023  Matthew Giannini  Refactor for ES
//

/**
 * Regex.
 */
class Regex extends Obj {

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  constructor(source, flags="") {
    super();
    this.#source = source;
    this.#flags = flags;
    this.#regexp = new RegExp(source, flags);
  }

  #source;
  #flags;
  #regexp;

  static #defVal = undefined;
  static defVal() { 
    if (Regex.#defVal === undefined) Regex.#defVal = Regex.fromStr("");
    return Regex.#defVal;
  }

  static fromStr(pattern, flags="") {
    return new Regex(pattern, flags);
  }

  static glob(pattern) {
    let s = "";
    for (let i=0; i<pattern.length; ++i) {
      const c = pattern.charCodeAt(i);
      if (Int.isAlphaNum(c)) s += String.fromCharCode(c);
      else if (c == 63) s += '.';
      else if (c == 42) s += '.*';
      else s += '\\' + String.fromCharCode(c);
    }
    return new Regex(s);
  }

  static quote(pattern) {
    let s = "";
    for (let i=0; i<pattern.length; ++i) {
      const c = pattern.charCodeAt(i);
      if (Int.isAlphaNum(c)) s += String.fromCharCode(c);
      else s += '\\' + String.fromCharCode(c);
    }
    return new Regex(s);
  }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  equals(obj) {
    if (obj instanceof Regex)
      return obj.#source === this.#source && obj.#flags == this.#flags;
    else
      return false;
  }

  flags() { return this.#flags; }

  hash() { return Str.hash(this.#source); }

  toStr() { return this.#source; }

//////////////////////////////////////////////////////////////////////////
// Regular expression
//////////////////////////////////////////////////////////////////////////

  matches(s) { return this.matcher(s).matches(); }

  matcher(s) { return new RegexMatcher(this.#regexp, this.#source, s); }

  split(s, limit=0) {
    if (limit === 1)
      return List.make(Str.type$, [s]);

    const array = [];
    const re = this.#regexp;
    while (true) {
      const m = s.match(re);
      if (m == null || (limit != 0 && array.length == limit -1)) {
        array.push(s);
        break;
      }
      array.push(s.substring(0, m.index));
      s = s.substring(m.index + m[0].length);
    }
    // remove trailing empty strings
    if (limit == 0) {
      while (array[array.length-1] == "") { array.pop(); }
    }
    return List.make(Str.type$, array);
  }
}