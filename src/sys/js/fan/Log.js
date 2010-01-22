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
fan.sys.Log.prototype.$typeof = function() { return fan.sys.Log.$type; }

fan.sys.Log.prototype.err  = function(msg, err) { this.log(msg, err); }
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

fan.sys.LogLevel.prototype.$typeof = function()
{
  return fan.sys.LogLevel.$type;
}

//////////////////////////////////////////////////////////////////////////
// Range
//////////////////////////////////////////////////////////////////////////

fan.sys.LogLevel.m_debug  = new fan.sys.LogLevel(0, "debug");
fan.sys.LogLevel.m_info   = new fan.sys.LogLevel(1, "info");
fan.sys.LogLevel.m_warn   = new fan.sys.LogLevel(2, "warn");
fan.sys.LogLevel.m_err    = new fan.sys.LogLevel(3, "err");
fan.sys.LogLevel.m_silent = new fan.sys.LogLevel(4, "silent");

fan.sys.LogLevel.m_vals =
[
  fan.sys.LogLevel.m_debug,
  fan.sys.LogLevel.m_info,
  fan.sys.LogLevel.m_warn,
  fan.sys.LogLevel.m_err,
  fan.sys.LogLevel.m_silent
]

/*************************************************************************
 * LogRec
 ************************************************************************/

fan.sys.LogRec = fan.sys.Obj.$extend(fan.sys.Obj);

fan.sys.LogRec.prototype.$ctor = function() {}
fan.sys.LogRec.prototype.$typeof = function() { return fan.sys.LogRec.$type; }

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

fan.sys.LogRec.make = function(time, level, logName, msg, err)
{
  if (err === undefined) err = null;
  var self = new fan.sys.LogRec();
  self.m_time    = time;
  self.m_level   = level;
  self.m_logName = logName;
  self.m_msg     = msg;
  self.m_err     = err;
  return self;
}

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

fan.sys.LogRec.prototype.toStr = function()
{
  var ts = "todo"; //((DateTime)time).toLocale("hh:mm:ss DD-MMM-YY");
  return '[' + ts + '] [' + this.m_level + '] [' + this.m_logName + '] ' + this.m_msg;
}

fan.sys.LogRec.prototype.print = function(out)
{
  // TODO
  //if (out === undefined) out = ???
  //out.printLine(toStr());
  //if (err != null) err.trace(out, 2, true);
  try
  {
    console.log(this.toStr());
    if (err != null) err.trace(); // echo routes to console too
  }
  catch (err) {}  // no console support}
}

