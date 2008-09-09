//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 Dec 07  Andy Frank  Creation
//

using System.Text;

namespace Fan.Sys
{
  /// <summary>
  /// LogRecord.
  /// </summary>
  public class LogRecord : FanObj
  {

  //////////////////////////////////////////////////////////////////////////
  // Construction
  //////////////////////////////////////////////////////////////////////////

    public static LogRecord make(DateTime time, LogLevel level, Str logName, Str msg) { return make(time, level, logName, msg); }
    public static LogRecord make(DateTime time, LogLevel level, Str logName, Str msg, Err err)
    {
      LogRecord self = new LogRecord();
      make_(self, time, level, logName, msg, err);
      return self;
    }

    public static void make_(LogRecord self, DateTime time, LogLevel level, Str logName, Str msg) { make_(self, time, level, logName, msg, null); }
    public static void make_(LogRecord self, DateTime time, LogLevel level, Str logName, Str msg, Err err)
    {
      self.m_time    = time;
      self.m_level   = level;
      self.m_logName = logName;
      self.m_message = msg;
      self.m_err     = err;
    }

  //////////////////////////////////////////////////////////////////////////
  // Methods
  //////////////////////////////////////////////////////////////////////////

    public override Type type() { return Sys.LogRecordType; }

    public override Str toStr()
    {
      string ts = m_time.toLocale("hh:mm:ss DD-MMM-YY");
      StringBuilder s = new StringBuilder();
      s.Append('[').Append(ts).Append(']')
       .Append(' ').Append('[').Append(m_level).Append(']')
       .Append(' ').Append('[').Append(m_logName).Append(']')
       .Append(' ').Append(m_message);
      return Str.make(s.ToString());
    }

    public void print() { print(Sys.@out()); }
    public void print(OutStream @out)
    {
      @out.printLine(toStr());
      if (m_err != null) m_err.trace(@out, 2);
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    public DateTime m_time;
    public LogLevel m_level;
    public Str m_logName;
    public Str m_message;
    public Err m_err;

  }
}