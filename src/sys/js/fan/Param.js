//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   18 May 09  Andy Frank  Creation
//   20 May 09  Andy Frank  Refactor to new OO model
//

/**
 * Param.
 */
var sys_Param = sys_Obj.$extend(sys_Obj);

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

sys_Param.prototype.$ctor = function(name, of, hasDefault)
{
  this.m_name = name;
  this.m_of = sys_Type.find(of);
  this.m_hasDefault = hasDefault;
}

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

sys_Param.prototype.name = function() { return this.m_name; }
sys_Param.prototype.of = function() { return this.m_of; }
sys_Param.prototype.hasDefault = function() { return this.m_hasDefault; }

sys_Param.prototype.type = function()
{
  return sys_Type.find("sys::Param");
}

