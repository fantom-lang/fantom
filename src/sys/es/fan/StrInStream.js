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
    return this.#str.charCodeAt(this.#pos++);
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

  close() { return true; }

}