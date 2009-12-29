//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   13 Jun 09  Andy Frank  Creation
//

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