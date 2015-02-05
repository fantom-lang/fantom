//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   3 Jul 06  Brian Frank  Creation
//  21 Dec 07  Brian Frank  Revamp
//
package fan.sys;

import java.util.HashMap;

/**
 * Log provides a simple, but standardized mechanism for logging.
 */
public class Log
  extends FanObj
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  public static List list()
  {
    synchronized (lock)
    {
      return new List(Sys.LogType, (Log[])byName.values().toArray(new Log[byName.size()])).ro();
    }
  }

  public static Log find(String name) { return find(name, true); }
  public static Log find(String name, boolean checked)
  {
    synchronized (lock)
    {
      Log log = (Log)byName.get(name);
      if (log != null) return log;
      if (checked) throw Err.make("Unknown log: " + name);
      return null;
    }
  }

  public static Log get(String name)
  {
    synchronized (lock)
    {
      Log log = (Log)byName.get(name);
      if (log != null) return log;
      return make(name, true);
    }
  }

  public static Log make(String name, boolean register)
  {
    Log self = new Log();
    make$(self, name, register);
    return self;
  }

  public static void make$(Log self, String name, boolean register)
  {
    // verify valid name
    Uri.checkName(name);
    self.name = name;

    // if register
    if (register)
    {
      synchronized (lock)
      {
        // verify unique
        if (byName.get(name) != null)
          throw ArgErr.make("Duplicate log name: " + name);

        // init and put into map
        byName.put(name, self);

        // check for initial level
        String val = (String)Sys.sysPod.props(Uri.fromStr("log.props"), Duration.oneMin).get(name);
        if (val != null) self.level = LogLevel.fromStr(val);
      }
    }
  }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  public Type typeof()
  {
    return Sys.LogType;
  }

  public final String toStr()
  {
    return name;
  }

  public final String name()
  {
    return name;
  }

//////////////////////////////////////////////////////////////////////////
// Severity Level
//////////////////////////////////////////////////////////////////////////

  public final LogLevel level()
  {
    return level;
  }

  public final void level(LogLevel level)
  {
    if (level == null) throw ArgErr.make("level cannot be null");
    this.level = level;
  }

  public final boolean enabled(LogLevel level)
  {
    return this.level.ord <= level.ord;
  }

  public final boolean isEnabled(LogLevel level)
  {
    return enabled(level);
  }

  public final boolean isErr()   { return isEnabled(LogLevel.err); }

  public final boolean isWarn()  { return isEnabled(LogLevel.warn); }

  public final boolean isInfo()  { return isEnabled(LogLevel.info); }

  public final boolean isDebug() { return isEnabled(LogLevel.debug); }

//////////////////////////////////////////////////////////////////////////
// Logging
//////////////////////////////////////////////////////////////////////////

  public final void err(String msg) { err(msg, (Err)null); }
  public final void err(String msg, Throwable e) { err(msg, Err.make(e)); }
  public final void err(String msg, Err err)
  {
    log(LogRec.make(DateTime.now(null), LogLevel.err, name, msg, err));
  }

  public final void warn(String msg) { warn(msg, (Err)null); }
  public final void warn(String msg, Throwable e) { warn(msg, Err.make(e)); }
  public final void warn(String msg, Err err)
  {
    log(LogRec.make(DateTime.now(null), LogLevel.warn, name, msg, err));
  }

  public final void info(String msg) { info(msg, (Err)null); }
  public final void info(String msg, Throwable e) { info(msg, Err.make(e)); }
  public final void info(String msg, Err err)
  {
    log(LogRec.make(DateTime.now(null), LogLevel.info, name, msg, err));
  }

  public final void debug(String msg) { debug(msg, (Err)null); }
  public final void debug(String msg, Throwable e) { debug(msg, Err.make(e)); }
  public final void debug(String msg, Err err)
  {
    log(LogRec.make(DateTime.now(null), LogLevel.debug, name, msg, err));
  }

  public void log(LogRec rec)
  {
    if (!enabled(rec.level)) return;

    Func[] handlers = Log.handlers;
    for (int i=0; i<handlers.length; ++i)
    {
      try
      {
        handlers[i].call(rec);
      }
      catch (Throwable e)
      {
        e.printStackTrace();
      }
    }
  }

//////////////////////////////////////////////////////////////////////////
// Handlers
//////////////////////////////////////////////////////////////////////////

  public static List handlers()
  {
    return new List(Sys.FuncType, handlers).ro();
  }

  public static void addHandler(Func func)
  {
    if (!func.isImmutable())
      throw NotImmutableErr.make("handler must be immutable");

    synchronized (lock)
    {
      List temp = new List(Sys.FuncType, handlers).add(func);
      handlers = (Func[])temp.toArray(new Func[temp.sz()]);
    }
  }

  public static void removeHandler(Func func)
  {
    synchronized (lock)
    {
      List temp = new List(Sys.FuncType, handlers);
      temp.remove(func);
      handlers = (Func[])temp.toArray(new Func[temp.sz()]);
    }
  }

  // handlers
  static volatile Func[] handlers = new Func[1];
  static
  {
    try
    {
      handlers[0] = Sys.LogRecType.method("print", true).func();
    }
    catch (Throwable e)
    {
      handlers = new Func[0];
      e.printStackTrace();
    }
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private static Object lock = new Object();       // synchronization
  private static HashMap byName = new HashMap();   // String -> Log

  private String name;
  private volatile LogLevel level = LogLevel.info;

}