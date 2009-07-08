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
var sys_StrInStream = sys_Obj.$extend(sys_InStream);

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

sys_StrInStream.prototype.$ctor = function(str)
{
  this.str  = str;
  this.size = str.length;
  this.pos  = 0;
  this.pushback = null;
}

//////////////////////////////////////////////////////////////////////////
// InStream
//////////////////////////////////////////////////////////////////////////

sys_StrInStream.prototype.read = function()
{
  var b = this.readChar();
  return (b < 0) ? null : (b & 0xff);
}

sys_StrInStream.prototype.readBuf = function(buf, n)
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

sys_StrInStream.prototype.unread = function(c)
{
  return unreadChar(c);
}

sys_StrInStream.prototype.readChar = function()
{
  if (this.pushback != null && this.pushback.length > 0)
    return this.pushback.pop();
  if (this.pos >= this.size) return null;
  return this.str.charCodeAt(this.pos++);
}

sys_StrInStream.prototype.unreadChar = function(c)
{
  if (this.pushback == null) this.pushback = [];
  this.pushback.push(c);
  return this;
}

sys_StrInStream.prototype.close = function()
{
  return true;
}

