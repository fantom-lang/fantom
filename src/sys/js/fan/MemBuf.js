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

//////////////////////////////////////////////////////////////////////////
// File
//////////////////////////////////////////////////////////////////////////

fan.sys.MemBuf.prototype.toFile = function(uri)
{
  return fan.sys.MemFile.make(this.toImmutable(), uri);
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
