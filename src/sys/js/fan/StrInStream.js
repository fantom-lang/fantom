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
  var b = this.rChar();
  return (b < 0) ? null : b & 0xFF;
}

fan.sys.StrInStream.prototype.readBuf = function(buf, n)
{
  for (var i=0; i<n; ++i)
  {
    var c = this.rChar();
    if (c < 0) return i == 0 ? null : i;
    buf.out().writeChar(c);
  }
  return n;
}

fan.sys.StrInStream.prototype.unread = function(c)
{
  return this.unreadChar(c);
}

fan.sys.StrInStream.prototype.rChar = function()
{
  if (this.pushback != null && this.pushback.length > 0)
    return this.pushback.pop();
  if (this.pos >= this.size) return -1;
  return this.str.charCodeAt(this.pos++);
}

fan.sys.StrInStream.prototype.readChar = function()
{
  var c = this.rChar();
  return (c < 0) ? null : c;
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

