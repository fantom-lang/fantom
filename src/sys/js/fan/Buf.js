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
  return this.$typeof().name() + "(pos=" + this.pos() + " size=" + this.size() + ")";
}

fan.sys.Buf.prototype.$typeof = function()
{
  return fan.sys.Buf.$type;
}

//////////////////////////////////////////////////////////////////////////
// Access
//////////////////////////////////////////////////////////////////////////

fan.sys.Buf.prototype.isEmpty = function() { return this.size() == 0; }

fan.sys.Buf.prototype.capacity = function() { return fan.sys.Int.m_maxVal; }
//fan.sys.Buf.prototype.capacity$ = function(long c) {}

fan.sys.Buf.prototype.remaining = function() { return this.size()-this.pos(); }

fan.sys.Buf.prototype.more = function() { return this.size()-this.pos() > 0; }

fan.sys.Buf.prototype.seek = function(pos)
{
  var size = this.size();
  if (pos < 0) pos = size + pos;
  if (pos < 0 || pos > size) throw fan.sys.IndexErr.make(pos);
  this.pos$(pos);
  return this;
}

fan.sys.Buf.prototype.flip = function()
{
  this.size(this.pos());
  this.pos$(0);
  return this;
}

fan.sys.Buf.prototype.get = function(pos)
{
  var size = this.size();
  if (pos < 0) pos = size + pos;
  if (pos < 0 || pos >= size) throw fan.sys.IndexErr.make(pos);
  return this.getByte(pos);
}

fan.sys.Buf.prototype.getRange = function(range)
{
  var size = this.size();
  var s = range.$start(size);
  var e = range.$end(size);
  var n = (e - s + 1);
  if (n < 0) throw fan.sys.IndexErr.make(range);

  var slice = [];
  this.getBytes(s, slice, 0, n);

  var result = new fan.sys.MemBuf(slice, n);
  result.charset$(this.m_out.charset());
  return result;
}

fan.sys.Buf.prototype.dup = function()
{
  var size = this.size();
  var copy = [];
  this.getBytes(0, copy, 0, size);

  var result = new MemBuf(copy, size);
  result.charset$(this.m_out.charset());
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
  this.pos$(0);
  this.size$(0);
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

fan.sys.Buf.prototype.charset$ = function(charset)
{
  this.m_out.charset$(charset);
  this.m_in.charset$(charset);
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

fan.sys.Buf.prototype.writeBuf = function(other, n) { this.m_out.writeBuf(other, n); return this; }

fan.sys.Buf.prototype.writeI2 = function(x) { this.m_out.writeI2(x); return this; }

fan.sys.Buf.prototype.writeI4 = function(x) { this.m_out.writeI4(x); return this; }

fan.sys.Buf.prototype.writeI8 = function(x) { this.m_out.writeI8(x); return this; }

fan.sys.Buf.prototype.writeF4 = function(x) { this.m_out.writeF4(x); return this; }

fan.sys.Buf.prototype.writeF8 = function(x) { this.m_out.writeF8(x); return this; }

fan.sys.Buf.prototype.writeDecimal = function(x) { this.m_out.writeDecimal(x); return this; }

fan.sys.Buf.prototype.writeBool = function(x) { this.m_out.writeBool(x); return this; }

fan.sys.Buf.prototype.writeUtf = function(x) { this.m_out.writeUtf(x); return this; }

fan.sys.Buf.prototype.writeChar = function(c) { this.m_out.writeChar(c); return this; }

fan.sys.Buf.prototype.writeChars = function(s, off, len) { this.m_out.writeChars(s, off, len); return this; }

fan.sys.Buf.prototype.print = function(obj) { this.m_out.print(obj); return this; }

fan.sys.Buf.prototype.printLine = function(obj) { this.m_out.printLine(obj); return this; }

fan.sys.Buf.prototype.writeObj = function(obj, opt) { this.m_out.writeObj(obj, opt); return this; }

fan.sys.Buf.prototype.writeXml = function(s, flags) { this.m_out.writeXml(s, flags); return this; }

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

fan.sys.Buf.prototype.readChars = function(n) { return this.m_in.readChars(n); }

fan.sys.Buf.prototype.readLine = function(max) { return this.m_in.readLine(max); }

fan.sys.Buf.prototype.readStrToken = function(max, f) { return this.m_in.readStrToken(max, f); }

fan.sys.Buf.prototype.readAllLines = function() { return this.m_in.readAllLines(); }

fan.sys.Buf.prototype.eachLine = function(f) { this.m_in.eachLine(f); }

fan.sys.Buf.prototype.readAllStr = function(normNewlines) { return this.m_in.readAllStr(normNewlines); }

fan.sys.Buf.prototype.readObj = function(opt) { return this.m_in.readObj(opt); }

fan.sys.Buf.prototype.readProps = function() { return this.m_in.readProps(); }

fan.sys.Buf.prototype.writeProps = function(props, close) { return this.m_out.writeProps(props, close); }

//////////////////////////////////////////////////////////////////////////
// Hex
//////////////////////////////////////////////////////////////////////////

fan.sys.Buf.fromHex = function(s)
{
  var slen = s.length;
  var buf = [];
  var hexInv = fan.sys.Buf.hexInv;
  var size = 0;

  for (var i=0; i<slen; ++i)
  {
    var c0 = s.charCodeAt(i);
    var n0 = c0 < 128 ? hexInv[c0] : -1;
    if (n0 < 0) continue;

    var n1 = -1;
    if (++i < slen)
    {
      var c1 = s.charCodeAt(i);
      n1 = c1 < 128 ? hexInv[c1] : -1;
    }
    if (n1 < 0) throw fan.sys.IOErr.make("Invalid hex str");

    buf[size++] = (n0 << 4) | n1;
  }

  return fan.sys.MemBuf.makeBytes(buf);
}

fan.sys.Buf.hexChars = [
//0  1  2  3  4  5  6  7  8  9  a  b  c  d   e   f
  48,49,50,51,52,53,54,55,56,57,97,98,99,100,101,102];

fan.sys.Buf.hexInv = [];
for (var i=0; i<128; ++i) fan.sys.Buf.hexInv[i] = -1;
for (var i=0; i<10; ++i)  fan.sys.Buf.hexInv[48+i] = i;
for (var i=10; i<16; ++i) fan.sys.Buf.hexInv[97+i-10] = fan.sys.Buf.hexInv[65+i-10] = i;

//////////////////////////////////////////////////////////////////////////
// Base64
//////////////////////////////////////////////////////////////////////////

fan.sys.Buf.prototype.toBase64 = function()
{
  throw fan.sys.UnsupportedErr.make(this.$typeof()+".toBase64");
}

fan.sys.Buf.fromBase64 = function(s)
{
  var slen = s.length;
  var si = 0;
  var max = slen * 6 / 8;
  var buf = [];
  var size = 0;

  while (si < slen)
  {
    var n = 0;
    var v = 0;
    for (var j=0; j<4 && si<slen;)
    {
      var ch = s.charCodeAt(si++);
      var c = ch < 128 ? fan.sys.Buf.base64inv[ch] : -1;
      if (c >= 0)
      {
        n |= c << (18 - j++ * 6);
        if (ch != 61 /*'='*/) v++;
      }
    }

    if (v > 1) buf.push(n >> 16);
    if (v > 2) buf.push(n >> 8);
    if (v > 3) buf.push(n);
  }

  return fan.sys.MemBuf.makeBytes(buf);
}

fan.sys.Buf.base64chars = [
//A  B  C  D  E  F  G  H  I  J  K  L  M  N  O  P  Q  R  S  T  U  V  W  X  Y  Z
  65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,
//a  b  c  d   e   f   g   h   i   j   k   l   m   n   o   p   q   r   s   t   u   v   w   x   y   z
  97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122,
//0  1  2  3  4  5  6  7  8  9  +  /
  48,49,50,51,52,53,54,55,56,57,43,47];

fan.sys.Buf.base64inv = [];
for (var i=0; i<128; ++i) fan.sys.Buf.base64inv[i] = -1;
for (var i=0; i<fan.sys.Buf.base64chars.length; ++i)
  fan.sys.Buf.base64inv[fan.sys.Buf.base64chars[i]] = i;
fan.sys.Buf.base64inv[61] = 0; // '='

