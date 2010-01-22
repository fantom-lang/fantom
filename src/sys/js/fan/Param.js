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
fan.sys.Param = fan.sys.Obj.$extend(fan.sys.Obj);

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

fan.sys.Param.prototype.$ctor = function(name, of, hasDefault)
{
  this.m_name = name;
  this.m_of = fan.sys.Type.find(of);
  this.m_hasDefault = hasDefault;
}

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

fan.sys.Param.prototype.name = function() { return this.m_name; }
fan.sys.Param.prototype.of = function() { return this.m_of; }
fan.sys.Param.prototype.hasDefault = function() { return this.m_hasDefault; }
fan.sys.Param.prototype.$typeof = function() { return fan.sys.Param.$type; }

