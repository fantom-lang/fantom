//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   29 Dec 08  Andy Frank  Creation
//   20 May 09  Andy Frank  Refactor to new OO model
//

/**
 * StrBuf
 */
fan.sys.StrBuf = fan.sys.Obj.$extend(fan.sys.Obj);

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

fan.sys.StrBuf.prototype.$ctor = function()
{
  this.m_str = "";
}

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

fan.sys.StrBuf.prototype.$typeof = function()
{
  return fan.sys.StrBuf.$type;
}

fan.sys.StrBuf.prototype.add = function(obj)
{
  this.m_str += obj==null ? "null" : fan.sys.ObjUtil.toStr(obj);
  return this;
}

fan.sys.StrBuf.prototype.addChar = function(ch)
{
  this.m_str += String.fromCharCode(ch);
  return this;
}

fan.sys.StrBuf.prototype.capacity = function()
{
  if (this.m_capacity == null) return this.m_str.length;
  return this.m_capacity;
}
fan.sys.StrBuf.prototype.capacity$ = function(c) { this.m_capacity = c; }
fan.sys.StrBuf.prototype.m_capacity = null;

fan.sys.StrBuf.prototype.clear = function()
{
  this.m_str = "";
  return this;
}

fan.sys.StrBuf.prototype.get = function(i)
{
  if (i < 0) i = this.m_str.length+i;
  if (i < 0 || i >= this.m_str.length) throw fan.sys.IndexErr.make(i);
  return this.m_str.charCodeAt(i);
}

fan.sys.StrBuf.prototype.set = function(i, ch)
{
  if (i < 0) i = this.m_str.length+i;
  if (i < 0 || i >= this.m_str.length) throw fan.sys.IndexErr.make(i);
  this.m_str = this.m_str.substr(0,i) + String.fromCharCode(ch) + this.m_str.substr(i+1);
  return this;
}

fan.sys.StrBuf.prototype.join = function(x, sep)
{
  if (sep === undefined) sep = " ";
  var s = (x == null) ? "null" : fan.sys.ObjUtil.toStr(x);
  if (this.m_str.length > 0) this.m_str += sep;
  this.m_str += s;
  return this;
}

fan.sys.StrBuf.prototype.insert = function(i, x)
{
  var s = (x == null) ? "null" : fan.sys.ObjUtil.toStr(x);
  if (i < 0) i = this.m_str.length+i;
  if (i < 0 || i > this.m_str.length) throw fan.sys.IndexErr.make(i);
  this.m_str = this.m_str.substr(0,i) + s + this.m_str.substr(i);
  return this;
}

fan.sys.StrBuf.prototype.remove = function(i)
{
  if (i < 0) i = this.m_str.length+i;
  if (i< 0 || i >= this.m_str.length) throw fan.sys.IndexErr.make(i);
  this.m_str = this.m_str.substr(0,i) + this.m_str.substr(i+1);
  return this;
}

fan.sys.StrBuf.prototype.removeRange = function(r)
{
  var s = r.$start(this.m_str.length);
  var e = r.$end(this.m_str.length);
  var n = e - s + 1;
  if (s < 0 || n < 0) throw fan.sys.IndexErr.make(r);
  this.m_str = this.m_str.substr(0,s) + this.m_str.substr(e+1);
  return this;
}

fan.sys.StrBuf.prototype.isEmpty = function()
{
  return this.m_str.length == 0;
}

fan.sys.StrBuf.prototype.size = function()
{
  return this.m_str.length;
}

fan.sys.StrBuf.prototype.toStr = function()
{
  return this.m_str;
}

fan.sys.StrBuf.prototype.out = function()
{
  return new fan.sys.StrBufOutStream(this);
}

//////////////////////////////////////////////////////////////////////////
// Static Methods
//////////////////////////////////////////////////////////////////////////

fan.sys.StrBuf.make = function() { return new fan.sys.StrBuf(); }

/*************************************************************************
 * StrBufOutStream
 ************************************************************************/

fan.sys.StrBufOutStream = fan.sys.Obj.$extend(fan.sys.OutStream);
fan.sys.StrBufOutStream.prototype.$ctor = function(buf)
{
  this.m_buf = buf;
}

fan.sys.StrBufOutStream.prototype.w = function(v)
{
  throw fan.sys.UnsupportedErr.make("binary write on StrBuf output");
}

fan.sys.StrBufOutStream.prototype.write = function(x)
{
  throw fan.sys.UnsupportedErr.make("binary write on StrBuf output");
}

fan.sys.StrBufOutStream.prototype.writeBuf = function(buf, n)
{
  throw fan.sys.UnsupportedErr.make("binary write on StrBuf output");
}

fan.sys.StrBufOutStream.prototype.writeI2 = function(x)
{
  throw fan.sys.UnsupportedErr.make("binary write on StrBuf output");
}

fan.sys.StrBufOutStream.prototype.writeI4 = function(x)
{
  throw fan.sys.UnsupportedErr.make("binary write on StrBuf output");
}

fan.sys.StrBufOutStream.prototype.writeI8 = function(x)
{
  throw fan.sys.UnsupportedErr.make("binary write on StrBuf output");
}

fan.sys.StrBufOutStream.prototype.writeF4 = function(x)
{
  throw fan.sys.UnsupportedErr.make("binary write on StrBuf output");
}

fan.sys.StrBufOutStream.prototype.writeF8 = function(x)
{
  throw fan.sys.UnsupportedErr.make("binary write on StrBuf output");
}

fan.sys.StrBufOutStream.prototype.writeUtf = function(x)
{
  throw fan.sys.UnsupportedErr.make("modified UTF-8 format write on StrBuf output");
}

fan.sys.StrBufOutStream.prototype.writeChar = function(c)
{
  this.m_buf.m_str += String.fromCharCode(c);
  return this;
}

fan.sys.StrBufOutStream.prototype.writeChars = function(s, off, len)
{
  if (off === undefined) off = 0;
  if (len === undefined) len = s.length-off;
  this.m_buf.m_str += s.substr(off, len);
  return this;
}

fan.sys.StrBufOutStream.prototype.flush = function() { return this; }
fan.sys.StrBufOutStream.prototype.close = function() { return true; }

