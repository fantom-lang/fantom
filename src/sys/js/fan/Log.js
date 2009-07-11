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
fan.sys.Log = fan.sys.Obj.$extend(fan.sys.Obj);

fan.sys.Log.prototype.$ctor = function() {}
fan.sys.Log.prototype.type = function() { return fan.sys.Type.find("sys::Log"); }

fan.sys.Log.prototype.error = function(msg, err) { this.log(msg, err); }
fan.sys.Log.prototype.info = function(msg, err) { this.log(msg, err); }
fan.sys.Log.prototype.warn = function(msg, err) { this.log(msg, err); }

fan.sys.Log.prototype.log = function(msg, err)
{
  try
  {
    console.log(msg);
  }
  catch (err) {}  // no console support
}

fan.sys.Log.make = function(name, register)
{
  var log = new fan.sys.Log();
  log.name = name;
  log.register = register;
  return log;
}

fan.sys.Log.get = function(name)
{
  var log = fan.sys.Log.$cache[name];
  if (log == null)
  {
    log = fan.sys.Log.make(name, true);
    fan.sys.Log.$cache[name] = log;
  }
  return log;
}

fan.sys.Log.$cache = [];

/*************************************************************************
 * LogLevel
 ************************************************************************/

fan.sys.LogLevel = fan.sys.Obj.$extend(fan.sys.Enum);

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

fan.sys.LogLevel.prototype.$ctor = function(ordinal, name)
{
  this.make$(ordinal, name);
}

fan.sys.LogLevel.prototype.type = function()
{
  return fan.sys.Type.find("sys::LogLevel");
}

//////////////////////////////////////////////////////////////////////////
// Range
//////////////////////////////////////////////////////////////////////////

fan.sys.LogLevel.debug  = new fan.sys.LogLevel(0, "debug");
fan.sys.LogLevel.info   = new fan.sys.LogLevel(1, "info");
fan.sys.LogLevel.warn   = new fan.sys.LogLevel(2, "warn");
fan.sys.LogLevel.error  = new fan.sys.LogLevel(3, "error");
fan.sys.LogLevel.silent = new fan.sys.LogLevel(4, "silent");

fan.sys.LogLevel.values =
[
  fan.sys.LogLevel.debug,
  fan.sys.LogLevel.info,
  fan.sys.LogLevel.warn,
  fan.sys.LogLevel.error,
  fan.sys.LogLevel.silent
]

/*************************************************************************
 * LogRecord
 ************************************************************************/

fan.sys.LogRecord = fan.sys.Obj.$extend(fan.sys.Obj);

fan.sys.LogRecord.prototype.$ctor = function() {}
fan.sys.LogRecord.prototype.type = function() { return fan.sys.Type.find("sys::LogRecord"); }

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

fan.sys.LogRecord.make = function(time, level, logName, msg, err)
{
  if (err == undefined) err = null;
  var self = new fan.sys.LogRecord();
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

fan.sys.LogRecord.prototype.toStr = function()
{
  var ts = "todo"; //((DateTime)time).toLocale("hh:mm:ss DD-MMM-YY");
  return '[' + ts + '] [' + this.m_level + '] [' + this.m_logName + '] ' + this.m_message;
}

fan.sys.LogRecord.prototype.print = function(out)
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

