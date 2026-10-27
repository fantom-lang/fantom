//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   11 May 2009  Andy Frank  Creation
//   20 May 2009  Andy Frank  Refactor to new OO model
//   25 Apr 2023  Matthew Giannini  Refactor to ES
//

/**
 * StrInStream
 */
class StrInStream extends InStream {

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  constructor(str) {
    super();
    this.#str = str;
    this.#size = str.length;
    this.#pos = 0;
    this.#pushback = null;
  }

  #str;
  #size;
  #pos;
  #pushback;

//////////////////////////////////////////////////////////////////////////
// InStream
//////////////////////////////////////////////////////////////////////////

  __toCharInStream() { return this; }

  read() { throw UnsupportedErr.make("Binary read on Str.in"); }
  readBuf() { throw UnsupportedErr.make("Binary read on Str.in"); }
  unread() { throw UnsupportedErr.make("Binary read on Str.in"); }

  __rChar() {
    if (this.#pushback != null && this.#pushback.length > 0)
      return this.#pushback.pop();
    if (this.#pos >= this.#size) return -1;

    // a surrogate pair is read as a single code point
    const c = this.#str.charCodeAt(this.#pos++);
    if (c >= 0xD800 && c <= 0xDBFF && this.#pos < this.#size) {
      const lo = this.#str.charCodeAt(this.#pos);
      if (lo >= 0xDC00 && lo <= 0xDFFF) { this.#pos++; return ((c - 0xD800) << 10) + (lo - 0xDC00) + 0x10000; }
    }
    return c;
  }

  readChar() {
    const c = this.__rChar();
    return (c < 0) ? null : c;
  }

  unreadChar(c) {
    if (this.#pushback == null) this.#pushback = [];
    this.#pushback.push(c);
    return this;
  }

  readAllStr(normalizeNewlines=true) {
    try {
      // pushback chars followed by the rest of the string
      let s = "";
      while (this.#pushback != null && this.#pushback.length > 0) {
        const c = this.#pushback.pop();
        s += c < 0x10000 ? String.fromCharCode(c) : String.fromCodePoint(c);
      }
      s += this.#str.substring(this.#pos);
      this.#pos = this.#size;

      // normalize CR LF and lone CR to LF
      if (normalizeNewlines && s.indexOf("\r") >= 0) s = s.replace(/\r\n?/g, "\n");
      return s;
    }
    finally {
      try { this.close(); } catch (err) { Err.make(err).trace(); }
    }
  }

  close() { return true; }

}