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
var sys_MemBuf = sys_Obj.$extend(sys_Obj); // TODO - fix to extend Buf

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

sys_MemBuf.prototype.$ctor = function()
{
  this.m_buf  = [];
  this.m_out  = new sys_MemBufOutStream(this);
  this.m_in   = new sys_MemBufInStream(this);
  this.m_pos  = 0;
  this.m_size = 0;
}

// TODO
sys_MemBuf.prototype.flip = function()
{
  this.m_size = this.m_pos;
  this.m_pos = 0;
  return this;
}

//////////////////////////////////////////////////////////////////////////
// OutStream
//////////////////////////////////////////////////////////////////////////

sys_MemBuf.prototype.out = function() { return this.m_out; }

//////////////////////////////////////////////////////////////////////////
// OutStream
//////////////////////////////////////////////////////////////////////////

sys_MemBuf.prototype.$in = function() { return this.m_in; }

//////////////////////////////////////////////////////////////////////////
// MemBufOutStream
//////////////////////////////////////////////////////////////////////////

var sys_MemBufOutStream = sys_Obj.$extend(sys_OutStream);
sys_MemBufOutStream.prototype.$ctor = function(buf) { this.buf = buf; }

sys_MemBufOutStream.prototype.write = function(v)
{
  return this.w(v);
}

sys_MemBufOutStream.prototype.w = function(v)
{
  this.buf.m_buf[this.buf.m_pos++] =  (0xff & v);
  if (this.buf.m_pos > this.buf.m_size) this.buf.m_size = this.buf.m_pos;
  return this;
}

/*
sys_MemBufOutStream.prototype.writeBuf = function(other, n)
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

var sys_MemBufInStream = sys_Obj.$extend(sys_InStream);
sys_MemBufInStream.prototype.$ctor = function(buf) { this.buf = buf; }

sys_MemBufInStream.prototype.read = function() { var n = this.r(); return n<0 ? null : n; }
sys_MemBufInStream.prototype.r = function()
{
  if (this.buf.m_pos >= this.buf.m_size) return -1;
  return this.buf.m_buf[this.buf.m_pos++] & 0xff;
}

sys_MemBufInStream.prototype.readChar = function() { var c = this.rChar(); return c<0 ? null : c; }
sys_MemBufInStream.prototype.rChar = function() { return this.r(); }

/*
sys_MemBufOutStream.prototype.readBuf(Buf other, long n)
{
  if (pos >= size) return null;
  int len = Math.min(size-pos, (int)n);
  other.pipeFrom(buf, pos, len);
  pos += len;
  return Long.valueOf(len);
}

sys_MemBufOutStream.prototype.unread(long n) { return unread((int)n); }
sys_MemBufOutStream.prototype.unread(int n)
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

sys_MemBufOutStream.prototype.peek()
{
  if (pos >= size) return null;
  return FanInt.pos[buf[pos] & 0xFF];
}

sys_MemBufOutStream.prototype.skip(long n)
{
  int oldPos = pos;
  pos += n;
  if (pos < size) return n;
  pos = size;
  return pos-oldPos;
}
*/