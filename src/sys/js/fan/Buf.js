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

fan.sys.Buf.make = function(capacity)
{
  var c = capacity || 1024;
  return fan.sys.MemBuf.makeCapacity(c);
}

fan.sys.Buf.random = function(size)
{
  var buf = [];
  for (var i=0; i<size;)
  {
    var x = Math.random() * 4294967296;
    buf[i++] = (0xff & (x >> 24));
    if (i < size)
    {
      buf[i++] = (0xff & (x >> 16));
      if (i < size)
      {
        buf[i++] = (0xff & (x >> 8));
        if (i < size) buf[i++] = (0xff & x);
      }
    }
  }
  return fan.sys.MemBuf.makeBytes(buf);
}

//////////////////////////////////////////////////////////////////////////
// Obj
//////////////////////////////////////////////////////////////////////////

fan.sys.Buf.prototype.equals = function(that)
{
  return this == that;
}

fan.sys.Buf.prototype.toStr = function()
{
  return this.$typeof().$name() + "(pos=" + this.pos() + " size=" + this.size() + ")";
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
fan.sys.Buf.prototype.capacity$ = function(c) {}

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

  var slice = this.getBytes(s, n);

  var result = new fan.sys.MemBuf(slice, n);
  result.charset$(this.charset());
  return result;
}

fan.sys.Buf.prototype.dup = function()
{
  var size = this.size();
  var copy = this.getBytes(0, size);

  var result = new fan.sys.MemBuf(copy, size);
  result.charset$(this.charset());
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

fan.sys.Buf.prototype.endian = function() { return this.m_out.endian(); }
fan.sys.Buf.prototype.endian$ = function(endian)
{
  this.m_out.endian$(endian);
  this.m_in.endian$(endian);
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

fan.sys.Buf.prototype.toHex = function()
{
  var buf = this.unsafeArray();
  var size = this.size();
  var hexChars = fan.sys.Buf.hexChars;
  var s = "";
  for (var i=0; i<size; ++i)
  {
    var b = buf[i] & 0xFF;
    s += String.fromCharCode(hexChars[b>>4]) + String.fromCharCode(hexChars[b&0xf]);
  }
  return s;
}

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
  return this.$doBase64(fan.sys.Buf.base64chars, true);
}

fan.sys.Buf.prototype.toBase64Uri = function()
{
  return this.$doBase64(fan.sys.Buf.base64UriChars, false);
}

fan.sys.Buf.prototype.$doBase64 = function(table, pad)
{
  var buf = this.m_buf;
  var size = this.m_size;
  var s = '';
  var i = 0;

  // append full 24-bit chunks
  var end = size-2;
  for (; i<end; i += 3)
  {
    var n = ((buf[i] & 0xff) << 16) + ((buf[i+1] & 0xff) << 8) + (buf[i+2] & 0xff);
    s += String.fromCharCode(table[(n >>> 18) & 0x3f]);
    s += String.fromCharCode(table[(n >>> 12) & 0x3f]);
    s += String.fromCharCode(table[(n >>> 6) & 0x3f]);
    s += String.fromCharCode(table[n & 0x3f]);
  }

  // pad and encode remaining bits
  var rem = size - i;
  if (rem > 0)
  {
    var n = ((buf[i] & 0xff) << 10) | (rem == 2 ? ((buf[size-1] & 0xff) << 2) : 0);
    s += String.fromCharCode(table[(n >>> 12) & 0x3f]);
    s += String.fromCharCode(table[(n >>> 6) & 0x3f]);
    s += rem == 2 ? String.fromCharCode(table[n & 0x3f]) : (pad ? '=' : "");
    if (pad) s += '=';
  }

  return s;
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


fan.sys.Buf.base64UriChars = [
//A  B  C  D  E  F  G  H  I  J  K  L  M  N  O  P  Q  R  S  T  U  V  W  X  Y  Z
  65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,
//a  b  c  d   e   f   g   h   i   j   k   l   m   n   o   p   q   r   s   t   u   v   w   x   y   z
  97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122,
//0  1  2  3  4  5  6  7  8  9  -  _
  48,49,50,51,52,53,54,55,56,57,45,95];

fan.sys.Buf.base64inv = [];
for (var i=0; i<128; ++i) fan.sys.Buf.base64inv[i] = -1;
for (var i=0; i<fan.sys.Buf.base64chars.length; ++i)
  fan.sys.Buf.base64inv[fan.sys.Buf.base64chars[i]] = i;
fan.sys.Buf.base64inv[45] = 62; // '-'
fan.sys.Buf.base64inv[95] = 63; // '_'
fan.sys.Buf.base64inv[61] = 0;  // '='

//////////////////////////////////////////////////////////////////////////
// Digest
//////////////////////////////////////////////////////////////////////////

fan.sys.Buf.prototype.toDigest = function(algorithm)
{
  // trim buf to content
  var buf = this.m_buf.slice(0, this.m_size);

  var digest = null;
  switch (algorithm)
  {
    case "MD5":
      digest = fan.sys.Buf_Md5(buf);  break;
    case "SHA1":
    case "SHA-1":
      // fall-through
      digest = fan.sys.buf_sha1.digest(buf); break;
    case "SHA-256":
      digest = fan.sys.buf_sha256.digest(buf); break;
    default: throw fan.sys.ArgErr.make("Unknown digest algorithm " + algorithm);
  }
  return fan.sys.MemBuf.makeBytes(digest);
}

fan.sys.Buf.prototype.hmac = function(algorithm, keyBuf)
{
  // trim buf to content
  var buf = this.m_buf.slice(0, this.m_size);
  var key = keyBuf.m_buf.slice(0, keyBuf.m_size);

  var digest = null;
  switch (algorithm)
  {
    case "MD5":
      digest = fan.sys.Buf_Md5(buf, key);  break;
    case "SHA1":
    case "SHA-1":
      // fall thru
      digest = fan.sys.buf_sha1.digest(buf, key); break;
    case "SHA-256":
      digest = fan.sys.buf_sha256.digest(buf, key); break;
    default: throw fan.sys.ArgErr.make("Unknown digest algorithm " + algorithm);
  }
  return fan.sys.MemBuf.makeBytes(digest);
}

//////////////////////////////////////////////////////////////////////////
// CRC
//////////////////////////////////////////////////////////////////////////

fan.sys.Buf.prototype.crc = function(algorithm)
{
  if (algorithm == "CRC-16") return this.crc16();
  if (algorithm == "CRC-32") return this.crc32();
  if (algorithm == "CRC-32-Adler") return this.crcAdler32();
  throw fan.sys.ArgErr.make("Unknown CRC algorthm: " + algorithm);
}

fan.sys.Buf.prototype.crc16 = function()
{
  var array = this.unsafeArray();
  var size = this.size();
  var seed = 0xffff;
  for (var i=0; i<size; ++i) seed = this.$crc16(array[i], seed);
  return seed;
}

fan.sys.Buf.prototype.$crc16 = function(dataToCrc, seed)
{
  var dat = ((dataToCrc ^ (seed & 0xFF)) & 0xFF);
  seed = (seed & 0xFFFF) >>> 8;
  var index1 = (dat & 0x0F);
  var index2 = (dat >>> 4);
  if ((fan.sys.Buf.CRC16_ODD_PARITY[index1] ^ fan.sys.Buf.CRC16_ODD_PARITY[index2]) == 1)
    seed ^= 0xC001;
  dat  <<= 6;
  seed ^= dat;
  dat  <<= 1;
  seed ^= dat;
  return seed;
}

fan.sys.Buf.prototype.crc32 = function()
{
  // From StackOverflow:
  // https://stackoverflow.com/questions/18638900/javascript-crc32#answer-18639975

  var array = this.unsafeArray();
  var crc = -1;
  for (var i=0, iTop=array.length; i<iTop; i++)
  {
    crc = ( crc >>> 8 ) ^ fan.sys.Buf.CRC32_b_table[(crc ^ array[i]) & 0xFF];
  }
  return (crc ^ (-1)) >>> 0;
};

fan.sys.Buf.prototype.crcAdler32 = function(seed)
{
  // https://github.com/SheetJS/js-adler32
  //
  // Copyright (C) 2014-present  SheetJS
  // Licensed under Apache 2.0

  var array = this.unsafeArray();
	var a = 1, b = 0, L = array.length, M = 0;
	if (typeof seed === 'number') { a = seed & 0xFFFF; b = (seed >>> 16) & 0xFFFF; }
	for(var i=0; i<L;)
  {
		M = Math.min(L-i, 3850) + i;
		for(; i<M; i++)
    {
			a += array[i] & 0xFF;
			b += a;
		}
		a = (15 * (a >>> 16) + (a & 65535));
		b = (15 * (b >>> 16) + (b & 65535));
	}
	return ((b % 65521) << 16) | (a % 65521);
}

fan.sys.Buf.CRC16_ODD_PARITY = [ 0, 1, 1, 0, 1, 0, 0, 1, 1, 0, 0, 1, 0, 1, 1, 0 ];

fan.sys.Buf.CRC32_a_table =
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

fan.sys.Buf.CRC32_b_table = fan.sys.Buf.CRC32_a_table.split(' ').map(function(s){ return parseInt(s,16) });

//////////////////////////////////////////////////////////////////////////
// PBKDF2
//////////////////////////////////////////////////////////////////////////

fan.sys.Buf.pbk = function(algorithm, password, salt, iterations, keyLen)
{
  var digest = null;
  var passBuf = fan.sys.Str.toBuf(password);

  // trim buf to content
  passBytes = passBuf.m_buf.slice(0, passBuf.m_size);
  saltBytes = salt.m_buf.slice(0, salt.m_size);

  switch(algorithm)
  {
    case "PBKDF2WithHmacSHA1":
      digest = fan.sys.buf_sha1.pbkdf2(passBytes, saltBytes, iterations, keyLen); break;
    case "PBKDF2WithHmacSHA256":
      digest = fan.sys.buf_sha256.pbkdf2(passBytes, saltBytes, iterations, keyLen); break;
    default: throw fan.sys.Err.make("Unsupported algorithm: " + algorithm);

  }
  return fan.sys.MemBuf.makeBytes(digest);
}
