//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   13 Jun 09  Andy Frank  Creation
//

/**
 * MemBuf.
 */
fan.sys.MemBuf = fan.sys.Obj.$extend(fan.sys.Buf);

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

fan.sys.MemBuf.prototype.$ctor = function(buf, size)
{
  this.m_buf  = (buf  !== undefined) ? buf  : [];
  this.m_size = (size !== undefined) ? size : 0;
  this.m_pos  = 0;
  this.m_out  = new fan.sys.MemBufOutStream(this);
  this.m_in   = new fan.sys.MemBufInStream(this);
}

fan.sys.MemBuf.makeCapacity = function(capacity)
{
  var buf = new fan.sys.MemBuf();
  buf.capacity$(capacity);
  return buf;
}

fan.sys.MemBuf.makeBytes = function(bytes)
{
  var buf = new fan.sys.MemBuf();
  buf.m_buf = bytes;
  buf.m_size = bytes.length;
  return buf;
}

//////////////////////////////////////////////////////////////////////////
// Obj
//////////////////////////////////////////////////////////////////////////

fan.sys.MemBuf.prototype.$typeof = function() { return fan.sys.MemBuf.$type; }

fan.sys.MemBuf.prototype.toImmutable = function()
{
  var buf  = this.m_buf;
  var size = this.m_size;
  this.m_buf = fan.sys.MemBuf.$emptyBytes
  this.m_size = 0;
  return new fan.sys.ConstBuf(buf, size, this.endian(), this.charset());
}

//////////////////////////////////////////////////////////////////////////
// Buf Support
//////////////////////////////////////////////////////////////////////////

fan.sys.MemBuf.prototype.size = function() { return this.m_size; }
fan.sys.MemBuf.prototype.size$ = function(x)
{
  if (x > this.m_buf.length)
  {
    this.m_buf.length = x;
  }
  this.m_size = x;
}

fan.sys.MemBuf.prototype.pos = function() { return this.m_pos; }
fan.sys.MemBuf.prototype.pos$ = function(x) { this.m_pos = x; }

fan.sys.MemBuf.prototype.getByte = function(pos)
{
  return this.m_buf[pos] & 0xFF;
}

fan.sys.MemBuf.prototype.setByte = function(pos, x)
{
  this.m_buf[pos] = x & 0xFF;
}

fan.sys.MemBuf.prototype.getBytes = function(pos, len)
{
  return this.m_buf.slice(pos, pos+len);
}

//////////////////////////////////////////////////////////////////////////
// Java IO Streams (Rhino)
//////////////////////////////////////////////////////////////////////////

fan.sys.MemBuf.prototype.pipeTo = function(dst, len)
{
  if (this.m_pos+len > this.m_size) throw fan.sys.IOErr.make("Not enough bytes to write");
  var byteArray = this.cpMemToJavaBuffer(len)
  dst.write(byteArray, 0, len);
  this.m_pos += len;
}

fan.sys.MemBuf.prototype.pipeFrom = function(src, len)
{
  this.grow(this.m_pos + len);
  var byteArray = new java.lang.reflect.Array.newInstance(java.lang.Byte.TYPE, len);
  var read = src.read(byteArray, 0, len);
   if (read < 0) return -1;
  this.cpJavaBufferToMem(byteArray, read);
  this.m_pos += read;
  this.m_size = this.m_pos;
  return read;
}

fan.sys.MemBuf.prototype.cpMemToJavaBuffer = function(len)
{
  var bytes = new java.lang.reflect.Array.newInstance(java.lang.Byte.TYPE, len);
  for (var i=0; i<len; ++i)
  {
    var b = this.m_buf[this.m_pos+i];
    if (b > 127) b |= 0xFFFFFF00;
    bytes[i] = b;
  }
  return bytes;
}

fan.sys.MemBuf.prototype.cpJavaBufferToMem = function(bytes, len)
{
  for (var i=0; i<len; ++i)
    this.m_buf[this.m_pos+i] = bytes[i] & 0xFF;
}

//////////////////////////////////////////////////////////////////////////
// Buf API
//////////////////////////////////////////////////////////////////////////

fan.sys.MemBuf.prototype.capacity = function()
{
  return this.m_buf.length;
}

fan.sys.MemBuf.prototype.capacity$ = function(c)
{
  // does this help or hurt performance? seems like js runtime
  // woudl already be good at expanding native Array object...

  if (c < this.m_size) throw fan.sys.ArgErr.make("capacity < size");
  this.m_buf.length = c;
}

fan.sys.MemBuf.prototype.trim = function()
{
  if (this.m_size == this.m_buf.length) return this;
  this.m_buf = this.m_buf.slice(0, size);
  return this;
}

fan.sys.MemBuf.prototype.toHex = function()
{
  var buf = this.m_buf;
  var size = this.m_size;
  var hexChars = fan.sys.Buf.hexChars;
  var s = '';
  for (var i=0; i<size; ++i)
  {
    var b = buf[i] & 0xff;
    s += String.fromCharCode(hexChars[b>>4])
    s += String.fromCharCode(hexChars[b&0xf]);
  }
  return s;
}

fan.sys.MemBuf.prototype.toBase64 = function()
{
  return this.$doBase64(fan.sys.Buf.base64chars, true);
}

fan.sys.MemBuf.prototype.toBase64Uri = function()
{
  return this.$doBase64(fan.sys.Buf.base64UriChars, false);
}

fan.sys.MemBuf.prototype.$doBase64 = function(table, pad)
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

fan.sys.MemBuf.prototype.toDigest = function(algorithm)
{
  var digest = null;
  switch (algorithm)
  {
    case "MD5":
      digest = fan.sys.Buf_Md5(this.m_buf);  break;
    case "SHA1":
    case "SHA-1":
      // fall-through
      digest = fan.sys.buf_sha1.digest(this.m_buf); break;
    case "SHA-256":
      digest = fan.sys.buf_sha256.digest(this.m_buf); break;
    default: throw fan.sys.ArgErr.make("Unknown digest algorithm " + algorithm);
  }
  return fan.sys.MemBuf.makeBytes(digest);
}

fan.sys.MemBuf.prototype.hmac = function(algorithm, keyBuf)
{
  var digest = null;
  switch (algorithm)
  {
    case "MD5":
      digest = fan.sys.Buf_Md5(this.m_buf, keyBuf.m_buf);  break;
    case "SHA1":
    case "SHA-1":
      // fall thru
      digest = fan.sys.buf_sha1.digest(this.m_buf, keyBuf.m_buf); break;
    case "SHA-256":
      digest = fan.sys.buf_sha256.digest(this.m_buf, keyBuf.m_buf); break;
    default: throw fan.sys.ArgErr.make("Unknown digest algorithm " + algorithm);
  }
  return fan.sys.MemBuf.makeBytes(digest);
}

//////////////////////////////////////////////////////////////////////////
// Internal Support
//////////////////////////////////////////////////////////////////////////

fan.sys.MemBuf.prototype.grow = function(capacity)
{
  if (this.m_buf.length >= capacity) return;
  this.capacity$(Math.max(capacity, this.m_size*2));
}

fan.sys.MemBuf.prototype.unsafeArray = function()
{
  return this.m_buf;
}

fan.sys.MemBuf.$emptyBytes = [];
