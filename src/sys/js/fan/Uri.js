//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 Mar 09  Andy Frank  Creation
//   20 May 09  Andy Frank  Refactor to new OO model
//

/**
 * Uri
 */
var sys_Uri = sys_Obj.$extend(sys_Obj);

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

sys_Uri.prototype.$ctor = function(uri)
{
  this.m_uri = uri;
}

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

sys_Uri.prototype.type = function()
{
  return sys_Type.find("sys::Uri");
}

sys_Uri.prototype.equals = function(that)
{
  return this.m_uri == that.m_uri;
}

sys_Uri.prototype.toCode = function()
{
  return '`' + this.m_str + '`';
}

sys_Uri.prototype.toStr = function()
{
  return this.m_uri;
}

// TODO - TEMP FIX FOR GFX::IMAGE
sys_Uri.prototype.get = function()
{
  return sys_File.make();
}

//////////////////////////////////////////////////////////////////////////
// Static Methods
//////////////////////////////////////////////////////////////////////////

sys_Uri.make = function(uri)
{
  return new sys_Uri(uri);
}

sys_Uri.fromStr = function(s)
{
  return new sys_Uri(s);
}