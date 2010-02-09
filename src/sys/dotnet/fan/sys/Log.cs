//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//  24 Dec 07  Andy Frank  Creation
//

using System.Collections;

namespace Fan.Sys
{
  /// <summary>
  /// Log provides a simple, but standardized mechanism for logging.
  /// </summary>
  public class Log : FanObj
  {

  //////////////////////////////////////////////////////////////////////////
  // Construction
  //////////////////////////////////////////////////////////////////////////

    public static List list()
    {
      lock (lockObj)
      {
        Log[] arr = new Log[byName.Count];
        byName.Values.CopyTo(arr, 0);
        return new List(Sys.LogType, arr).ro();
      }
    }

    public static Log find(string name) { return find(name, true); }
    public static Log find(string name, bool check)
    {
      lock (lockObj)
      {
        Log log = (Log)byName[name];
        if (log != null) return log;
        if (check) throw Err.make("Unknown log: " + name).val;
        return null;
      }
    }

    public static Log get(string name)
    {
      lock (lockObj)
      {
        Log log = (Log)byName[name];
        if (log != null) return log;
        return make(name, true);
      }
    }

    public static Log make(string name, bool register)
    {
      Log self = new Log();
      make_(self, name, register);
      return self;
    }

    public static void make_(Log self, string name, bool register)
    {
      // verify valid name
      Uri.checkName(name);
      self.m_name = name;

      if (register)
      {
        lock (lockObj)
        {
          // verify unique
          if (byName[name] != null)
            throw ArgErr.make("Duplicate log name: " + name).val;

          // init and put into map
          byName[name] = self;

          // check for initial level
          string val = (string)Sys.m_sysPod.props(Uri.fromStr("log.props"), Duration.m_oneMin).get(name);
          if (val != null) self.m_level = LogLevel.fromStr(val);
        }
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // Identity
  //////////////////////////////////////////////////////////////////////////

    public override Type @typeof()
    {
      return Sys.LogType;
    }

    public sealed override string toStr()
    {
      return m_name;
    }

    public string name()
    {
      return m_name;
    }

  //////////////////////////////////////////////////////////////////////////
  // Severity Level
  //////////////////////////////////////////////////////////////////////////

    public LogLevel level()
    {
      return m_level;
    }

    public void level(LogLevel level)
    {
      if (level == null) throw ArgErr.make("level cannot be null").val;
      this.m_level = level;
    }

    public bool enabled(LogLevel level)
    {
      return this.m_level.m_ord <= level.m_ord;
    }

    public bool isEnabled(LogLevel level)
    {
      return enabled(level);
    }

    public bool isErr() { return isEnabled(LogLevel.m_err); }

    public bool isWarn()  { return isEnabled(LogLevel.m_warn); }

    public bool isInfo()  { return isEnabled(LogLevel.m_info); }

    public bool isDebug() { return isEnabled(LogLevel.m_debug); }

  //////////////////////////////////////////////////////////////////////////
  // Logging
  //////////////////////////////////////////////////////////////////////////

    public void err(string message) { err(message, (Err)null); }
    public void err(string message, System.Exception e) { err(message, Err.make(e)); }
    public void err(string message, Err err)
    {
      log(LogRec.make(DateTime.now(), LogLevel.m_err, m_name, message, err));
    }

    public void warn(string message) { warn(message, (Err)null); }
    public void warn(string message, System.Exception e) { warn(message, Err.make(e)); }
    public void warn(string message, Err err)
    {
      log(LogRec.make(DateTime.now(), LogLevel.m_warn, m_name, message, err));
    }

    public void info(string message) { info(message, (Err)null); }
    public void info(string message, System.Exception e) { info(message, Err.make(e)); }
    public void info(string message, Err err)
    {
      log(LogRec.make(DateTime.now(), LogLevel.m_info, m_name, message, err));
    }

    public void debug(string message) { debug(message, (Err)null); }
    public void debug(string message, System.Exception e) { debug(message, Err.make(e)); }
    public void debug(string message, Err err)
    {
      log(LogRec.make(DateTime.now(), LogLevel.m_debug, m_name, message, err));
    }

    public virtual void log(LogRec rec)
    {
      if (!enabled(rec.m_level)) return;

      Func[] handlers = Log.m_handlers;
      for (int i=0; i<handlers.Length; ++i)
      {
        try
        {
          handlers[i].call(rec);
        }
        catch (System.Exception e)
        {
          Err.dumpStack(e);
        }
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // Handlers
  //////////////////////////////////////////////////////////////////////////

    public static List handlers()
    {
      return new List(Sys.FuncType, m_handlers).ro();
    }

    public static void addHandler(Func func)
    {
      if (!func.isImmutable())
        throw NotImmutableErr.make("handler must be immutable").val;

      lock (lockObj)
      {
        List temp = new List(Sys.FuncType, m_handlers).add(func);
        m_handlers = (Func[])temp.toArray(new Func[temp.sz()]);
      }
    }

    public static void removeHandler(Func func)
    {
      lock (lockObj)
      {
        List temp = new List(Sys.FuncType, m_handlers);
        temp.remove(func);
        m_handlers = (Func[])temp.toArray(new Func[temp.sz()]);
      }
    }

    // handlers
    static volatile Func[] m_handlers = new Func[1];

  //////////////////////////////////////////////////////////////////////////
  // Static Init
  //////////////////////////////////////////////////////////////////////////

    static Log()
    {
      try
      {
        m_handlers[0] = Sys.LogRecType.method("print", true).func();
      }
      catch (System.Exception e)
      {
        m_handlers = new Func[0];
        Err.dumpStack(e);
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    private static object lockObj = new System.Object();  // synchronization
    private static Hashtable byName = new Hashtable();    // string -> Log

    private string m_name;
    private volatile LogLevel m_level = LogLevel.m_info;

  }
}