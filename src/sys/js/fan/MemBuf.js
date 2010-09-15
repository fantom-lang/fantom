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

//////////////////////////////////////////////////////////////////////////
// Buf Support
//////////////////////////////////////////////////////////////////////////

fan.sys.MemBuf.prototype.size = function() { return this.m_size; }
fan.sys.MemBuf.prototype.size$ = function(x) { this.m_size = x; }

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

fan.sys.MemBuf.prototype.getBytes = function(pos, dest, off, len)
{
  // TODO FIXIT
  //System.arraycopy(this.buf, (int)pos, dest, off, len);
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

/*
fan.sys.MemBuf.prototype.capacity(long c)
{
  int newCapacity = (int)c;
  if (newCapacity < size) throw ArgErr.make("capacity < size").val;
  byte[] temp = new byte[newCapacity];
  System.arraycopy(buf, 0, temp, 0, Math.min(size, newCapacity));
  buf = temp;
}
*/

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
  var buf = this.m_buf;
  var size = this.m_size;
  var s = '';
  var base64chars = fan.sys.Buf.base64chars;
  var i = 0;

  // append full 24-bit chunks
  var end = size-2;
  for (; i<end; i += 3)
  {
    var n = ((buf[i] & 0xff) << 16) + ((buf[i+1] & 0xff) << 8) + (buf[i+2] & 0xff);
    s += String.fromCharCode(base64chars[(n >>> 18) & 0x3f]);
    s += String.fromCharCode(base64chars[(n >>> 12) & 0x3f]);
    s += String.fromCharCode(base64chars[(n >>> 6) & 0x3f]);
    s += String.fromCharCode(base64chars[n & 0x3f]);
  }

  // pad and encode remaining bits
  var rem = size - i;
  if (rem > 0)
  {
    var n = ((buf[i] & 0xff) << 10) | (rem == 2 ? ((buf[size-1] & 0xff) << 2) : 0);
    s += String.fromCharCode(base64chars[(n >>> 12) & 0x3f]);
    s += String.fromCharCode(base64chars[(n >>> 6) & 0x3f]);
    s += rem == 2 ? String.fromCharCode(base64chars[n & 0x3f]) : '=';
    s += '=';
  }

  return s;
}

fan.sys.MemBuf.prototype.toDigest = function(algorithm)
{
  var digest = null;
  switch (algorithm)
  {
    case "MD5":   digest = fan.sys.Buf_Md5(this.m_buf);  break;
    case "SHA1":  // fall thru
    case "SHA-1": digest = fan.sys.Buf_Sha1(this.m_buf); break;
    default: throw fan.sys.Err.make("Unknown digest algorithm " + algorithm);
  }
  return fan.sys.MemBuf.makeBytes(digest);
}

fan.sys.MemBuf.prototype.hmac = function(algorithm, keyBuf)
{
  var digest = null;
  switch (algorithm)
  {
    case "MD5":   digest = fan.sys.Buf_Md5(this.m_buf, keyBuf.m_buf);  break;
    case "SHA1":  // fall thru
    case "SHA-1": digest = fan.sys.Buf_Sha1(this.m_buf, keyBuf.m_buf); break;
    default: throw fan.sys.Err.make("Unknown digest algorithm " + algorithm);
  }
  return fan.sys.MemBuf.makeBytes(digest);
}

