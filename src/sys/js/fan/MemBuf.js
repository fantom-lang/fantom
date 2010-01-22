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
  this.m_buf  = [];
  this.m_pos  = 0;
  this.m_size = 0;
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

fan.sys.MemBuf.prototype.size = function()
{
  return this.m_size;
}

/*
fan.sys.MemBuf.prototype.size(long x)
{
  int newSize = (int)x;
  if (newSize > buf.length)
  {
    byte[] temp = new byte[newSize];
    System.arraycopy(buf, 0, temp, 0, buf.length);
    buf  = temp;
  }
  size = newSize;
}
*/

fan.sys.MemBuf.prototype.pos = function()
{
  return this.m_pos;
}

fan.sys.MemBuf.prototype.pos = function(x)
{
  this.m_pos = x;
}

/*
fan.sys.MemBuf.prototype.getByte = function(pos)
{
  return buf[(int)pos] & 0xFF;
}

final void setByte(long pos, int x)
{
  buf[(int)pos] = (byte)x;
}

final void getBytes(long pos, byte[] dest, int off, int len)
{
  System.arraycopy(this.buf, (int)pos, dest, off, len);
}

final void pipeTo(byte[] dst, int dstPos, int len)
{
  if (pos + len > size) throw IOErr.make("Not enough bytes to write").val;
  System.arraycopy(buf, pos, dst, dstPos, len);
  pos += len;
}

final void pipeTo(OutputStream dst, long lenLong)
  throws IOException
{
  int len = (int)lenLong;
  if (pos + len > size) throw IOErr.make("Not enough bytes to write").val;
  dst.write(buf, pos, len);
  pos += len;
}

final void pipeTo(RandomAccessFile dst, long lenLong)
  throws IOException
{
  int len = (int)lenLong;
  if (pos + len > size) throw IOErr.make("Not enough bytes to write").val;
  dst.write(buf, pos, len);
  pos += len;
}

final void pipeTo(ByteBuffer dst, int len)
{
  if (pos + len > size) throw IOErr.make("Not enough bytes to write").val;
  dst.put(buf, pos, len);
  pos += len;
}

final void pipeFrom(byte[] src, int srcPos, int len)
{
  grow(pos+len);
  System.arraycopy(src, srcPos, buf, pos, len);
  pos += len;
  size = pos;
}

final long pipeFrom(InputStream src, long lenLong)
  throws IOException
{
  int len = (int)lenLong;
  grow(pos+len);
  int read = src.read(buf, pos, len);
  if (read < 0) return -1;
  pos  += read;
  size = pos;
  return read;
}

final long pipeFrom(RandomAccessFile src, long lenLong)
  throws IOException
{
  int len = (int)lenLong;
  grow(pos+len);
  int read = src.read(buf, pos, len);
  if (read < 0) return -1;
  pos += read;
  size = pos;
  return read;
}

final int pipeFrom(ByteBuffer src, int len)
{
  grow(pos+len);
  src.get(buf, pos, len);
  pos += len;
  size = pos;
  return len;
}
*/

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

