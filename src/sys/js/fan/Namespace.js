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
fan.sys.Namespace = fan.sys.Obj.$extend(fan.sys.Obj);
fan.sys.Namespace.prototype.$ctor = function() {}
fan.sys.Namespace.prototype.type = function() { return fan.sys.Type.find("sys::Namespace"); }

