//
// Copyright (c) 2017, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Nov 2017  Andy Frank  Creation
//   17 Apr 2023  Matthew Giannini  Refactor to ES
//

/**
 * ConstBuf.
 */
class ConstBuf extends Buf {

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  // constructor(data, size, endian, charset) {
  constructor(data, size) {
    super();
    this.data     = data;
    this.__size   = size;
    this.__pos    = 0;
    this.__in     = ConstBuf.#errInStream();
    this.__out    = ConstBuf.#errOutStream();
  }

  static #_errInStream;
  static #errInStream() { 
    if (!ConstBuf.#_errInStream) ConstBuf.#_errInStream = new ErrInStream();
    return ConstBuf.#_errInStream;
  }

  static #_errOutStream;
  static #errOutStream() {
    if (!ConstBuf.#_errOutStream) ConstBuf.#_errOutStream = new ErrOutStream();
    return ConstBuf.#_errOutStream;
  }

  data;
  __size;
  __pos;
  __in;
  __out;

//////////////////////////////////////////////////////////////////////////
// Obj
//////////////////////////////////////////////////////////////////////////

  isImmutable() { return true; }

  toImmutable() { return this; }

//////////////////////////////////////////////////////////////////////////
// Buf Support
//////////////////////////////////////////////////////////////////////////

  in$() { return new ConstBufInStream(this); }
  
  toFile(uri) { return MemFile.make(this.toImmutable(), uri); }

  size(it) {
    if (it === undefined) return this.__size;
    throw this.err();
  }

  pos(it) {
    if (it === undefined) return 0;
    if (it != 0) throw this.err();
  }

  __getByte(pos) { return this.data[pos] & 0xFF; }

  __setByte(pos, x) { throw this.err() }

  __getBytes(pos, len) { return this.data.slice(pos, pos+len); }

// public final void pipeTo(byte[] dst, int dstPos, int len)
// {
//   if (len > size) throw IOErr.make("Not enough bytes to write");
//   System.arraycopy(buf, 0, dst, dstPos, len);
// }
//
// public final void pipeTo(OutputStream dst, long lenLong)
//   throws IOException
// {
//   int len = (int)lenLong;
//   if (len > size) throw IOErr.make("Not enough bytes to write");
//   dst.write(buf, 0, len);
// }
//
// public final void pipeTo(RandomAccessFile dst, long lenLong)
//   throws IOException
// {
//   int len = (int)lenLong;
//   if (len > size) throw IOErr.make("Not enough bytes to write");
//   dst.write(buf, 0, len);
// }
//
// public final void pipeTo(ByteBuffer dst, int len)
// {
//   if (len > size) throw IOErr.make("Not enough bytes to write");
//   dst.put(buf, 0, len);
// }

// pipeFrom() { throw this.err(); }
// fan.sys.ConstBuf.prototype.pipeFrom = function(src, srcPos, len)
// fan.sys.ConstBuf.prototype.pipeFrom = function(InputStream src, long lenLong)
// fan.sys.ConstBuf.prototype.pipeFrom = function(RandomAccessFile src, long lenLong)
// fan.sys.ConstBuf.prototype.pipeFrom = function(ByteBuffer src, int len)

//////////////////////////////////////////////////////////////////////////
// Buf API
//////////////////////////////////////////////////////////////////////////

  capacity(it) { throw this.err(); }

  sync() { throw this.err(); }

  trim() { throw this.err(); }

  endian(it) {
    if (it === undefined) return Endian.big();
    throw this.err();
  }

  charset(it) {
    if (it === undefined) return Charset.utf8();
    throw this.err();
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  __unsafeArray() { return this.data; }

  err() { return ReadonlyErr.make("Buf is immutable"); }
}
