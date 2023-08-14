//
// Copyright (c) 2010, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   26 Feb 2010  Andy Frank  Creation
//   04 Apr 2023  Matthew Giannini  Refactor to ES
//

class Version extends Obj {

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  constructor(segments) {
    super();
    this.#segments = segments.ro();
  }

  #segments;

  static fromStr(s, checked=true) {
    let segments = List.make(Int.type$);
    let seg = -1;
    let valid = true;
    let len = s.length;
    for (let i=0; i<len; ++i) {
      const c = s.charCodeAt(i);
      if (c == 46) {
        if (seg < 0 || i+1>=len) { valid = false; break; }
        segments.add(seg);
        seg = -1;
      }
      else {
        if (48 <= c && c <= 57) {
          if (seg < 0) seg = c-48;
          else seg = seg*10 + (c-48);
        }
        else {
          valid = false; break;
        }
      }
    }
    if (seg >= 0) segments.add(seg);

    if (!valid || segments.size() == 0)
    {
      if (checked)
        throw ParseErr.makeStr("Version", s);
      else
        return null;
    }

    return new Version(segments);
  }

  static make(segments) {
    let valid = segments.size() > 0;
    for (let i=0; i<segments.size(); ++i)
      if (segments.get(i) < 0) valid = false;
    if (!valid) throw ArgErr.make("Invalid Version: '" + segments + "'");
    return new Version(segments);
  }

  static #defVal = undefined;
  static defVal() {
    if (Version.#defVal === undefined) Version.#defVal = Version.fromStr("0");
    return Version.#defVal;
  }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  equals(obj) {
    if (obj instanceof Version)
      return this.toStr() == obj.toStr();
    else
      return false;
  }

  compare(obj) {
    const that = obj;
    const a = this.#segments;
    const b = that.#segments;
    for (let i=0; i<a.size() && i<b.size(); ++i) {
      const ai = a.get(i);
      const bi = b.get(i);
      if (ai < bi) return -1;
      if (ai > bi) return +1;
    }
    if (a.size() < b.size()) return -1;
    if (a.size() > b.size()) return +1;
    return 0;
  }

  hash() { return Str.hash(this.toStr()); }

  

  toStr() {
    if (this.str$ == null) {
      let s = "";
      for (let i=0; i<this.#segments.size(); ++i)
      {
        if (i > 0) s += '.';
        s += this.#segments.get(i);
      }
      this.str$ = s;
    }
    return this.str$;
  }

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  segments() { return this.#segments; }

  segment(index) { return this.#segments.get(index); }

  major() { return this.#segments.get(0); }

  minor() {
    if (this.#segments.size() < 2) return null;
    return this.#segments.get(1);
  }

  build() {
    if (this.#segments.size() < 3) return null;
    return this.#segments.get(2);
  }

  patch() {
    if (this.#segments.size() < 4) return null;
    return this.#segments.get(3);
  }
}
