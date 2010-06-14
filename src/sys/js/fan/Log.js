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

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

fan.sys.Log.prototype.$ctor = function()
{
  this.m_name  = null;
  this.m_level = fan.sys.LogLevel.m_info;
}

fan.sys.Log.list = function()
{
  return fan.sys.List.make(fan.sys.Log.$type, fan.sys.Log.m_byName).ro();
}

fan.sys.Log.find = function(name, checked)
{
  if (checked === undefined) checked = true;
  var log = fan.sys.Log.m_byName[name];
  if (log != null) return log;
  if (checked) throw fan.sys.Err.make("Unknown log: " + name);
  return null;
}

fan.sys.Log.get = function(name)
{
  var log = fan.sys.Log.m_byName[name];
  if (log != null) return log;
  return fan.sys.Log.make(name, true);
}

fan.sys.Log.make = function(name, register)
{
  var self = new fan.sys.Log();
  fan.sys.Log.make$(self, name, register);
  return self;
}

fan.sys.Log.make$ = function(self, name, register)
{
  // verify valid name
  fan.sys.Uri.checkName(name);
  self.m_name = name;

  // if register
  if (register)
  {
    // verify unique
    if (fan.sys.Log.m_byName[name] != null)
      throw fan.sys.ArgErr.make("Duplicate log name: " + name);

    // init and put into map
    fan.sys.Log.m_byName[name] = self;

    // check for initial level
// TODO FIXIT
//    var val = (String)Sys.sysPod.props(Uri.fromStr("log.props"), Duration.oneMin).get(name);
//    if (val != null) self.level = LogLevel.fromStr(val);
  }
}

fan.sys.Log.m_byName = [];

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

fan.sys.Log.prototype.$typeof = function() { return fan.sys.Log.$type; }

fan.sys.Log.prototype.toStr = function() { return this.m_name; }

fan.sys.Log.prototype.name = function() { return this.m_name; }

//////////////////////////////////////////////////////////////////////////
// Severity Level
//////////////////////////////////////////////////////////////////////////

fan.sys.Log.prototype.level = function()
{
  return this.m_level;
}

fan.sys.Log.prototype.level$ = function(level)
{
  if (level == null) throw fan.sys.ArgErr.make("level cannot be null");
  this.m_level = level;
}

fan.sys.Log.prototype.enabled = function(level)
{
  return this.m_level.m_ordinal <= level.m_ordinal;
}

fan.sys.Log.prototype.isEnabled = function(level)
{
  return this.enabled(level);
}

fan.sys.Log.prototype.isErr = function()   { return this.isEnabled(fan.sys.LogLevel.m_err); }
fan.sys.Log.prototype.isWarn = function()  { return this.isEnabled(fan.sys.LogLevel.m_warn); }
fan.sys.Log.prototype.isInfo = function()  { return this.isEnabled(fan.sys.LogLevel.m_info); }
fan.sys.Log.prototype.isDebug = function() { return this.isEnabled(fan.sys.LogLevel.m_debug); }

//////////////////////////////////////////////////////////////////////////
// Logging
//////////////////////////////////////////////////////////////////////////

fan.sys.Log.prototype.err = function(msg, err)
{
  this.log(fan.sys.LogRec.make(fan.sys.DateTime.now(), fan.sys.LogLevel.m_err, this.m_name, msg, err));
}

fan.sys.Log.prototype.warn = function(msg, err)
{
  this.log(fan.sys.LogRec.make(fan.sys.DateTime.now(), fan.sys.LogLevel.m_warn, this.m_name, msg, err));
}

fan.sys.Log.prototype.info = function(msg, err)
{
  this.log(fan.sys.LogRec.make(fan.sys.DateTime.now(), fan.sys.LogLevel.m_info, this.m_name, msg, err));
}

fan.sys.Log.prototype.debug = function(msg, err)
{
  this.log(fan.sys.LogRec.make(fan.sys.DateTime.now(), fan.sys.LogLevel.m_debug, this.m_name, msg, err));
}

fan.sys.Log.prototype.log = function(rec)
{
  if (!this.enabled(rec.m_level)) return;

  for (var i=0; i<fan.sys.Log.m_handlers.length; ++i)
  {
    try { fan.sys.Log.m_handlers[i].call(rec); }
    catch (e) { fan.sys.Err.make(e).trace(); }
  }
}

//////////////////////////////////////////////////////////////////////////
// Handlers
//////////////////////////////////////////////////////////////////////////

fan.sys.Log.handlers = function()
{
  return fan.sys.List.make(fan.sys.Func.$type, fan.sys.Log.m_handlers).ro();
}

fan.sys.Log.addHandler = function(func)
{
  if (!func.isImmutable()) throw fan.sys.NotImmutableErr.make("handler must be immutable");
  fan.sys.Log.m_handlers.push(func);
}

fan.sys.Log.removeHandler = function(func)
{
  var index = null;
  for (var i=0; i<fan.sys.Log.m_handlers.length; i++)
    if (fan.sys.Log.m_handlers[i] == func) { index=i; break }

  if (index == null) return;
  fan.sys.Log.m_handlers.splice(index, 1);
}

fan.sys.Log.m_handlers = [];

