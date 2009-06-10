//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Jun 09  Andy Frank  Creation
//

/**
 * OutStream
 */
var sys_OutStream = sys_Obj.$extend(sys_Obj);

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

sys_OutStream.prototype.$ctor = function() { this.out = null; }
sys_OutStream.prototype.$make = function(out) { this.out = out; }

