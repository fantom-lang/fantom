//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   29 Dec 2008  Andy Frank  Creation
//   20 May 2009  Andy Frank  Refactor to new OO model
//   20 Apr 2023  Matthew Giannini  Refactor for ES
//

/**
 * Range represents a contiguous range of integers from start to end.
 */
class Range extends Obj {

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  constructor(start, end, exclusive) {
    super();
    this.#start = start;
    this.#end = end;
    this.#exclusive = (exclusive === undefined) ? false : exclusive;
  }

  #start;
  #end;
  #exclusive;

  static makeInclusive(start, end) { return new Range(start, end, false); }

  static makeExclusive(start, end) { return new Range(start, end, true); }

  static make(start, end, exclusive) { return new Range(start, end, exclusive); }

  static fromStr(s, checked=true) {
    try {
      const dot = s.indexOf('.');
      if (s.charAt(dot+1) != '.') throw new Error();
      const exclusive = s.charAt(dot+2) == '<';
      const start = Int.fromStr(s.substr(0, dot));
      const end   = Int.fromStr(s.substr(dot + (exclusive?3:2)));
      return new Range(start, end, exclusive);
    }
    catch (err) {
      if (!checked) return null;
      throw ParseErr.make("Range", s, null, err);
    }
  }

//////////////////////////////////////////////////////////////////////////
// Range
//////////////////////////////////////////////////////////////////////////

  start() { return this.#start; }
  end() { return this.#end; }
  inclusive() { return !this.#exclusive; }
  exclusive() { return this.#exclusive; }

  isEmpty() { return this.#exclusive && this.#start == this.#end; }

  min() {
    if (this.isEmpty()) return null;
    if (this.#end < this.#start) return this.#exclusive ? this.#end+1 : this.#end;
    return this.#start;
  }

  max() {
    if (this.isEmpty()) return null;
    if (this.#end < this.#start) return this.#start;
    return this.#exclusive ? this.#end-1 : this.#end;
  }

  first() {
    if (this.isEmpty()) return null;
    return this.#start;
  }

  last() {
    if (this.isEmpty()) return null;
    if (!this.#exclusive) return this.#end;
    if (this.#start < this.#end) return this.#end-1;
    return this.#end+1;
  }

  contains(i) {
    if (this.#start < this.#end) {
      if (this.#exclusive)
        return this.#start <= i && i < this.#end;
      else
        return this.#start <= i && i <= this.#end;
    }
    else {
      if (this.#exclusive)
        return this.#end < i && i <= this.#start;
      else
        return this.#end <= i && i <= this.#start;
    }
  }

  offset(offset) {
    if (offset == 0) return this;
    return Range.make(this.#start+offset, this.#end+offset, this.#exclusive);
  }

  each(func) {
    let start = this.#start;
    let end   = this.#end;
    if (start < end) {
      if (this.#exclusive) --end;
      for (let i=start; i<=end; ++i) func(i);
    }
    else {
      if (this.#exclusive) ++end;
      for (let i=start; i>=end; --i) func(i);
    }
  }

  eachWhile(func) {
    let start = this.#start;
    let end   = this.#end;
    let r = null
    if (start < end) {
      if (this.#exclusive) --end;
      for (let i=start; i<=end; ++i) {
        r = func(i);
        if (r != null) return r;
      }
    }
    else {
      if (this.#exclusive) ++end;
      for (let i=start; i>=end; --i) {
        r = func(i);
        if (r != null) return r;
      }
    }
    return null;
  }

  map(func) {
    let r = func.__returns;
    if (r == null || r == Void.type$) r = Obj.type$.toNullable();

    const acc = List.make(r);
    let start = this.#start;
    let end   = this.#end;
    if (start < end) {
      if (this.#exclusive) --end;
      for (let i=start; i<=end; ++i) acc.add(func(i));
    }
    else {
      if (this.#exclusive) ++end;
      for (let i=start; i>=end; --i) acc.add(func(i));
    }
    return acc;
  }

  toList() {
    let start = this.#start;
    let end = this.#end;
    const acc = List.make(Int.type$);
    if (start < end) {
      if (this.#exclusive) --end;
      for (let i=start; i<=end; ++i) acc.push(i);
    }
    else {
      if (this.#exclusive) ++end;
      for (let i=start; i>=end; --i) acc.push(i);
    }
    return acc;
  }

  random() { return Int.random(this); }

  equals(that) {
    if (that instanceof Range) {
      return this.#start == that.#start &&
            this.#end == that.#end &&
            this.#exclusive == that.#exclusive;
    }
    return false;
  }

  hash() { return (this.#start << 24) ^ this.#end; }

  toStr() {
    if (this.#exclusive)
      return this.#start + "..<" + this.#end;
    else
      return this.#start + ".." + this.#end;
  }

  __start(size) {
    if (size == null) return this.#start;

    let x = this.#start;
    if (x < 0) x = size + x;
    if (x > size) throw IndexErr.make(this);
    return x;
  }

  __end(size) {
    if (size == null) return this.#end;

    let x = this.#end;
    if (x < 0) x = size + x;
    if (this.#exclusive) x--;
    if (x >= size) throw IndexErr.make(this);
    return x;
  }

}