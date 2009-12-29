//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   3 Dec 09  Andy Frank  Creation
//

/**
 * LogLevel.
 */
fan.sys.LogLevel = fan.sys.Obj.$extend(fan.sys.Enum);

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

fan.sys.LogLevel.prototype.$ctor = function(ordinal, name)
{
  this.make$(ordinal, name);
}

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

fan.sys.LogLevel.prototype.type = function()
{
  return fan.sys.LogLevel.$type;
}

//////////////////////////////////////////////////////////////////////////
// Static
//////////////////////////////////////////////////////////////////////////

fan.sys.LogLevel.m_debug  = new fan.sys.LogLevel(0,  "debug");
fan.sys.LogLevel.m_info   = new fan.sys.LogLevel(1,  "info");
fan.sys.LogLevel.m_warn   = new fan.sys.LogLevel(2,  "warn");
fan.sys.LogLevel.m_err    = new fan.sys.LogLevel(3,  "err");
fan.sys.LogLevel.m_silent = new fan.sys.LogLevel(4,  "silent");

fan.sys.LogLevel.m_vals =
[
  fan.sys.LogLevel.m_debug,
  fan.sys.LogLevel.m_info,
  fan.sys.LogLevel.m_warn,
  fan.sys.LogLevel.m_err,
  fan.sys.LogLevel.m_silent
];