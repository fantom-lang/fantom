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
fan.sys.Actor = fan.sys.Obj.$extend(fan.sys.Obj);
fan.sys.Actor.prototype.$ctor = function() {}
fan.sys.Actor.prototype.type = function() { return fan.sys.Actor.$type; }

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

fan.sys.Actor.locals = function()
{
  if (fan.sys.Actor.$locals == null)
  {
    var k = fan.sys.Str.$type;
    var v = fan.sys.Obj.$type.toNullable();
    fan.sys.Actor.$locals = fan.sys.Map.make(k, v);
  }
  return fan.sys.Actor.$locals;
}
fan.sys.Actor.$locals = null;

