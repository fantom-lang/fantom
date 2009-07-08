//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 Mar 09  Andy Frank  Creation
//   20 May 09  Andy Frank  Refactor to new OO model
//

/**
 * Namespace.
 */
var sys_Namespace = sys_Obj.$extend(sys_Obj);
sys_Namespace.prototype.$ctor = function() {}
sys_Namespace.prototype.type = function() { return sys_Type.find("sys::Namespace"); }

