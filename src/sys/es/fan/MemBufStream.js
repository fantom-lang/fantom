//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   13 Jun 2009  Andy Frank  Creation
//   13 Jun 2023  Matthew Giannini  Refactor for ES
//

//////////////////////////////////////////////////////////////////////////
// MemBufOutStream
//////////////////////////////////////////////////////////////////////////

class MemBufOutStream extends OutStream {

  constructor(buf) {
    super();
    this.buf = buf;
  }

  buf;

  static make(buf) {
    const self = new MemBufOutStream(buf);
    MemBufOutStream.make$(self);
    return self;
  }

  static make$(self, out) {
    OutStream.make$(self, out);
  }

  write(v) {
    if (this.buf.__pos+1 >= this.buf.data.length) this.buf.grow(this.buf.__pos+1);
    this.buf.data[this.buf.__pos++] = (0xff & v);
    if (this.buf.__pos > this.buf.__size) this.buf.__size = this.buf.__pos;
    return this;
  }

  writeChar(c) {
    this.charset().__encoder().encodeOut(c, this);
    return this;
  }

  writeBuf(other, n=other.remaining()) {
    // TODO FIXIT: pull out into util (see readBuf)

    this.buf.grow(this.buf.__pos + n);

    if (other.__pos+n > other.__size)
      throw IOErr.make("Not enough bytes to write");

    const orig = this.buf.data;
    let temp = other.data.slice(other.__pos, other.__pos+n);
    this.buf.data = MemBuf.__concat(this.buf.data.slice(0, this.buf.__pos), temp);
    // this.buf.data = this.buf.data.slice(0, this.buf.__pos).concat(temp);
    this.buf.__pos += n;
    other.__pos += n;

    const remaining = this.buf.__size - this.buf.__pos;
    if (remaining > 0) {
      temp = orig.slice(this.buf.__pos, this.buf.__pos+remaining);
      this.buf.data = MemBuf.__concat(this.buf.data, temp);
      // this.buf.data = this.buf.data.concat(temp);
    }

    if (this.buf.__pos > this.buf.__size) this.buf.__size = this.buf.__pos;
    return this;
  }

  flush() {}

  sync() {}
}

///////////////////////////////////////////////////////z///////////////////
// MemBufInStream
//////////////////////////////////////////////////////////////////////////

class MemBufInStream extends InStream {

  constructor(buf) {
    super();
    this.buf = buf;
  }

  buf;

  static make(buf) {
    const self = new MemBufInStream(buf);
    MemBufInStream.make$(self);
    return self;
  }

  static make$(self) {
    InStream.make$(self);
  }

  read() {
    if (this.buf.__pos >= this.buf.__size) return null;
    return this.buf.data[this.buf.__pos++] & 0xff;
  }

  readChar() {
    const c = this.__rChar();
    return (c < 0) ? null : c;
  }

  __rChar() {
    return this.charset().__encoder().decode(this);
  }

  readBuf(other, n) {
    if (this.buf.__pos >= this.buf.__size) return null;

    const len = Math.min(this.buf.__size-this.buf.__pos, n);
    const orig = other.data;

    let temp = this.buf.data.slice(this.buf.__pos, this.buf.__pos+len);
    other.data = MemBuf.__concat(other.data.slice(0, other.__pos), temp);
    // other.data = other.data.slice(0, other.__pos).concat(temp);
    this.buf.__pos += len;
    other.__pos += len;
    other.__size = other.__pos;

    const remaining =  other.__size - other.__pos;
    if (remaining > 0) {
      temp = orig.slice(other.__pos, other.__pos+remaining);
      other.data = MemBuf.__concat(other.data, temp);
      // other.data = other.data.concat(temp);
    }

    return len;
  }

  unread(n) {
    // unreading a buffer is a bit weird - the typical case
    // is that we are pushing back the byte we just read in
    // which case we can just rewind the position; however
    // if we pushing back a different byte then we need
    // to shift the entire buffer and insert the byte
    n &= 0xFF;
    if (this.buf.__pos > 0 && this.buf.data[this.buf.__pos-1] == n)
    {
      this.buf.__pos--;
    }
    else
    {
      if (this.buf.__size+1 >= this.buf.data.length) this.buf.grow(this.buf.__size+1);
      const temp = this.buf.data.slice(this.buf.__pos, this.buf.data.length - 1);
      this.buf.data[this.buf.__pos] = n;
      this.buf.data.set(temp, this.buf.__pos + 1);
      this.buf.__size++;
    }
    return this;
  }

  avail() { return this.buf.remaining(); }

  peek() {
    if (this.buf.__pos >= this.buf.__size) return null;
    return this.buf.data[this.buf.__pos] & 0xFF;
  }

  skip(n) {
    const oldPos = this.buf.__pos;
    this.buf.__pos += n;
    if (this.buf.__pos < this.buf.__size) return n;
    this.buf.__pos = this.buf.__size;
    return this.buf.__pos-oldPos;
  }
}

///////////////////////////////////////////////////////z///////////////////
// ErrInStream
//////////////////////////////////////////////////////////////////////////

class ErrInStream extends InStream {
  constructor() { super(); }
  read()            { throw this.err(); }
  rChar()           { throw this.err(); }
  readBuf(other, n) { throw this.err(); }
  unread(n)         { throw this.err(); }
  unread(n)         { throw this.err(); }
  endian(endian)    { throw this.err(); }
  charset(charset)  { throw this.err(); }
  err() { return ReadonlyErr.make("Buf is immutable; use Buf.in()"); }
}

///////////////////////////////////////////////////////z///////////////////
// ErrOutStream
//////////////////////////////////////////////////////////////////////////

class ErrOutStream extends OutStream {
  constructor() { super(); }
  write(v)           { throw this.err(); }
  writeBuf(other, n) { throw this.err(); }
  writeChar(c)       { throw this.err(); }
  writeChar(c)       { throw this.err(); }
  endian(endian)     { throw this.err(); }
  charset(charset)   { throw this.err(); }
  err() { return ReadonlyErr.make("Buf is immutable"); }
}

///////////////////////////////////////////////////////z///////////////////
// ConstBufInStream
//////////////////////////////////////////////////////////////////////////

class ConstBufInStream extends InStream {
  constructor(buf) { 
    super();
    this.buf    = buf;
    this.__pos  = 0;
    this.__size = buf.size();
    // this.endian(buf.endian());
    // this.charset(buf.charset());
  }

  buf;
  __pos;
  __size;

  read() {
    if (this.__pos >= this.__size) return null;
    return this.buf.data[this.__pos++] & 0xFF;
  }

  readBuf(other, n) {
    if (this.__pos >= this.__size) return null;
    const len = Math.min(this.__size - this.__pos, n);
    other.pipeFrom(buf.data, this.__pos, len);
    this.__pos += len;
    return len;
  }

  unread(n) {
    // unreading a buffer is a bit weird - the typical case
    // is that we are pushing back the byte we just read in
    // which case we can just rewind the position; however
    // if we pushing back a different byte then we need
    // to shift the entire buffer and insert the byte
    if (this.__pos > 0 && this.buf.data[this.__pos-1] == n) {
      this.__pos--;
    }
    else {
      throw this.buf.err();
    }
    return this;
  }

  peek() {
    if (this.__pos >= this.__size) return null;
    return this.buf.data[this.__pos] & 0xFF;
  }

  skip(n) {
    const oldPos = this.__pos;
    this.__pos += n;
    if (this.__pos < this.__size) return n;
    this.__pos = this.__size;
    return this.__pos-oldPos;
  }
}
