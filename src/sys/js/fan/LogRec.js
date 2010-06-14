//
// Copyright (c) 2010, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 Mar 10  Andy Frank  Creation
//

/**
 * LogRec.
 */
fan.sys.LogRec = fan.sys.Obj.$extend(fan.sys.Obj);

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

fan.sys.LogRec.prototype.$ctor = function() {}

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
  var ts = this.m_time.toLocale("hh:mm:ss DD-MMM-YY");
  return '[' + ts + '] [' + this.m_level + '] [' + this.m_logName + '] ' + this.m_msg;
}

fan.sys.LogRec.prototype.print = function(out)
{
  // TODO FIXIT
  //if (out === undefined) out = ???
  //out.printLine(toStr());
  //if (err != null) err.trace(out, 2, true);

  fan.sys.ObjUtil.echo(this.toStr());
  if (this.m_err != null) this.m_err.trace(); // echo routes to console too
}

fan.sys.LogRec.prototype.$typeof = function() { return fan.sys.LogRec.$type; }


