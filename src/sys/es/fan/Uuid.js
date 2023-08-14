//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   30 Dec 2008  Brian Frank  Creation
//   08 Feb 2013  Ivo Smid     Conversion of Java class to JS
//   25 Apr 2023  Matthew Giannini  Refactor to ES
//

/**
 * Uuid
 */
class Uuid extends Obj {

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  constructor(value) {
    super();
    this.#value = value;
  }

  #value;

  

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  static make() {
    let uuid;
    if (typeof window !== "undefined" && window.crypto === undefined) {
      // IE
      uuid = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
        var r = Math.random() * 16 | 0, v = c == 'x' ? r : (r & 0x3 | 0x8);
        return v.toString(16);
      });
    }
    else {
      uuid = ([1e7]+-1e3+-4e3+-8e3+-1e11).replace(/[018]/g, function(c) {
        return (c ^ Env.__node().crypto.getRandomValues(new Uint8Array(1))[0] & 15 >> c / 4).toString(16);
      });
    }
    return Uuid.fromStr(uuid);
  }

  static makeStr(a, b, c, d, e) {
    let value = Int.toHex(a, 8) + "-" +
      Int.toHex(b, 4) + "-" +
      Int.toHex(c, 4) + "-" +
      Int.toHex(d, 4) + "-" +
      Int.toHex(e, 12);
    return new Uuid(value);
  }

  static makeBits(hi, lo) {
    throw UnsupportedErr.make("Uuid.makeBits not implemented in Js env");
  }

  static fromStr(s, checked=true) {
    try {
      const len = s.length;

      // sanity check
      if (len != 36 ||
        s.charAt(8) != '-' || s.charAt(13) != '-' || s.charAt(18) != '-' || s.charAt(23) != '-')
      {
        throw new Error();
      }

      // parse hex components
      const a = Int.fromStr(s.substring(0, 8), 16);
      const b = Int.fromStr(s.substring(9, 13), 16);
      const c = Int.fromStr(s.substring(14, 18), 16);
      const d = Int.fromStr(s.substring(19, 23), 16);
      const e = Int.fromStr(s.substring(24), 16);

      return Uuid.makeStr(a, b, c, d, e);
    }
    catch (err) {
      if (!checked) return null;
      throw ParseErr.makeStr("Uuid", s, null, err);
    }
  }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////


  bitsHi() { throw UnsupportedErr.make("Uuid.bitsHi not implemented in Js env"); }

  bitsLo() { throw UnsupportedErr.make("Uuid.bitsLo not implemented in Js env"); }

  equals(that) {
    if (that instanceof Uuid)
      return this.#value == that.#value;
    else
      return false;
  }

  hash() { return Str.hash(this.#value); }

  compare(that) { return ObjUtil.compare(this.#value, that.#value); }

  toStr() { return this.#value; }
}