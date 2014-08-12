//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   1 Aug 2013  Andy Frank  Break out from StrBuf to fix dependy order
//

/**
 * StrBufOutStream
 */
fan.sys.StrBufOutStream = fan.sys.Obj.$extend(fan.sys.OutStream);
fan.sys.StrBufOutStream.prototype.$ctor = function(buf)
{
  fan.sys.OutStream.prototype.$ctor.call(this)
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
