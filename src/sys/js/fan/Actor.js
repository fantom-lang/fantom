//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   2 Junc 09  Andy Frank  Creation
//

/**
 * Actor.
 */
var sys_Actor = sys_Obj.$extend(sys_Obj);
sys_Actor.prototype.$ctor = function() {}
sys_Actor.prototype.type = function() { return sys_Type.find("sys::Actor"); }

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

sys_Actor.locals = function()
{
  if (sys_Actor.$locals == null)
  {
    var k = sys_Type.find("sys::Str");
    var v = sys_Type.find("sys::Obj?")
    sys_Actor.$locals = new sys_Map(k, v);
  }
  return sys_Actor.$locals;
}
sys_Actor.$locals = null;

