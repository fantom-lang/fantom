//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   3 Jul 06  Brian Frank  Creation
//
package fan.sys;

/**
 * LogRecord
 */
public class LogRecord
  extends FanObj
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  public static LogRecord make(DateTime time, LogLevel level, String logName, String msg) { return make(time, level, logName, msg, null); }
  public static LogRecord make(DateTime time, LogLevel level, String logName, String msg, Err err)
  {
    LogRecord self = new LogRecord();
    make$(self, time, level, logName, msg, err);
    return self;
  }

  public static void make$(LogRecord self, DateTime time, LogLevel level, String logName, String msg) { make$(self, time, level, logName, msg, null); }
  public static void make$(LogRecord self, DateTime time, LogLevel level, String logName, String msg, Err err)
  {
    self.time    = time;
    self.level   = level;
    self.logName = logName;
    self.message = msg;
    self.err     = err;
  }

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  public Type type() { return Sys.LogRecordType; }

  public String toStr()
  {
    String ts = ((DateTime)time).toLocale("hh:mm:ss DD-MMM-YY");
    StringBuilder s = new StringBuilder();
    s.append('[').append(ts).append(']')
     .append(' ').append('[').append(level).append(']')
     .append(' ').append('[').append(logName).append(']')
     .append(' ').append(message);
    return s.toString();
  }

  public void print() { print(Sys.out()); }
  public void print(OutStream out)
  {
    synchronized (out)
    {
      out.printLine(toStr());
      if (err != null) err.trace(out, 2, true);
    }
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  public DateTime time;
  public LogLevel level;
  public String logName;
  public String message;
  public Err err;

}