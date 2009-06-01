//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 Mar 09  Andy Frank  Creation
//   20 May 09  Andy Frank  Refactor to new OO model
//

/**
 * Log.
 */
var sys_Log = sys_Obj.$extend(sys_Obj);

sys_Log.prototype.$ctor = function() {}
sys_Log.prototype.type = function() { return sys_Type.find("sys::Log"); }

sys_Log.prototype.error = function(msg, err) { this.log(msg, err); }
sys_Log.prototype.info = function(msg, err) { this.log(msg, err); }
sys_Log.prototype.warn = function(msg, err) { this.log(msg, err); }

sys_Log.prototype.log = function(msg, err)
{
  try
  {
    console.log(msg);
  }
  catch (err) {}  // no console support
}

sys_Log.make = function(name, register)
{
  var log = new sys_Log();
  log.name = name;
  log.register = register;
  return log;
}

sys_Log.get = function(name)
{
  var log = sys_Log.$cache[name];
  if (log == null)
  {
    log = sys_Log.make(name, true);
    sys_Log.$cache[name] = log;
  }
  return log;
}

sys_Log.$cache = [];

/*************************************************************************
 * LogLevel
 ************************************************************************/

var sys_LogLevel = sys_Obj.$extend(sys_Enum);

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

sys_LogLevel.prototype.$ctor = function(ordinal, name)
{
  this.$make(ordinal, name);
}

sys_LogLevel.prototype.type = function()
{
  return sys_Type.find("sys::LogLevel");
}

//////////////////////////////////////////////////////////////////////////
// Range
//////////////////////////////////////////////////////////////////////////

sys_LogLevel.debug  = new sys_LogLevel(0, "debug");
sys_LogLevel.info   = new sys_LogLevel(1, "info");
sys_LogLevel.warn   = new sys_LogLevel(2, "warn");
sys_LogLevel.error  = new sys_LogLevel(3, "error");
sys_LogLevel.silent = new sys_LogLevel(4, "silent");

sys_LogLevel.values =
[
  sys_LogLevel.debug,
  sys_LogLevel.info,
  sys_LogLevel.warn,
  sys_LogLevel.error,
  sys_LogLevel.silent
]

/*************************************************************************
 * LogRecord
 ************************************************************************/

var sys_LogRecord = sys_Obj.$extend(sys_Obj);

sys_LogRecord.prototype.$ctor = function() {}
sys_LogRecord.prototype.type = function() { return sys_Type.find("sys::LogRecord"); }

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

sys_LogRecord.make = function(time, level, logName, msg, err)
{
  if (err == undefined) err = null;
  var self = new sys_LogRecord();
  self.m_time    = time;
  self.m_level   = level;
  self.m_logName = logName;
  self.m_message = msg;
  self.m_err     = err;
  return self;
}

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

sys_LogRecord.prototype.toStr = function()
{
  var ts = "todo"; //((DateTime)time).toLocale("hh:mm:ss DD-MMM-YY");
  return '[' + ts + '] [' + this.m_level + '] [' + this.m_logName + '] ' + this.m_message;
}

sys_LogRecord.prototype.print = function(out)
{
  // TODO
  //if (out == undefined) out = ???
  //out.printLine(toStr());
  //if (err != null) err.trace(out, 2, true);
  try
  {
    console.log(this.toStr());
    if (err != null) err.trace(); // echo routes to console too
  }
  catch (err) {}  // no console support}
}

