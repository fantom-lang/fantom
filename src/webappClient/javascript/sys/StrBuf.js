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
var sys_StrBuf = sys_Obj.$extend(sys_Obj);

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

sys_StrBuf.prototype.$ctor = function()
{
  this.m_str = "";
}

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

sys_StrBuf.prototype.type = function()
{
  return sys_Type.find("sys::StrBuf");
}

sys_StrBuf.prototype.add = function(obj)
{
  this.m_str += obj==null ? "null" : sys_Obj._toStr(obj);
  return this;
}

sys_StrBuf.prototype.addChar = function(ch)
{
  this.m_str += ch;
  return this;
}

sys_StrBuf.prototype.isEmpty = function()
{
  return this.m_str == 0;
}

sys_StrBuf.prototype.toStr = function()
{
  return this.m_str;
}

//////////////////////////////////////////////////////////////////////////
// Static Methods
//////////////////////////////////////////////////////////////////////////

sys_StrBuf.make = function() { return new sys_StrBuf(); }

