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
    return `${this.typeof$().name()} (pos=${this.pos()} size=${this.size()})`;
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
    this.in$().endian(it);
  }

  charset(it) {
    if (it === undefined) return this.out().charset();
    this.out().charset(it);
    this.in$().charset(it);
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

  writeProps(props, close) { return this.__out.writeProps(props, close); }

//////////////////////////////////////////////////////////////////////////
// InStream
//////////////////////////////////////////////////////////////////////////

  in$() { return this.__in; }

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

    let digest = null;
    switch (algorithm)
    {
      case "MD5":
        digest = buf_md5(buf); break;
      case "SHA1":
      case "SHA-1":
        // fall-through
        digest = buf_sha1.digest(buf); break;
      case "SHA-256":
        digest = buf_sha256.digest(buf); break;
      default: throw ArgErr.make("Unknown digest algorithm " + algorithm);
    }
    return MemBuf.__makeBytes(digest);
  }

  hmac(algorithm, keyBuf) {
    // trim buf to content
    const buf = this.__unsafeArray().slice(0, this.size());
    const key = keyBuf.__unsafeArray().slice(0, keyBuf.size());

    let digest = null;
    switch (algorithm)
    {
      case "MD5":
        digest = buf_md5(buf, key); break;
      case "SHA1":
      case "SHA-1":
        // fall thru
        digest = buf_sha1.digest(buf, key); break;
      case "SHA-256":
        digest = buf_sha256.digest(buf, key); break;
      default: throw ArgErr.make("Unknown digest algorithm " + algorithm);
    }
    return MemBuf.__makeBytes(digest);
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
    // From StackOverflow:
    // https://stackoverflow.com/questions/18638900/javascript-crc32#answer-18639975

    const array = this.__unsafeArray();
    let crc = -1;
    for (let i=0, iTop=array.length; i<iTop; i++) {
      crc = ( crc >>> 8 ) ^ Buf.#CRC32_b_table[(crc ^ array[i]) & 0xFF];
    }
    return (crc ^ (-1)) >>> 0;
  }

  #crcAdler32(seed) {
    // https://github.com/SheetJS/js-adler32
    //
    // Copyright (C) 2014-present  SheetJS
    // Licensed under Apache 2.0

    const array = this.__unsafeArray();
    let a = 1, b = 0, L = array.length, M = 0;
    if (typeof seed === 'number') { a = seed & 0xFFFF; b = (seed >>> 16) & 0xFFFF; }
    for(let i=0; i<L;) {
      M = Math.min(L-i, 3850) + i;
      for(; i<M; i++) {
        a += array[i] & 0xFF;
        b += a;
      }
      a = (15 * (a >>> 16) + (a & 65535));
      b = (15 * (b >>> 16) + (b & 65535));
    }
    return ((b % 65521) << 16) | (a % 65521);
  }

  static #CRC16_ODD_PARITY = [ 0, 1, 1, 0, 1, 0, 0, 1, 1, 0, 0, 1, 0, 1, 1, 0 ];

  static #CRC32_a_table =
    "00000000 77073096 EE0E612C 990951BA 076DC419 706AF48F E963A535 9E6495A3 " +
    "0EDB8832 79DCB8A4 E0D5E91E 97D2D988 09B64C2B 7EB17CBD E7B82D07 90BF1D91 " +
    "1DB71064 6AB020F2 F3B97148 84BE41DE 1ADAD47D 6DDDE4EB F4D4B551 83D385C7 " +
    "136C9856 646BA8C0 FD62F97A 8A65C9EC 14015C4F 63066CD9 FA0F3D63 8D080DF5 " +
    "3B6E20C8 4C69105E D56041E4 A2677172 3C03E4D1 4B04D447 D20D85FD A50AB56B " +
    "35B5A8FA 42B2986C DBBBC9D6 ACBCF940 32D86CE3 45DF5C75 DCD60DCF ABD13D59 " +
    "26D930AC 51DE003A C8D75180 BFD06116 21B4F4B5 56B3C423 CFBA9599 B8BDA50F " +
    "2802B89E 5F058808 C60CD9B2 B10BE924 2F6F7C87 58684C11 C1611DAB B6662D3D " +
    "76DC4190 01DB7106 98D220BC EFD5102A 71B18589 06B6B51F 9FBFE4A5 E8B8D433 " +
    "7807C9A2 0F00F934 9609A88E E10E9818 7F6A0DBB 086D3D2D 91646C97 E6635C01 " +
    "6B6B51F4 1C6C6162 856530D8 F262004E 6C0695ED 1B01A57B 8208F4C1 F50FC457 " +
    "65B0D9C6 12B7E950 8BBEB8EA FCB9887C 62DD1DDF 15DA2D49 8CD37CF3 FBD44C65 " +
    "4DB26158 3AB551CE A3BC0074 D4BB30E2 4ADFA541 3DD895D7 A4D1C46D D3D6F4FB " +
    "4369E96A 346ED9FC AD678846 DA60B8D0 44042D73 33031DE5 AA0A4C5F DD0D7CC9 " +
    "5005713C 270241AA BE0B1010 C90C2086 5768B525 206F85B3 B966D409 CE61E49F " +
    "5EDEF90E 29D9C998 B0D09822 C7D7A8B4 59B33D17 2EB40D81 B7BD5C3B C0BA6CAD " +
    "EDB88320 9ABFB3B6 03B6E20C 74B1D29A EAD54739 9DD277AF 04DB2615 73DC1683 " +
    "E3630B12 94643B84 0D6D6A3E 7A6A5AA8 E40ECF0B 9309FF9D 0A00AE27 7D079EB1 " +
    "F00F9344 8708A3D2 1E01F268 6906C2FE F762575D 806567CB 196C3671 6E6B06E7 " +
    "FED41B76 89D32BE0 10DA7A5A 67DD4ACC F9B9DF6F 8EBEEFF9 17B7BE43 60B08ED5 " +
    "D6D6A3E8 A1D1937E 38D8C2C4 4FDFF252 D1BB67F1 A6BC5767 3FB506DD 48B2364B " +
    "D80D2BDA AF0A1B4C 36034AF6 41047A60 DF60EFC3 A867DF55 316E8EEF 4669BE79 " +
    "CB61B38C BC66831A 256FD2A0 5268E236 CC0C7795 BB0B4703 220216B9 5505262F " +
    "C5BA3BBE B2BD0B28 2BB45A92 5CB36A04 C2D7FFA7 B5D0CF31 2CD99E8B 5BDEAE1D " +
    "9B64C2B0 EC63F226 756AA39C 026D930A 9C0906A9 EB0E363F 72076785 05005713 " +
    "95BF4A82 E2B87A14 7BB12BAE 0CB61B38 92D28E9B E5D5BE0D 7CDCEFB7 0BDBDF21 " +
    "86D3D2D4 F1D4E242 68DDB3F8 1FDA836E 81BE16CD F6B9265B 6FB077E1 18B74777 " +
    "88085AE6 FF0F6A70 66063BCA 11010B5C 8F659EFF F862AE69 616BFFD3 166CCF45 " +
    "A00AE278 D70DD2EE 4E048354 3903B3C2 A7672661 D06016F7 4969474D 3E6E77DB " +
    "AED16A4A D9D65ADC 40DF0B66 37D83BF0 A9BCAE53 DEBB9EC5 47B2CF7F 30B5FFE9 " +
    "BDBDF21C CABAC28A 53B39330 24B4A3A6 BAD03605 CDD70693 54DE5729 23D967BF " +
    "B3667A2E C4614AB8 5D681B02 2A6F2B94 B40BBE37 C30C8EA1 5A05DF1B 2D02EF8D ";

  static #CRC32_b_table = Buf.#CRC32_a_table.split(' ').map((s) =>{ return parseInt(s,16) });

//////////////////////////////////////////////////////////////////////////
// PBKDF2
//////////////////////////////////////////////////////////////////////////

  static pbk(algorithm, password, salt, iterations, keyLen) {
    let digest = null;
    const passBuf = Str.toBuf(password);

    // trim buf to content
    const passBytes = passBuf.__unsafeArray().slice(0, passBuf.size());
    const saltBytes = salt.__unsafeArray().slice(0, salt.size());

    switch(algorithm) {
      case "PBKDF2WithHmacSHA1":
        digest = buf_sha1.pbkdf2(passBytes, saltBytes, iterations, keyLen); break;
      case "PBKDF2WithHmacSHA256":
        digest = buf_sha256.pbkdf2(passBytes, saltBytes, iterations, keyLen); break;
      default: throw Err.make("Unsupported algorithm: " + algorithm);

    }
    return MemBuf.__makeBytes(digest);
  }
}

