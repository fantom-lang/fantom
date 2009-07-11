//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   11 May 09  Andy Frank  Creation
//   20 May 09  Andy Frank  Refactor to new OO model
//

/**
 * StrInStream
 */
fan.sys.StrInStream = fan.sys.Obj.$extend(fan.sys.InStream);

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

fan.sys.StrInStream.prototype.$ctor = function(str)
{
  this.str  = str;
  this.size = str.length;
  this.pos  = 0;
  this.pushback = null;
}

//////////////////////////////////////////////////////////////////////////
// InStream
//////////////////////////////////////////////////////////////////////////

fan.sys.StrInStream.prototype.read = function()
{
  var b = this.readChar();
  return (b < 0) ? null : (b & 0xff);
}

fan.sys.StrInStream.prototype.readBuf = function(buf, n)
{
  var nval = n;
  for (var i=0; i<nval; ++i)
  {
    var c = this.readChar();
    if (c < 0) return i;
    buf.out.w(c);
  }
  return n;
}

fan.sys.StrInStream.prototype.unread = function(c)
{
  return unreadChar(c);
}

fan.sys.StrInStream.prototype.readChar = function()
{
  if (this.pushback != null && this.pushback.length > 0)
    return this.pushback.pop();
  if (this.pos >= this.size) return null;
  return this.str.charCodeAt(this.pos++);
}

fan.sys.StrInStream.prototype.unreadChar = function(c)
{
  if (this.pushback == null) this.pushback = [];
  this.pushback.push(c);
  return this;
}

fan.sys.StrInStream.prototype.close = function()
{
  return true;
}

