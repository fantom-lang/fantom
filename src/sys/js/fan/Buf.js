//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   01 Apr 2009  Andy Frank  Creation
//   20 May 2009  Andy Frank  Refactor to new OO model
//   17 Apr 2013  Matthew Giannini  Refactor to ES
//

/**
 * Buf.
 */
class Buf extends Obj {

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  constructor() { super(); }

  static make(capacity=1024) {
    return MemBuf.makeCapacity(capacity);
  }

  static random(size) {
    const buf = new Uint8Array(size);
    for (let i=0; i<size;) {
      var x = Math.random() * 4294967296;
      buf[i++] = (0xff & (x >> 24));
      if (i < size) {
        buf[i++] = (0xff & (x >> 16));
        if (i < size) {
          buf[i++] = (0xff & (x >> 8));
          if (i < size) buf[i++] = (0xff & x);
        }
      }
    }
    return MemBuf.__makeBytes(buf);
  }

//////////////////////////////////////////////////////////////////////////
// Abstract Methods
//////////////////////////////////////////////////////////////////////////

  size(it) { throw UnsupportedErr.make(); }

  pos(it) { throw UnsupportedErr.make(); }

  __setByte(pos, b) { throw UnsupportedErr.make(); }

  __getByte(pos) { throw UnsupportedErr.make(); }

  __getBytes(pos, len) { throw UnsupportedErr.make(); }

  __unsafeArray() { throw UnsupportedErr.make(); }

//////////////////////////////////////////////////////////////////////////
// Obj
//////////////////////////////////////////////////////////////////////////

  equals(that) { return this == that; }

  bytesEqual(that) {
    if (this == that) return true;
    if (this.size() != that.size()) return false;
    for (let i=0; i<this.size(); ++i)
      if (this.__getByte(i) != that.__getByte(i))
        return false;
    return true;
  }

  toStr() {
    return `${this.typeof().name()} (pos=${this.pos()} size=${this.size()})`;
  }

//////////////////////////////////////////////////////////////////////////
// Access
//////////////////////////////////////////////////////////////////////////

  isEmpty() { return this.size() == 0; }

  capacity(it) {
    if (it === undefined) return Int.maxVal();
    // no set???
  }

  remaining() { return this.size()-this.pos(); }

  more() { return this.size()-this.pos() > 0; }

  seek(pos) {
    const size = this.size();
    if (pos < 0) pos = size + pos;
    if (pos < 0 || pos > size) throw IndexErr.make(pos);
    this.pos(pos);
    return this;
  }

  flip() {
    this.size(this.pos());
    this.pos(0);
    return this;
  }

  get(pos) {
    const size = this.size();
    if (pos < 0) pos = size + pos;
    if (pos < 0 || pos >= size) throw IndexErr.make(pos);
    return this.__getByte(pos);
  }

  getRange(range) {
    const size = this.size();
    const s = range.__start(size);
    const e = range.__end(size);
    const n = (e - s + 1);
    if (n < 0) throw IndexErr.make(range);

    const slice  = this.__getBytes(s, n);
    const result = new MemBuf(slice, n);
    result.charset(this.charset());
    return result;
  }

  dup() {
    const size   = this.size();
    const copy   = this.__getBytes(0, size);
    const result = new MemBuf(copy, size);
    result.charset(this.charset());
    return result;
  }

//////////////////////////////////////////////////////////////////////////
// Modification
//////////////////////////////////////////////////////////////////////////

  set(pos, b) {
    const size = this.size();
    if (pos < 0) pos = size + pos;
    if (pos < 0 || pos >= size) throw IndexErr.make(pos);
    this.__setByte(pos, b);
    return this;
  }

  trim() { return this; }

  clear() {
    this.pos(0);
    this.size(0);
    return this;
  }

  flush() { return this; }

  close() { return true; }

  endian(it) { 
    if (it === undefined) return this.out().endian();
    this.out().endian(it);
    this.in().endian(it);
  }

  charset(it) {
    if (it === undefined) return this.out().charset();
    this.out().charset(it);
    this.in().charset(it);
  }

  fill(b, times) {
    if (this.capacity() < this.size()+times) this.capacity(this.size()+times);
    for (let i=0; i<times; ++i) this.__out.write(b);
    return this;
  }

//////////////////////////////////////////////////////////////////////////
// OutStream
//////////////////////////////////////////////////////////////////////////

  out() { return this.__out; }

  write(b) { this.__out.write(b); return this; }

  writeBuf(other, n) { this.__out.writeBuf(other, n); return this; }

  writeI2(x) { this.__out.writeI2(x); return this; }

  writeI4(x) { this.__out.writeI4(x); return this; }

  writeI8(x) { this.__out.writeI8(x); return this; }

  writeF4(x) { this.__out.writeF4(x); return this; }

  writeF8(x) { this.__out.writeF8(x); return this; }

  writeDecimal(x) { this.__out.writeDecimal(x); return this; }

  writeBool(x) { this.__out.writeBool(x); return this; }

  writeUtf(x) { this.__out.writeUtf(x); return this; }

  writeChar(c) { this.__out.writeChar(c); return this; }

  writeChars(s, off=0, len=s.length-off) { this.__out.writeChars(s, off, len); return this; }

  print(obj) { this.__out.print(obj); return this; }

  printLine(obj="") { this.__out.printLine(obj); return this; }

  writeObj(obj, opt) { this.__out.writeObj(obj, opt); return this; }

  writeXml(s, flags) { this.__out.writeXml(s, flags); return this; }

  writeProps(props, close) { this.__out.writeProps(props, close); return this; }

//////////////////////////////////////////////////////////////////////////
// InStream
//////////////////////////////////////////////////////////////////////////

  in() { return this.__in; }

  read() {  return this.__in.read(); }

  readBuf(other, n) { return this.__in.readBuf(other, n); }

  unread(n) { this.__in.unread(n); return this; }

  readBufFully(buf, n) { return this.__in.readBufFully(buf, n); }

  readAllBuf() { return this.__in.readAllBuf(); }

  peek() { return this.__in.peek(); }

  readU1() { return this.__in.readU1(); }

  readS1() { return this.__in.readS1(); }

  readU2() { return this.__in.readU2(); }

  readS2() { return this.__in.readS2(); }

  readU4() { return this.__in.readU4(); }

  readS4() { return this.__in.readS4(); }

  readS8() { return this.__in.readS8(); }

  readF4() { return this.__in.readF4(); }

  readF8() { return this.__in.readF8(); }

  readDecimal() { return this.__in.readDecimal(); }

  readBool() { return this.__in.readBool(); }

  readUtf() { return this.__in.readUtf(); }

  readChar() { return this.__in.readChar(); }

  unreadChar(c) { this.__in.unreadChar(c); return this; }

  peekChar() { return this.__in.peekChar(); }

  readChars(n) { return this.__in.readChars(n); }

  readLine(max=4096) { return this.__in.readLine(max); }

  readStrToken(max=null, f=null) { return this.__in.readStrToken(max, f); }

  readAllLines() { return this.__in.readAllLines(); }

  eachLine(f) { this.__in.eachLine(f); }

  readAllStr(normNewlines=true) { return this.__in.readAllStr(normNewlines); }

  readObj(opt=null) { return this.__in.readObj(opt); }

  readProps() { return this.__in.readProps(); }

//////////////////////////////////////////////////////////////////////////
// File
//////////////////////////////////////////////////////////////////////////

  toFile(uri) { throw UnsupportedErr.make("Only supported on memory buffers"); }

//////////////////////////////////////////////////////////////////////////
// Hex
//////////////////////////////////////////////////////////////////////////

  toHex() {
    const data = this.__unsafeArray();
    const size = this.size();
    const hexChars = Buf.#hexChars;
    let s = "";
    for (let i=0; i<size; ++i) {
      const b = data[i] & 0xFF;
      s += String.fromCharCode(hexChars[b>>4]) + String.fromCharCode(hexChars[b&0xf]);
    }
    return s;
  }

  static fromHex(s) {
    const slen = s.length;
    const buf = []
    const hexInv = Buf.#hexInv;
    let size = 0;

    for (let i=0; i<slen; ++i) {
      const c0 = s.charCodeAt(i);
      const n0 = c0 < 128 ? hexInv[c0] : -1;
      if (n0 < 0) continue;

      let n1 = -1;
      if (++i < slen) {
        const c1 = s.charCodeAt(i);
        n1 = c1 < 128 ? hexInv[c1] : -1;
      }
      if (n1 < 0) throw IOErr.make("Invalid hex str");

      buf[size++] = (n0 << 4) | n1;
    }

    return MemBuf.__makeBytes(buf);
  }

  static #hexChars = [
  //0  1  2  3  4  5  6  7  8  9  a  b  c  d   e   f
    48,49,50,51,52,53,54,55,56,57,97,98,99,100,101,102];

  static #hexInv = [];
  static {
    for (let i=0; i<128; ++i) Buf.#hexInv[i] = -1;
    for (let i=0; i<10; ++i)  Buf.#hexInv[48+i] = i;
    for (let i=10; i<16; ++i) Buf.#hexInv[97+i-10] = Buf.#hexInv[65+i-10] = i;
  }

//////////////////////////////////////////////////////////////////////////
// Base64
//////////////////////////////////////////////////////////////////////////

  toBase64() {
    return this.#doBase64(Buf.#base64chars, true);
  }

  toBase64Uri() {
    return this.#doBase64(Buf.#base64UriChars, false);
  }

  #doBase64(table, pad) {
    const buf  = this.__unsafeArray();
    const size = this.size();
    let s = '';
    let i = 0;

    // append full 24-bit chunks
    const end = size-2;
    for (; i<end; i += 3) {
      const n = ((buf[i] & 0xff) << 16) + ((buf[i+1] & 0xff) << 8) + (buf[i+2] & 0xff);
      s += String.fromCharCode(table[(n >>> 18) & 0x3f]);
      s += String.fromCharCode(table[(n >>> 12) & 0x3f]);
      s += String.fromCharCode(table[(n >>> 6) & 0x3f]);
      s += String.fromCharCode(table[n & 0x3f]);
    }

    // pad and encode remaining bits
    const rem = size - i;
    if (rem > 0) {
      const n = ((buf[i] & 0xff) << 10) | (rem == 2 ? ((buf[size-1] & 0xff) << 2) : 0);
      s += String.fromCharCode(table[(n >>> 12) & 0x3f]);
      s += String.fromCharCode(table[(n >>> 6) & 0x3f]);
      s += rem == 2 ? String.fromCharCode(table[n & 0x3f]) : (pad ? '=' : "");
      if (pad) s += '=';
    }

    return s;
  }

  static fromBase64(s) {
    const slen = s.length;
    let si = 0;
    const max = slen * 6 / 8;
    const buf = [];
    let size = 0;

    while (si < slen) {
      let n = 0;
      let v = 0;
      for (let j=0; j<4 && si<slen;) {
        const ch = s.charCodeAt(si++);
        const c = ch < 128 ? Buf.#base64inv[ch] : -1;
        if (c >= 0) {
          n |= c << (18 - j++ * 6);
          if (ch != 61) v++; // '='
        }
      }

      if (v > 1) buf.push(n >> 16);
      if (v > 2) buf.push(n >> 8);
      if (v > 3) buf.push(n);
    }

    return MemBuf.__makeBytes(buf);
  }

  static #base64chars = [
  //A  B  C  D  E  F  G  H  I  J  K  L  M  N  O  P  Q  R  S  T  U  V  W  X  Y  Z
    65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,
  //a  b  c  d   e   f   g   h   i   j   k   l   m   n   o   p   q   r   s   t   u   v   w   x   y   z
    97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122,
  //0  1  2  3  4  5  6  7  8  9  +  /
    48,49,50,51,52,53,54,55,56,57,43,47];


  static #base64UriChars = [
  //A  B  C  D  E  F  G  H  I  J  K  L  M  N  O  P  Q  R  S  T  U  V  W  X  Y  Z
    65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,
  //a  b  c  d   e   f   g   h   i   j   k   l   m   n   o   p   q   r   s   t   u   v   w   x   y   z
    97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122,
  //0  1  2  3  4  5  6  7  8  9  -  _
    48,49,50,51,52,53,54,55,56,57,45,95];

  static #base64inv = [];
  static {
    for (let i=0; i<128; ++i) Buf.#base64inv[i] = -1;
    for (let i=0; i<Buf.#base64chars.length; ++i)
      Buf.#base64inv[Buf.#base64chars[i]] = i;
    Buf.#base64inv[45] = 62; // '-'
    Buf.#base64inv[95] = 63; // '_'
    Buf.#base64inv[61] = 0;  // '='
  }

//////////////////////////////////////////////////////////////////////////
// Digest
//////////////////////////////////////////////////////////////////////////

  toDigest(algorithm) {
    // trim buf to content
    const buf = this.__unsafeArray().slice(0, this.size());
    return MemBuf.__makeBytes(buf_digest.digest(algorithm, buf));
  }

  hmac(algorithm, keyBuf) {
    // trim buf to content
    const buf = this.__unsafeArray().slice(0, this.size());
    const key = keyBuf.__unsafeArray().slice(0, keyBuf.size());
    return MemBuf.__makeBytes(buf_digest.hmac(algorithm, buf, key));
  }

//////////////////////////////////////////////////////////////////////////
// CRC
//////////////////////////////////////////////////////////////////////////

  crc(algorithm) {
    if (algorithm == "CRC-16") return this.#crc16();
    if (algorithm == "CRC-32") return this.#crc32();
    if (algorithm == "CRC-32-Adler") return this.#crcAdler32();
    throw ArgErr.make(`Unknown CRC algorthm: ${algorithm}`);
  }

  #crc16() {
    const array = this.__unsafeArray();
    const size = this.size();
    let seed = 0xffff;
    for (let i=0; i<size; ++i) seed = this.#do_crc16(array[i], seed);
    return seed;
  }

  #do_crc16(dataToCrc, seed) {
    let dat = ((dataToCrc ^ (seed & 0xFF)) & 0xFF);
    seed = (seed & 0xFFFF) >>> 8;
    const index1 = (dat & 0x0F);
    const index2 = (dat >>> 4);
    if ((Buf.#CRC16_ODD_PARITY[index1] ^ Buf.#CRC16_ODD_PARITY[index2]) == 1)
      seed ^= 0xC001;
    dat  <<= 6;
    seed ^= dat;
    dat  <<= 1;
    seed ^= dat;
    return seed;
  }

  #crc32() {
    return crc32.unsigned(this.__unsafeArray(), 0, this.size());
  }

  #crcAdler32() {
    // RFC 1950; sums cannot exceed 2^32 within 5552 bytes before modulo
    const array = this.__unsafeArray();
    const size = this.size();
    let a = 1, b = 0;
    for (let i=0; i<size;) {
      const end = Math.min(i + 5552, size);
      for (; i<end; ++i) { a += array[i]; b += a; }
      a %= 65521;
      b %= 65521;
    }
    return (b * 65536) + a;
  }

  static #CRC16_ODD_PARITY = [ 0, 1, 1, 0, 1, 0, 0, 1, 1, 0, 0, 1, 0, 1, 1, 0 ];

//////////////////////////////////////////////////////////////////////////
// PBKDF2
//////////////////////////////////////////////////////////////////////////

  static pbk(algorithm, password, salt, iterations, keyLen) {
    const passBuf = Str.toBuf(password);

    // trim buf to content
    const passBytes = passBuf.__unsafeArray().slice(0, passBuf.size());
    const saltBytes = salt.__unsafeArray().slice(0, salt.size());

    let hash = null;
    switch(algorithm) {
      case "PBKDF2WithHmacSHA1":   hash = "SHA-1"; break;
      case "PBKDF2WithHmacSHA256": hash = "SHA-256"; break;
      default: throw Err.make("Unsupported algorithm: " + algorithm);
    }
    return MemBuf.__makeBytes(buf_digest.pbkdf2(hash, passBytes, saltBytes, iterations, keyLen));
  }
}

