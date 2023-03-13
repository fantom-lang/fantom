//
// Copyright (c) 2017, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Nov 17  Andy Frank  Creation
//

/**
 * ConstBuf.
 */
fan.sys.ConstBuf = fan.sys.Obj.$extend(fan.sys.Buf);

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

fan.sys.ConstBuf.prototype.$ctor = function(buf, size, endian, charset)
{
  this.m_buf     = buf;
  this.m_pos     = 0;
  this.m_size    = size;
  this.m_in      = fan.sys.ConstBuf.errInStream;
  this.m_out     = fan.sys.ConstBuf.errOutStream;
  this.m_endian  = endian;
  this.m_charset = charset;
}

//////////////////////////////////////////////////////////////////////////
// Obj
//////////////////////////////////////////////////////////////////////////

fan.sys.ConstBuf.prototype.$typeof = function() { return fan.sys.ConstBuf.$type; }

fan.sys.ConstBuf.prototype.isImmutable = function() { return true; }

fan.sys.ConstBuf.prototype.toImmutable= function() { return this; }

//////////////////////////////////////////////////////////////////////////
// Buf Support
//////////////////////////////////////////////////////////////////////////

fan.sys.ConstBuf.prototype.$in = function()
{
  return new fan.sys.ConstBufInStream(this);
}

fan.sys.ConstBuf.prototype.size = function() { return this.m_size; }
fan.sys.ConstBuf.prototype.size$ = function(x) { throw this.err(); }

fan.sys.ConstBuf.prototype.pos = function() { return 0; }
fan.sys.ConstBuf.prototype.pos$ = function(x) { throw this.err(); }

fan.sys.ConstBuf.prototype.getByte = function(pos)
{
  return this.m_buf[pos] & 0xFF;
}

fan.sys.ConstBuf.prototype.setByte = function(pos, x) { throw this.err() }

fan.sys.ConstBuf.prototype.getBytes = function(pos, len)
{
  return this.m_buf.slice(pos, pos+len);
}

// public final void pipeTo(byte[] dst, int dstPos, int len)
// {
//   if (len > size) throw IOErr.make("Not enough bytes to write");
//   System.arraycopy(buf, 0, dst, dstPos, len);
// }
//
// public final void pipeTo(OutputStream dst, long lenLong)
//   throws IOException
// {
//   int len = (int)lenLong;
//   if (len > size) throw IOErr.make("Not enough bytes to write");
//   dst.write(buf, 0, len);
// }
//
// public final void pipeTo(RandomAccessFile dst, long lenLong)
//   throws IOException
// {
//   int len = (int)lenLong;
//   if (len > size) throw IOErr.make("Not enough bytes to write");
//   dst.write(buf, 0, len);
// }
//
// public final void pipeTo(ByteBuffer dst, int len)
// {
//   if (len > size) throw IOErr.make("Not enough bytes to write");
//   dst.put(buf, 0, len);
// }

fan.sys.ConstBuf.prototype.pipeFrom = function() { throw this.err(); }
// fan.sys.ConstBuf.prototype.pipeFrom = function(src, srcPos, len)
// fan.sys.ConstBuf.prototype.pipeFrom = function(InputStream src, long lenLong)
// fan.sys.ConstBuf.prototype.pipeFrom = function(RandomAccessFile src, long lenLong)
// fan.sys.ConstBuf.prototype.pipeFrom = function(ByteBuffer src, int len)

//////////////////////////////////////////////////////////////////////////
// Buf API
//////////////////////////////////////////////////////////////////////////

fan.sys.ConstBuf.prototype.capacity = function() { throw this.err(); }
fan.sys.ConstBuf.prototype.capacity$ = function(c) { throw this.err(); }

fan.sys.ConstBuf.prototype.sync = function() { throw this.err(); }

fan.sys.ConstBuf.prototype.trim = function() { throw this.err(); }

fan.sys.ConstBuf.prototype.endian = function() { return this.m_endian; }
fan.sys.ConstBuf.prototype.endian$ = function(endian) { throw this.err(); }

fan.sys.ConstBuf.prototype.charset = function() { return this.m_charset; }
fan.sys.ConstBuf.prototype.charset$ = function(charset) { throw this.err(); }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

fan.sys.ConstBuf.prototype.unsafeArray = function()
{
  return this.m_buf;
}

fan.sys.ConstBuf.prototype.err = function()
{
  return fan.sys.ReadonlyErr.make("Buf is immutable");
}