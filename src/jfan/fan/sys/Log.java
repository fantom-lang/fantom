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

  public static Log find(Str name) { return find(name, Bool.True); }
  public static Log find(Str name, Bool checked)
  {
    synchronized (lock)
    {
      Log log = (Log)byName.get(name);
      if (log != null) return log;
      if (checked.val) throw Err.make("Unknown log: " + name).val;
      return null;
    }
  }

  public static Log get(String name) { return get(Str.make(name)); }
  public static Log get(Str name)
  {
    synchronized (lock)
    {
      Log log = (Log)byName.get(name);
      if (log != null) return log;
      return make(name);
    }
  }

  public static Log make(Str name)
  {
    Log self = new Log();
    make$(self, name);
    return self;
  }

  public static void make$(Log self, Str name)
  {
    synchronized (lock)
    {
      // verify valid name
      Uri.checkName(name);

      // verify unique
      if (byName.get(name) != null)
        throw ArgErr.make("Duplicate log name: " + name).val;

      // init and put into map
      self.name = name;
      byName.put(name, self);

      // check for initial level
      if (logProps != null)
      {
        Str val = (Str)logProps.get(name);
        if (val != null)
          self.level = LogLevel.fromStr(val);
      }
    }
  }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  public Type type()
  {
    return Sys.LogType;
  }

  public final Str toStr()
  {
    return name;
  }

  public final Str name()
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
    if (level == null) throw ArgErr.make("level cannot be null").val;
    this.level = level;
  }

  public final boolean enabled(LogLevel level)
  {
    return this.level.ord <= level.ord;
  }

  public final Bool isEnabled(LogLevel level)
  {
    return enabled(level) ? Bool.True : Bool.False;
  }

  public final Bool isError() { return isEnabled(LogLevel.error); }

  public final Bool isWarn()  { return isEnabled(LogLevel.warn); }

  public final Bool isInfo()  { return isEnabled(LogLevel.info); }

  public final Bool isDebug() { return isEnabled(LogLevel.debug); }

//////////////////////////////////////////////////////////////////////////
// Logging
//////////////////////////////////////////////////////////////////////////

  public final void error(Str message) { error(message, null); }
  public final void error(String message) { error(Str.make(message), null); }
  public final void error(String message, Throwable e) { error(Str.make(message), Err.make(e)); }
  public final void error(Str message, Err err)
  {
    log(LogRecord.make(DateTime.now(), LogLevel.error, name, message, err));
  }

  public final void warn(Str message) { warn(message, null); }
  public final void warn(String message) { warn(Str.make(message), null); }
  public final void warn(String message, Throwable e) { warn(Str.make(message), Err.make(e)); }
  public final void warn(Str message, Err err)
  {
    log(LogRecord.make(DateTime.now(), LogLevel.warn, name, message, err));
  }

  public final void info(Str message) { info(message, null); }
  public final void info(String message) { info(Str.make(message), null); }
  public final void info(String message, Throwable e) { info(Str.make(message), Err.make(e)); }
  public final void info(Str message, Err err)
  {
    log(LogRecord.make(DateTime.now(), LogLevel.info, name, message, err));
  }

  public final void debug(Str message) { debug(message, null); }
  public final void debug(String message) { debug(Str.make(message), null); }
  public final void debug(String message, Throwable e) { debug(Str.make(message), Err.make(e)); }
  public final void debug(Str message, Err err)
  {
    log(LogRecord.make(DateTime.now(), LogLevel.debug, name, message, err));
  }

  public void log(LogRecord rec)
  {
    if (!enabled(rec.level)) return;

    Func[] handlers = Log.handlers;
    for (int i=0; i<handlers.length; ++i)
    {
      try
      {
        handlers[i].call1(rec);
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
    if (!func.isImmutable().val)
      throw NotImmutableErr.make("handler must be immutable").val;

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
      handlers[0] = Sys.LogRecordType.method("print", true).func();
    }
    catch (Throwable e)
    {
      handlers = new Func[0];
      e.printStackTrace();
    }
  }

//////////////////////////////////////////////////////////////////////////
// Static Init
//////////////////////////////////////////////////////////////////////////

  static
  {
    try
    {
      File f  = Sys.homeDir().plus("lib/log.props");
      if (f.exists().val)
      {
        Map props = logProps = f.readProps();
        List keys = props.keys();
        for (int i=0; i<keys.sz(); ++i)
        {
          Str key = (Str)keys.get(i);
          Str val = (Str)props.get(key);
          if (LogLevel.fromStr(val, Bool.False) == null)
          {
            System.out.println("ERROR: Invalid level lib/log.props#" + key + " = " + val);
            props.remove(key);
          }
        }
      }
    }
    catch (Exception e)
    {
      System.out.println("ERROR: Cannot load lib/log.props");
      e.printStackTrace();
    }
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private static Object lock = new Object();       // synchronization
  private static HashMap byName = new HashMap();   // String -> Log
  private static Map logProps;

  private Str name;
  private volatile LogLevel level = LogLevel.info;

}