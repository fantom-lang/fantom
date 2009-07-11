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
fan.sys.Uri = fan.sys.Obj.$extend(fan.sys.Obj);

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

fan.sys.Uri.prototype.$ctor = function(uri)
{
  this.m_uri = uri;
}

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

fan.sys.Uri.prototype.type = function()
{
  return fan.sys.Type.find("sys::Uri");
}

fan.sys.Uri.prototype.equals = function(that)
{
  return this.m_uri == that.m_uri;
}

fan.sys.Uri.prototype.toCode = function()
{
  return '`' + this.m_str + '`';
}

fan.sys.Uri.prototype.toStr = function()
{
  return this.m_uri;
}

// TODO - TEMP FIX FOR GFX::IMAGE
fan.sys.Uri.prototype.get = function()
{
  return fan.sys.File.make();
}

//////////////////////////////////////////////////////////////////////////
// Static Methods
//////////////////////////////////////////////////////////////////////////

fan.sys.Uri.make = function(uri)
{
  return new fan.sys.Uri(uri);
}

fan.sys.Uri.fromStr = function(s)
{
  return new fan.sys.Uri(s);
}