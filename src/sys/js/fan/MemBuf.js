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

//////////////////////////////////////////////////////////////////////////
// Obj
//////////////////////////////////////////////////////////////////////////

fan.sys.MemBuf.prototype.type = function() { return fan.sys.Type.find("sys::MemBuf"); }

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

//////////////////////////////////////////////////////////////////////////
// MemBufOutStream
//////////////////////////////////////////////////////////////////////////

fan.sys.MemBufOutStream = fan.sys.Obj.$extend(fan.sys.OutStream);
fan.sys.MemBufOutStream.prototype.$ctor = function(buf) { this.buf = buf; }

fan.sys.MemBufOutStream.prototype.write = function(v)
{
  return this.w(v);
}

fan.sys.MemBufOutStream.prototype.w = function(v)
{
  this.buf.m_buf[this.buf.m_pos++] =  (0xff & v);
  if (this.buf.m_pos > this.buf.m_size) this.buf.m_size = this.buf.m_pos;
  return this;
}

/*
fan.sys.MemBufOutStream.prototype.writeBuf = function(other, n)
{
  int len = (int)n;
  grow(pos+len);
  other.pipeTo(buf, pos, len);
  pos += len;
  if (pos > size) size = pos;
  return this;
}
*/

//////////////////////////////////////////////////////////////////////////
// MemBufInStream
//////////////////////////////////////////////////////////////////////////

fan.sys.MemBufInStream = fan.sys.Obj.$extend(fan.sys.InStream);
fan.sys.MemBufInStream.prototype.$ctor = function(buf) { this.buf = buf; }

fan.sys.MemBufInStream.prototype.read = function() { var n = this.r(); return n<0 ? null : n; }
fan.sys.MemBufInStream.prototype.r = function()
{
  if (this.buf.m_pos >= this.buf.m_size) return -1;
  return this.buf.m_buf[this.buf.m_pos++] & 0xff;
}

fan.sys.MemBufInStream.prototype.readChar = function() { var c = this.rChar(); return c<0 ? null : c; }
fan.sys.MemBufInStream.prototype.rChar = function() { return this.r(); }

/*
fan.sys.MemBufOutStream.prototype.readBuf(Buf other, long n)
{
  if (pos >= size) return null;
  int len = Math.min(size-pos, (int)n);
  other.pipeFrom(buf, pos, len);
  pos += len;
  return Long.valueOf(len);
}

fan.sys.MemBufOutStream.prototype.unread(long n) { return unread((int)n); }
fan.sys.MemBufOutStream.prototype.unread(int n)
{
  // unreading a buffer is a bit weird - the typical case
  // is that we are pushing back the byte we just read in
  // which case we can just rewind the position; however
  // if we pushing back a different byte then we need
  // to shift the entire buffer and insert the byte
  if (pos > 0 && buf[pos-1] == (byte)n)
  {
    pos--;
  }
  else
  {
    if (size+1 >= buf.length) grow(size+1);
    System.arraycopy(buf, pos, buf, pos+1, size);
    buf[pos] = (byte)n;
    size++;
  }
  return this;
}

fan.sys.MemBufOutStream.prototype.peek()
{
  if (pos >= size) return null;
  return FanInt.pos[buf[pos] & 0xFF];
}

fan.sys.MemBufOutStream.prototype.skip(long n)
{
  int oldPos = pos;
  pos += n;
  if (pos < size) return n;
  pos = size;
  return pos-oldPos;
}
*/