//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   22 Junc 09  Andy Frank  Creation
//

/**
 * MimeType represents the parsed value of a Content-Type
 * header per RFC 2045 section 5.1.
 */
var sys_MimeType = sys_Obj.$extend(sys_Obj);
sys_MimeType.prototype.$ctor = function() {}
sys_MimeType.prototype.type = function() { return sys_Type.find("sys::MimeType"); }

