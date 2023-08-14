//
// Copyright (c) 2011 Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   03 Jan 2011  Andy Frank  Creation
//   20 Apr 2023  Matthew Giannini  Refactor for ES
//

/**
 * Depend.
 */
class Depend extends Obj {

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  constructor(name, constraints) {
    super();
    this.#name = name;
    this.#constraints = constraints;
    this.#str = null;
  }

  #name;
  #constraints;
  #str;

  static fromStr(str, checked=true) {
    try {
      // allow try-block to capture errs
      return new DependParser(str).parse();
    }
    catch (err) {
      if (!checked) return null;
      throw ParseErr.makeStr("Depend", str);
    }
  }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  equals(obj) {
    if (obj instanceof Depend)
      return this.toStr() == obj.toStr();
    else
      return false;
  }

  hash() {
    return Str.hash(this.toStr());
  }

  toStr() {
    if (this.#str == null) {
      let s = "";
      s += this.#name + " ";
      for (let i=0; i<this.#constraints.length; ++i) {
        if (i > 0) s += ",";
        var c = this.#constraints[i];
        s += c.version;
        if (c.isPlus) s += "+";
        if (c.endVersion != null) s += "-" + c.endVersion;
      }
      this.#str = s.toString();
    }
    return this.#str;
  }

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  name() { return this.#name; }

  size() { return this.#constraints.length; }

  version(index=0) { return this.#constraints[index].version; }

  isSimple(index=0) { return !this.isPlus(index) && !this.isRange(index); }

  isPlus(index=0) { return this.#constraints[index].isPlus; }

  isRange(index=0) { return this.#constraints[index].endVersion != null; }

  endVersion(index=0) { return this.#constraints[index].endVersion; }

  match(v) {
    for (let i=0; i<this.#constraints.length; ++i) {
      const c = this.#constraints[i];
      if (c.isPlus) {
        // versionPlus
        if (c.version.compare(v) <= 0)
          return true;
      }
      else if (c.endVersion != null) {
        // versionRange
        if (c.version.compare(v) <= 0 &&
            (c.endVersion.compare(v) >= 0 || Depend.#doMatch(c.endVersion, v)))
          return true;
      }
      else
      {
        // versionSimple
        if (Depend.#doMatch(c.version, v))
          return true;
      }
    }
    return false;
  }

  static #doMatch(a, b) {
    if (a.segments().size() > b.segments().size()) return false;
    for (let i=0; i<a.segments().size(); ++i)
      if (a.segment(i) != b.segment(i))
        return false;
    return true;
  }

}

//////////////////////////////////////////////////////////////////////////
// DependConstraint
//////////////////////////////////////////////////////////////////////////

class DependConstraint {
  constructor() {
    this.version = null;
    this.isPlus = false;
    this.endVersion = null;
  }

  version;
  isPlus;
  endVersion;
}

//////////////////////////////////////////////////////////////////////////
// DependParser
//////////////////////////////////////////////////////////////////////////

class DependParser {
  constructor(str) {
    this.str = str;
    this.cur = 0;
    this.pos = 0;
    this.len = str.length;
    this.constraints = [];
    this.consume();
  }

  str;
  cur;
  pos;
  len;
  constraints;

  parse() {
    const name = this.#name();
    this.constraints.push(this.constraint());
    while (this.cur == 44) {
      this.consume();
      this.consumeSpaces();
      this.constraints.push(this.constraint());
    }
    if (this.pos <= this.len) throw new Error();
    return new Depend(name, this.constraints);
  }

  #name() {
    let s = ""
    while (this.cur != 32) {
      if (this.cur < 0) throw new Error();
      s += String.fromCharCode(this.cur);
      this.consume();
    }
    this.consumeSpaces();
    if (s.length == 0) throw new Error();
    return s;
  }

  constraint() {
    let c = new DependConstraint();
    c.version = this.version();
    this.consumeSpaces();
    if (this.cur == 43) {
      c.isPlus = true;
      this.consume();
      this.consumeSpaces();
    }
    else if (this.cur == 45) {
      this.consume();
      this.consumeSpaces();
      c.endVersion = this.version();
      this.consumeSpaces();
    }
    return c;
  }

  version() {
    const segs = List.make(Int.type$);
    let seg = this.consumeDigit();
    while (true) {
      if (48 <= this.cur && this.cur <= 57) {
        seg = seg*10 + this.consumeDigit();
      }
      else {
        segs.add(seg);
        seg = 0;
        if (this.cur != 46) break;
        else this.consume();
      }
    }
    return Version.make(segs);
  }

  consumeDigit() {
    if (48 <= this.cur && this.cur <= 57) {
      const digit = this.cur - 48;
      this.consume();
      return digit;
    }
    throw new Error();
  }

  consumeSpaces() {
    while (this.cur == 32 || this.cur == 9) this.consume();
  }

  consume() {
    if (this.pos < this.len) {
      this.cur = this.str.charCodeAt(this.pos++);
    }
    else {
      this.cur = -1;
      this.pos = this.len+1;
    }
  }
}

