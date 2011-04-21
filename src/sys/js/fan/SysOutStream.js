//
// Copyright (c) 2010, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   1 Sep 19  Andy Frank  Creation
//

/**
 * SysOutStream
 */
fan.sys.SysOutStream = fan.sys.Obj.$extend(fan.sys.OutStream);

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

fan.sys.SysOutStream.make = function(out, bufSize)
{
  return new fan.sys.SysOutStream(fan.sys.SysOutStream.toBuffered(out, bufSize));
}

fan.sys.SysOutStream.toBuffered = function(out, bufSize)
{
  if (bufSize == null || bufSize == 0)
    return out;
  else
    return new java.io.BufferedOutputStream(out, bufSize);
}

fan.sys.SysOutStream.prototype.$ctor = function(out)
{
  fan.sys.OutStream.prototype.$ctor.call(this);
  this.out = out;
}

//////////////////////////////////////////////////////////////////////////
// Obj
//////////////////////////////////////////////////////////////////////////

fan.sys.SysOutStream.prototype.$typeof = function() { return fan.sys.SysOutStream.$type; }

//////////////////////////////////////////////////////////////////////////
// OutStream
//////////////////////////////////////////////////////////////////////////

fan.sys.SysOutStream.prototype.w = function(v)
{
  try
  {
    this.out.write(v);
    return this;
  }
  catch (e)
  {
    throw fan.sys.IOErr.make(e).val;
  }
}

fan.sys.SysOutStream.prototype.writeBuf = function(buf, n)
{
  if (n === undefined) n = buf.remaining();
  try
  {
    buf.pipeTo(this.out, n);
    return this;
  }
  catch (e)
  {
    throw fan.sys.IOErr.make(e);
  }
}

fan.sys.SysOutStream.prototype.writeChar = function(c)
{
  this.m_charset.m_encoder.encodeOut(c, this);
  return this;
}

fan.sys.SysOutStream.prototype.flush = function()
{
  try
  {
    this.out.flush();
    return this;
  }
  catch (e)
  {
    throw fan.sys.IOErr.make(e);
  }
}

fan.sys.SysOutStream.prototype.close = function()
{
  try
  {
    if (this.out != null) this.out.close();
    return true;
  }
  catch (e)
  {
    return false;
  }
}

/*************************************************************************
 * ConsoleOutStream
 ************************************************************************/

fan.sys.ConsoleOutStream = fan.sys.Obj.$extend(fan.sys.OutStream);
fan.sys.ConsoleOutStream.prototype.$ctor = function()
{
  fan.sys.OutStream.prototype.$ctor.call(this);
  this.m_buf = "";
}
fan.sys.ConsoleOutStream.prototype.$typeof = function() { return fan.sys.SysOutStream.$type; }
fan.sys.ConsoleOutStream.prototype.write = function(v)
{
  if (v == 10) this.flush();
  else this.m_buf += String.fromCharCode(v)
}
fan.sys.ConsoleOutStream.prototype.flush = function()
{
  if (this.m_buf.length > 0 && console) console.log(this.m_buf);
  this.m_buf = "";
}

/*************************************************************************
 * LocalFileOutStream
 ************************************************************************/

fan.sys.LocalFileOutStream = fan.sys.Obj.$extend(fan.sys.SysOutStream);
fan.sys.LocalFileOutStream.prototype.$ctor = function(out, fd)
{
  fan.sys.SysOutStream.prototype.$ctor.call(this);
  this.out = out;
  this.fd = fd;
}
fan.sys.LocalFileOutStream.prototype.sync = function()
{
  try
  {
    this.flush();
    this.fd.sync();
    return this;
  }
  catch (e)
  {
    throw fan.sys.IOErr.make(e);
  }
}

