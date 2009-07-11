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

fan.sys.StrBuf.prototype.type = function()
{
  return fan.sys.Type.find("sys::StrBuf");
}

fan.sys.StrBuf.prototype.add = function(obj)
{
  this.m_str += obj==null ? "null" : fan.sys.Obj.toStr(obj);
  return this;
}

fan.sys.StrBuf.prototype.addChar = function(ch)
{
  this.m_str += String.fromCharCode(ch);
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

//////////////////////////////////////////////////////////////////////////
// Static Methods
//////////////////////////////////////////////////////////////////////////

fan.sys.StrBuf.make = function() { return new fan.sys.StrBuf(); }

