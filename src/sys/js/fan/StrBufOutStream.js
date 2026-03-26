//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   01 Aug 2013  Andy Frank  Break out from StrBuf to fix dependy order
//   25 Apr 2023  Matthew Giannini Refactor for ES
//

/**
 * StrBufOutStream
 */
class StrBufOutStream extends OutStream {
  constructor(buf) {
    super();
    this.#buf = buf;
  }

  #buf;

  w(v) { throw UnsupportedErr.make("binary write on StrBuf output"); }

  write(x) { throw UnsupportedErr.make("binary write on StrBuf output"); }

  writeBuf(buf, n) { throw UnsupportedErr.make("binary write on StrBuf output"); }

  writeI2(x) { throw UnsupportedErr.make("binary write on StrBuf output"); }

  writeI4(x) { throw UnsupportedErr.make("binary write on StrBuf output"); }

  writeI8(x) { throw UnsupportedErr.make("binary write on StrBuf output"); }

  writeF4(x) { throw UnsupportedErr.make("binary write on StrBuf output"); }

  writeF8(x) { throw UnsupportedErr.make("binary write on StrBuf output"); }

  writeUtf(x) { throw UnsupportedErr.make("modified UTF-8 format write on StrBuf output"); }

  writeChar(c) {
    this.#buf.addChar(c);
    return this;
  }

  writeChars(s, off=0, len=s.length-off) {
    this.#buf.add(s.slice(off, off+len));
    return this;
  }

  flush() { return this; }
  close() { return true; }
}