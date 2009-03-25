//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 Mar 09  Andy Frank  Creation
//

/**
 * Thread.
 */
var sys_Thread = sys_Obj.extend(
{
  $ctor: function() {},
  type: function() { return sys_Type.find("sys::Thread"); },
});