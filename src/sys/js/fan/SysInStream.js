//
// Copyright (c) 2010, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   1 Sep 19  Andy Frank  Creation
//

/**
 * SysInStream
 */
fan.sys.SysInStream = fan.sys.Obj.$extend(fan.sys.InStream);

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

fan.sys.SysInStream.make = function(ins, bufSize)
{
  if (bufSize == null || bufSize == 0)
    return new fan.sys.SysInStream(ins);
  else
    return new fan.sys.SysInStream(new java.io.BufferedInputStream(ins, bufSize));
}

fan.sys.SysInStream.prototype.$ctor = function(ins)
{
  fan.sys.InStream.prototype.$ctor.call(this);
  this.m_in = ins;
}

//////////////////////////////////////////////////////////////////////////
// Obj
//////////////////////////////////////////////////////////////////////////

fan.sys.SysInStream.prototype.$typeof = function() { return fan.sys.SysInStream.$type; }

//////////////////////////////////////////////////////////////////////////
// InStream
//////////////////////////////////////////////////////////////////////////

fan.sys.SysInStream.prototype.read = function() { var n = this.r(); return n < 0 ? null : n; }
fan.sys.SysInStream.prototype.r = function()
{
  try
  {
    return this.m_in.read();
  }
  catch (e)
  {
    throw fan.sys.IOErr.make(e);
  }
}

fan.sys.SysInStream.prototype.readChar = function()
{
  var c = this.rChar()
  return (c < 0) ? null : c;
}

fan.sys.SysInStream.prototype.rChar = function()
{
  return this.m_charset.m_encoder.decode(this);
}

fan.sys.SysInStream.prototype.readBuf = function(buf, n)
{
  try
  {
    var read = buf.pipeFrom(this.m_in, n);
    if (read < 0) return null;
    return read;
  }
  catch (e)
  {
    throw fan.sys.IOErr.make(e);
  }
}

fan.sys.SysInStream.prototype.unread = function(n)
{
  try
  {
    // don't take the hit until we know we need to wrap
    // the raw input stream with a pushback stream
    if (!(this.m_in instanceof java.io.PushbackInputStream))
      this.m_in = new java.io.PushbackInputStream(this.m_in, 128);
    this.m_in.unread(n);
    return this;
  }
  catch (e)
  {
    throw fan.sys.IOErr.make(e);
  }
}

fan.sys.SysInStream.prototype.skip = function(n)
{
  try
  {
    var skipped = this.m_in.skip(n);
    if (skipped < 0) return 0;
    return skipped;
  }
  catch (e)
  {
    throw fan.sys.IOErr.make(e);
  }
}

fan.sys.SysInStream.prototype.close = function()
{
  try
  {
    if (this.m_in != null) this.m_in.close();
    return true;
  }
  catch (e)
  {
    return false;
  }
}

