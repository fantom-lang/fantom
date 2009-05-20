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
var sys_Bool = sys_Obj.$extend(sys_Obj);

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

sys_Bool.prototype.$ctor = function() {}

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

sys_Bool.prototype.type = function()
{
  return sys_Type.find("sys::Bool");
}

//////////////////////////////////////////////////////////////////////////
// Static
//////////////////////////////////////////////////////////////////////////

sys_Bool.fromStr = function(s, checked)
{
  if (s == "true") return true;
  if (s == "false") return false;
  if (checked != null && !checked) return null;
  throw new sys_ParseErr("Bool", s);
}

sys_Bool.toStr  = function(self) { return self ? "true" : "false"; }
sys_Bool.toCode = function(self) { return self ? "true" : "false"; }
sys_Bool.defVal = false;