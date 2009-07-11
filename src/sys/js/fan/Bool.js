//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 Dec 08  Andy Frank  Creation
//   20 May 09  Andy Frank  Refactor to new OO model
//

/**
 * Bool
 */
fan.sys.Bool = fan.sys.Obj.$extend(fan.sys.Obj);

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

fan.sys.Bool.prototype.$ctor = function() {}

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

fan.sys.Bool.prototype.type = function()
{
  return fan.sys.Type.find("sys::Bool");
}

//////////////////////////////////////////////////////////////////////////
// Static
//////////////////////////////////////////////////////////////////////////

fan.sys.Bool.fromStr = function(s, checked)
{
  if (s == "true") return true;
  if (s == "false") return false;
  if (checked != null && !checked) return null;
  throw new fan.sys.ParseErr("Bool", s);
}

fan.sys.Bool.toStr  = function(self) { return self ? "true" : "false"; }
fan.sys.Bool.toCode = function(self) { return self ? "true" : "false"; }
fan.sys.Bool.defVal = false;