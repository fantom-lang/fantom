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

fan.sys.SysInStream.prototype.read = function()
{
  var n = this.r();
  return n < 0 ? null : n;
}
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

/*************************************************************************
 * LocalFileInStream
 ************************************************************************/

fan.sys.LocalFileInStream = fan.sys.Obj.$extend(fan.sys.SysInStream);
fan.sys.LocalFileInStream.prototype.$typeof = function() { return fan.sys.LocalFileInStream.$type; }
fan.sys.LocalFileInStream.prototype.$ctor = function(fd, bufSize)
{
  fan.sys.SysInStream.prototype.$ctor.call(this);
  this.fd = fd;
  this.pre = [];
  this.buf = Buffer.alloc(bufSize);
  this.start = 0;
  this.end = 0;
  this._load();
}

fan.sys.LocalFileInStream.prototype._load = function()
{
  this.start = 0;
  this.end = fs.readSync(this.fd, this.buf);
}

fan.sys.LocalFileInStream.prototype.avail = function()
{
  return this.pre.length + (this.end - this.start);
}

fan.sys.LocalFileInStream.prototype.r = function()
{
  try
  {
    if (this.avail() === 0)
      this._load();
    else if (this.pre.length > 0)
      return this.pre.pop();

    if (this.avail() == 0)
    {
      return -1;
    }
    var x = this.buf[this.start++];
    return x
  }
  catch (e)
  {
    throw fan.sys.IOErr.make(e);
  }
}

fan.sys.LocalFileInStream.prototype.readBuf = function(buf, n)
{
  var out = buf.out();
  var read = 0;
  var r;
  while (n > 0)
  {
    r = this.read();
    if (r === null) break;
    out.write(r);
    n--;
    read++;
  }
  return read == 0 ? null : read;
}

fan.sys.LocalFileInStream.prototype.unread = function(n)
{
  this.pre.push(n);
}

fan.sys.LocalFileInStream.prototype.skip = function(n)
{
  var skipped = 0;

  if (this.pre.length > 0)
  {
    var len = Math.min(this.pre.length, n);
    this.pre = this.pre.slice(0, -len);
    n -= len;
    skipped += len;
  }

  if (this.avail() === 0)
    this._load();
  while (this.avail() > n)
  {
    this.n -= this.avail();
    this.skipped += this.avail();
    this._load();
  }

  n = Math.min(this.avail(), n);

  start += n;
  skipped += n;

  return skipped;
}

fan.sys.LocalFileInStream.prototype.close = function()
{
  try
  {
    fs.closeSync(fd);
    return true;
  }
  catch (e)
  {
    return false;
  }
}