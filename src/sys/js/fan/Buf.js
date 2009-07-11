//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   1 Apr 09   Andy Frank  Creation
//   20 May 09  Andy Frank  Refactor to new OO model
//

/**
 * Buf.
 */
fan.sys.Buf = fan.sys.Obj.$extend(fan.sys.Obj);

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

fan.sys.Buf.prototype.$ctor = function() {}
fan.sys.Buf.make = function(capacity) { return new fan.sys.MemBuf(); }

//////////////////////////////////////////////////////////////////////////
// Obj
//////////////////////////////////////////////////////////////////////////

fan.sys.Buf.prototype.equals = function(that)
{
  return this == that;
}

fan.sys.Buf.prototype.toStr = function()
{
  return this.type().name() + "(pos=" + this.pos() + " size=" + this.size() + ")";
}

fan.sys.Buf.prototype.type = function()
{
  return fan.sys.Type.find("sys::Buf");
}

//////////////////////////////////////////////////////////////////////////
// Access
//////////////////////////////////////////////////////////////////////////

fan.sys.Buf.prototype.empty = function() { return this.size() == 0; }

fan.sys.Buf.prototype.capacity = function() { return fan.sys.Int.maxVal; }
//fan.sys.Buf.prototype.capacity$ = function(long c) {}

fan.sys.Buf.prototype.remaining = function() { return this.size()-this.pos(); }

fan.sys.Buf.prototype.more = function() { return this.size()-this.pos() > 0; }

fan.sys.Buf.prototype.seek = function(pos)
{
  var size = this.size();
  if (pos < 0) pos = size + pos;
  if (pos < 0 || pos > size) throw fan.sys.IndexErr.make(pos);
  pos(pos);
  return this;
}

fan.sys.Buf.prototype.flip = function()
{
  this.size(this.pos());
  this.pos(0);
  return this;
}

fan.sys.Buf.prototype.get = function(pos)
{
  var size = this.size();
  if (pos < 0) pos = size + pos;
  if (pos < 0 || pos >= size) throw fan.sys.IndexErr.make(pos);
  return this.getByte(pos);
}

fan.sys.Buf.prototype.slice = function(range)
{
  var size = this.size();
  var s = range.start(size);
  var e = range.end(size);
  var n = (e - s + 1);
  if (n < 0) throw fan.sys.IndexErr.make(range);

  var slice = [];
  this.getBytes(s, slice, 0, n);

  var result = new fan.sys.MemBuf(slice, n);
  //result.charset(charset());
  return result;
}

fan.sys.Buf.prototype.dup = function()
{
  var size = this.size();
  var copy = [];
  this.getBytes(0, copy, 0, size);

  var result = new MemBuf(copy, size);
  //result.charset(charset());
  return result;
}

//////////////////////////////////////////////////////////////////////////
// Modification
//////////////////////////////////////////////////////////////////////////

fan.sys.Buf.prototype.set = function(pos, b)
{
  var size = this.size();
  if (pos < 0) pos = size + pos;
  if (pos < 0 || pos >= size) throw fan.sys.IndexErr.make(pos);
  this.setByte(pos, b);
  return this;
}

fan.sys.Buf.prototype.trim = function()
{
  return this;
}

fan.sys.Buf.prototype.clear = function()
{
  this.pos(0);
  this.size(0);
  return this;
}

fan.sys.Buf.prototype.flush = function()
{
  return this;
}

fan.sys.Buf.prototype.close = function()
{
  return true;
}

fan.sys.Buf.prototype.charset = function()
{
  return this.m_out.charset();
}

fan.sys.Buf.prototype.charset = function(charset)
{
  this.m_out.charset(charset);
  this.m_in.charset(charset);
}

fan.sys.Buf.prototype.fill = function(b, times)
{
  if (this.capacity() < this.size()+times) this.capacity(this.size()+times);
  for (var i=0; i<times; ++i) this.m_out.write(b);
  return this;
}

//////////////////////////////////////////////////////////////////////////
// OutStream
//////////////////////////////////////////////////////////////////////////

fan.sys.Buf.prototype.out = function() { return this.m_out; }

fan.sys.Buf.prototype.write = function(b) { this.m_out.write(b); return this; }

//fan.sys.Buf.prototype.writeBuf = function(other) { this.m_out.writeBuf(other); return this; }
//fan.sys.Buf.prototype.writeBuf = function(other, n) { this.m_out.writeBuf(other, n); return this; }

fan.sys.Buf.prototype.writeI2 = function(x) { this.m_out.writeI2(x); return this; }

fan.sys.Buf.prototype.writeI4 = function(x) { this.m_out.writeI4(x); return this; }

fan.sys.Buf.prototype.writeI8 = function(x) { this.m_out.writeI8(x); return this; }

fan.sys.Buf.prototype.writeF4 = function(x) { this.m_out.writeF4(x); return this; }

fan.sys.Buf.prototype.writeF8 = function(x) { this.m_out.writeF8(x); return this; }

fan.sys.Buf.prototype.writeDecimal = function(x) { this.m_out.writeDecimal(x); return this; }

fan.sys.Buf.prototype.writeBool = function(x) { this.m_out.writeBool(x); return this; }

fan.sys.Buf.prototype.writeUtf = function(x) { this.m_out.writeUtf(x); return this; }

fan.sys.Buf.prototype.writeChar = function(c) { this.m_out.writeChar(c); return this; }

//fan.sys.Buf.prototype.writeChars = function(s) { this.m_out.writeChars(s); return this; }
//fan.sys.Buf.prototype.writeChars = function(s, off) { this.m_out.writeChars(s, off); return this; }
//fan.sys.Buf.prototype.writeChars = function(s, off, len) { this.m_out.writeChars(s, off, len); return this; }

fan.sys.Buf.prototype.print = function(obj) { this.m_out.print(obj); return this; }

//fan.sys.Buf.prototype.printLine = function() { this.m_out.printLine(); return this; }
//fan.sys.Buf.prototype.printLine = function(obj) { this.m_out.printLine(obj); return this; }

//fan.sys.Buf.prototype.writeObj = function(obj) { this.m_out.writeObj(obj); return this; }
//fan.sys.Buf.prototype.writeObj = function(obj, opt) { this.m_out.writeObj(obj, opt); return this; }

//fan.sys.Buf.prototype.writeXml = function(s) { this.m_out.writeXml(s, 0); return this; }
//fan.sys.Buf.prototype.writeXml = function(s, flags) { this.m_out.writeXml(s, flags); return this; }

//////////////////////////////////////////////////////////////////////////
// InStream
//////////////////////////////////////////////////////////////////////////

fan.sys.Buf.prototype.$in = function() { return this.m_in; }

fan.sys.Buf.prototype.read = function() {  return this.m_in.read(); }

fan.sys.Buf.prototype.readBuf = function(other, n) { return this.m_in.readBuf(other, n); }

fan.sys.Buf.prototype.unread = function(n) { this.m_in.unread(n); return this; }

fan.sys.Buf.prototype.readBufFully = function(buf, n) { return this.m_in.readBufFully(buf, n); }

fan.sys.Buf.prototype.readAllBuf = function() { return this.m_in.readAllBuf(); }

fan.sys.Buf.prototype.peek = function() { return this.m_in.peek(); }

fan.sys.Buf.prototype.readU1 = function() { return this.m_in.readU1(); }

fan.sys.Buf.prototype.readS1 = function() { return this.m_in.readS1(); }

fan.sys.Buf.prototype.readU2 = function() { return this.m_in.readU2(); }

fan.sys.Buf.prototype.readS2 = function() { return this.m_in.readS2(); }

fan.sys.Buf.prototype.readU4 = function() { return this.m_in.readU4(); }

fan.sys.Buf.prototype.readS4 = function() { return this.m_in.readS4(); }

fan.sys.Buf.prototype.readS8 = function() { return this.m_in.readS8(); }

fan.sys.Buf.prototype.readF4 = function() { return this.m_in.readF4(); }

fan.sys.Buf.prototype.readF8 = function() { return this.m_in.readF8(); }

fan.sys.Buf.prototype.readDecimal = function() { return this.m_in.readDecimal(); }

fan.sys.Buf.prototype.readBool = function() { return this.m_in.readBool(); }

fan.sys.Buf.prototype.readUtf = function() { return this.m_in.readUtf(); }

fan.sys.Buf.prototype.readChar = function() { return this.m_in.readChar(); }

fan.sys.Buf.prototype.unreadChar = function(c) { this.m_in.unreadChar(c); return this; }

fan.sys.Buf.prototype.peekChar = function() { return this.m_in.peekChar(); }

//fan.sys.Buf.prototype.readLine = function() { return this.m_in.readLine(); }
//fan.sys.Buf.prototype.readLine = function(max) { return this.m_in.readLine(max); }

//fan.sys.Buf.prototype.readStrToken = function() { return this.m_in.readStrToken(); }
//fan.sys.Buf.prototype.readStrToken = function(Long max) { return this.m_in.readStrToken(max); }
//fan.sys.Buf.prototype.readStrToken = function(Long max, Func f) { return this.m_in.readStrToken(FanInt.Chunk, f); }

fan.sys.Buf.prototype.readAllLines = function() { return this.m_in.readAllLines(); }

fan.sys.Buf.prototype.eachLine = function(f) { this.m_in.eachLine(f); }

fan.sys.Buf.prototype.readAllStr = function(normalizeNewlines)
{
  if (normalizeNewlines == undefined) normalizeNewlines = true;
  return this.m_in.readAllStr(normalizeNewlines);
}

//fan.sys.Buf.prototype.readObj = function() { return this.m_in.readObj(); }
//fan.sys.Buf.prototype.readObj = function(opt) { return this.m_in.readObj(opt); }

//////////////////////////////////////////////////////////////////////////
// Hex
//////////////////////////////////////////////////////////////////////////

// toHex
// fromHex

fan.sys.Buf.hexChars = [
//0  1  2  3  4  5  6  7  8  9  a  b  c  d   e   f
  48,49,50,51,52,53,54,55,56,57,97,98,99,100,101,102];

//////////////////////////////////////////////////////////////////////////
// Base64
//////////////////////////////////////////////////////////////////////////

// toBase64
// fromBase64

fan.sys.Buf.base64chars = [
//A  B  C  D  E  F  G  H  I  J  K  L  M  N  O  P  Q  R  S  T  U  V  W  X  Y  Z
  65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,
//a  b  c  d   e   f   g   h   i   j   k   l   m   n   o   p   q   r   s   t   u   v   w   x   y   z
  97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122,
//0  1  2  3  4  5  6  7  8  9  +  /
  48,49,50,51,52,53,54,55,56,57,43,47];

//////////////////////////////////////////////////////////////////////////
// MD5
//////////////////////////////////////////////////////////////////////////

fan.sys.Buf_Md5 = function(buf)
{
  /**
   * A JavaScript implementation of the RSA Data Security, Inc. MD5 Message
   * Digest Algorithm, as defined in RFC 1321.
   * Version 2.1 Copyright (C) Paul Johnston 1999 - 2002.
   * Other contributors: Greg Holt, Andrew Kepert, Ydnar, Lostinet
   * Distributed under the BSD License
   * See http://pajhome.org.uk/crypt/md5 for more info.
   */

  var chrsz = 8;  /* bits per input character. 8 - ASCII; 16 - Unicode */

  /*
   * Calculate the MD5 of an array of little-endian words, and a bit length
   */
  function core_md5(x, len)
  {
    /* append padding */
    x[len >> 5] |= 0x80 << ((len) % 32);
    x[(((len + 64) >>> 9) << 4) + 14] = len;

    var a =  1732584193;
    var b = -271733879;
    var c = -1732584194;
    var d =  271733878;

    for(var i=0; i<x.length; i+=16)
    {
      var olda = a;
      var oldb = b;
      var oldc = c;
      var oldd = d;

      a = md5_ff(a, b, c, d, x[i+ 0], 7 , -680876936);
      d = md5_ff(d, a, b, c, x[i+ 1], 12, -389564586);
      c = md5_ff(c, d, a, b, x[i+ 2], 17,  606105819);
      b = md5_ff(b, c, d, a, x[i+ 3], 22, -1044525330);
      a = md5_ff(a, b, c, d, x[i+ 4], 7 , -176418897);
      d = md5_ff(d, a, b, c, x[i+ 5], 12,  1200080426);
      c = md5_ff(c, d, a, b, x[i+ 6], 17, -1473231341);
      b = md5_ff(b, c, d, a, x[i+ 7], 22, -45705983);
      a = md5_ff(a, b, c, d, x[i+ 8], 7 ,  1770035416);
      d = md5_ff(d, a, b, c, x[i+ 9], 12, -1958414417);
      c = md5_ff(c, d, a, b, x[i+10], 17, -42063);
      b = md5_ff(b, c, d, a, x[i+11], 22, -1990404162);
      a = md5_ff(a, b, c, d, x[i+12], 7 ,  1804603682);
      d = md5_ff(d, a, b, c, x[i+13], 12, -40341101);
      c = md5_ff(c, d, a, b, x[i+14], 17, -1502002290);
      b = md5_ff(b, c, d, a, x[i+15], 22,  1236535329);

      a = md5_gg(a, b, c, d, x[i+ 1], 5 , -165796510);
      d = md5_gg(d, a, b, c, x[i+ 6], 9 , -1069501632);
      c = md5_gg(c, d, a, b, x[i+11], 14,  643717713);
      b = md5_gg(b, c, d, a, x[i+ 0], 20, -373897302);
      a = md5_gg(a, b, c, d, x[i+ 5], 5 , -701558691);
      d = md5_gg(d, a, b, c, x[i+10], 9 ,  38016083);
      c = md5_gg(c, d, a, b, x[i+15], 14, -660478335);
      b = md5_gg(b, c, d, a, x[i+ 4], 20, -405537848);
      a = md5_gg(a, b, c, d, x[i+ 9], 5 ,  568446438);
      d = md5_gg(d, a, b, c, x[i+14], 9 , -1019803690);
      c = md5_gg(c, d, a, b, x[i+ 3], 14, -187363961);
      b = md5_gg(b, c, d, a, x[i+ 8], 20,  1163531501);
      a = md5_gg(a, b, c, d, x[i+13], 5 , -1444681467);
      d = md5_gg(d, a, b, c, x[i+ 2], 9 , -51403784);
      c = md5_gg(c, d, a, b, x[i+ 7], 14,  1735328473);
      b = md5_gg(b, c, d, a, x[i+12], 20, -1926607734);

      a = md5_hh(a, b, c, d, x[i+ 5], 4 , -378558);
      d = md5_hh(d, a, b, c, x[i+ 8], 11, -2022574463);
      c = md5_hh(c, d, a, b, x[i+11], 16,  1839030562);
      b = md5_hh(b, c, d, a, x[i+14], 23, -35309556);
      a = md5_hh(a, b, c, d, x[i+ 1], 4 , -1530992060);
      d = md5_hh(d, a, b, c, x[i+ 4], 11,  1272893353);
      c = md5_hh(c, d, a, b, x[i+ 7], 16, -155497632);
      b = md5_hh(b, c, d, a, x[i+10], 23, -1094730640);
      a = md5_hh(a, b, c, d, x[i+13], 4 ,  681279174);
      d = md5_hh(d, a, b, c, x[i+ 0], 11, -358537222);
      c = md5_hh(c, d, a, b, x[i+ 3], 16, -722521979);
      b = md5_hh(b, c, d, a, x[i+ 6], 23,  76029189);
      a = md5_hh(a, b, c, d, x[i+ 9], 4 , -640364487);
      d = md5_hh(d, a, b, c, x[i+12], 11, -421815835);
      c = md5_hh(c, d, a, b, x[i+15], 16,  530742520);
      b = md5_hh(b, c, d, a, x[i+ 2], 23, -995338651);

      a = md5_ii(a, b, c, d, x[i+ 0], 6 , -198630844);
      d = md5_ii(d, a, b, c, x[i+ 7], 10,  1126891415);
      c = md5_ii(c, d, a, b, x[i+14], 15, -1416354905);
      b = md5_ii(b, c, d, a, x[i+ 5], 21, -57434055);
      a = md5_ii(a, b, c, d, x[i+12], 6 ,  1700485571);
      d = md5_ii(d, a, b, c, x[i+ 3], 10, -1894986606);
      c = md5_ii(c, d, a, b, x[i+10], 15, -1051523);
      b = md5_ii(b, c, d, a, x[i+ 1], 21, -2054922799);
      a = md5_ii(a, b, c, d, x[i+ 8], 6 ,  1873313359);
      d = md5_ii(d, a, b, c, x[i+15], 10, -30611744);
      c = md5_ii(c, d, a, b, x[i+ 6], 15, -1560198380);
      b = md5_ii(b, c, d, a, x[i+13], 21,  1309151649);
      a = md5_ii(a, b, c, d, x[i+ 4], 6 , -145523070);
      d = md5_ii(d, a, b, c, x[i+11], 10, -1120210379);
      c = md5_ii(c, d, a, b, x[i+ 2], 15,  718787259);
      b = md5_ii(b, c, d, a, x[i+ 9], 21, -343485551);

      a = safe_add(a, olda);
      b = safe_add(b, oldb);
      c = safe_add(c, oldc);
      d = safe_add(d, oldd);
    }
    return Array(a, b, c, d);
  }

  /*
   * These functions implement the four basic operations the algorithm uses.
   */
  function md5_cmn(q, a, b, x, s, t) { return safe_add(bit_rol(safe_add(safe_add(a, q), safe_add(x, t)), s),b); }
  function md5_ff(a, b, c, d, x, s, t) { return md5_cmn((b & c) | ((~b) & d), a, b, x, s, t); }
  function md5_gg(a, b, c, d, x, s, t) { return md5_cmn((b & d) | (c & (~d)), a, b, x, s, t); }
  function md5_hh(a, b, c, d, x, s, t) { return md5_cmn(b ^ c ^ d, a, b, x, s, t); }
  function md5_ii(a, b, c, d, x, s, t) { return md5_cmn(c ^ (b | (~d)), a, b, x, s, t); }

  /*
   * Add integers, wrapping at 2^32. This uses 16-bit operations internally
   * to work around bugs in some JS interpreters.
   */
  function safe_add(x, y)
  {
    var lsw = (x & 0xFFFF) + (y & 0xFFFF);
    var msw = (x >> 16) + (y >> 16) + (lsw >> 16);
    return (msw << 16) | (lsw & 0xFFFF);
  }

  /*
   * Bitwise rotate a 32-bit number to the left.
   */
  function bit_rol(num, cnt)
  {
    return (num << cnt) | (num >>> (32 - cnt));
  }

  /*
   * Convert a byte array to an array of little-endian words.
   */
  function bytesToWords(bytes)
  {
    var words = new Array();
    var size = bytes.length;

    // handle full 32-bit words
    for (var i=0; size>3 && (i+4)<size; i+=4)
    {
      words.push((bytes[i+3]<<24) | (bytes[i+2]<<16) | (bytes[i+1]<<8) | bytes[i]);
    }

    // handle remaning bytes
    var rem = bytes.length % 4;
    if (rem > 0)
    {
      if (rem == 3) words.push((bytes[size-1]<<16) | (bytes[size-2]<<8) | bytes[size-3]);
      if (rem == 2) words.push((bytes[size-1]<<8) | bytes[size-2]);
      if (rem == 1) words.push(bytes[size-1]);
    }

    return words;
  }

  var words = bytesToWords(buf);
  var dw = core_md5(words, buf.length * chrsz);
  var db = new Array();
  for (var i=0; i<dw.length; i++)
  {
    db.push(0xff & dw[i]);
    db.push(0xff & (dw[i] >> 8));
    db.push(0xff & (dw[i] >> 16));
    db.push(0xff & (dw[i] >> 24));
  }
  return db;
}

//////////////////////////////////////////////////////////////////////////
// SHA-1
//////////////////////////////////////////////////////////////////////////

fan.sys.Buf_Sha1 = function(buf)
{
  /*
   * A JavaScript implementation of the Secure Hash Algorithm, SHA-1, as defined
   * in FIPS PUB 180-1
   * Version 2.1a Copyright Paul Johnston 2000 - 2002.
   * Other contributors: Greg Holt, Andrew Kepert, Ydnar, Lostinet
   * Distributed under the BSD License
   * See http://pajhome.org.uk/crypt/md5 for details.
   */

  var chrsz = 8;  /* bits per input character. 8 - ASCII; 16 - Unicode */

  /*
   * Calculate the SHA-1 of an array of big-endian words, and a bit length
   */
  function core_sha1(x, len)
  {
    /* append padding */
    x[len >> 5] |= 0x80 << (24 - len % 32);
    x[((len + 64 >> 9) << 4) + 15] = len;

    var w = Array(80);
    var a =  1732584193;
    var b = -271733879;
    var c = -1732584194;
    var d =  271733878;
    var e = -1009589776;

    for(var i = 0; i < x.length; i += 16)
    {
      var olda = a;
      var oldb = b;
      var oldc = c;
      var oldd = d;
      var olde = e;

      for(var j = 0; j < 80; j++)
      {
        if(j < 16) w[j] = x[i + j];
        else w[j] = rol(w[j-3] ^ w[j-8] ^ w[j-14] ^ w[j-16], 1);
        var t = safe_add(safe_add(rol(a, 5), sha1_ft(j, b, c, d)),
                         safe_add(safe_add(e, w[j]), sha1_kt(j)));
        e = d;
        d = c;
        c = rol(b, 30);
        b = a;
        a = t;
      }

      a = safe_add(a, olda);
      b = safe_add(b, oldb);
      c = safe_add(c, oldc);
      d = safe_add(d, oldd);
      e = safe_add(e, olde);
    }
    return Array(a, b, c, d, e);
  }

  /*
   * Perform the appropriate triplet combination function for the current
   * iteration
   */
  function sha1_ft(t, b, c, d)
  {
    if(t < 20) return (b & c) | ((~b) & d);
    if(t < 40) return b ^ c ^ d;
    if(t < 60) return (b & c) | (b & d) | (c & d);
    return b ^ c ^ d;
  }

  /*
   * Determine the appropriate additive constant for the current iteration
   */
  function sha1_kt(t)
  {
    return (t < 20) ?  1518500249 : (t < 40) ?  1859775393 :
           (t < 60) ? -1894007588 : -899497514;
  }

  /*
   * Add integers, wrapping at 2^32. This uses 16-bit operations internally
   * to work around bugs in some JS interpreters.
   */
  function safe_add(x, y)
  {
    var lsw = (x & 0xFFFF) + (y & 0xFFFF);
    var msw = (x >> 16) + (y >> 16) + (lsw >> 16);
    return (msw << 16) | (lsw & 0xFFFF);
  }

  /*
   * Bitwise rotate a 32-bit number to the left.
   */
  function rol(num, cnt)
  {
    return (num << cnt) | (num >>> (32 - cnt));
  }

  /*
   * Convert a byte array to an array of big-endian words.
   */
  function bytesToWords(bytes)
  {
    var words = new Array();
    var size = bytes.length;

    // handle full 32-bit words
    for (var i=0; size>3 && (i+4)<size; i+=4)
    {
      words.push((bytes[i]<<24) | (bytes[i+1]<<16) | (bytes[i+2]<<8) | bytes[i+3]);
    }

    // handle remaning bytes
    var rem = bytes.length % 4;
    if (rem > 0)
    {
      if (rem == 3) words.push((bytes[size-3]<<24) | (bytes[size-2]<<16) | bytes[size-1]<<8);
      if (rem == 2) words.push((bytes[size-2]<<24) | bytes[size-1]<<16);
      if (rem == 1) words.push(bytes[size-1]<<24);
    }

    return words;
  }

  var words = bytesToWords(buf);
  var dw = core_sha1(words, buf.length * chrsz);
  var db = new Array();
  for (var i=0; i<dw.length; i++)
  {
    db.push(0xff & (dw[i] >> 24));
    db.push(0xff & (dw[i] >> 16));
    db.push(0xff & (dw[i] >> 8));
    db.push(0xff & dw[i]);
  }
  return db;
}

