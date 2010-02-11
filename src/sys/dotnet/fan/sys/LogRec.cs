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
  /// LogRec.
  /// </summary>
  public class LogRec : FanObj
  {

  //////////////////////////////////////////////////////////////////////////
  // Construction
  //////////////////////////////////////////////////////////////////////////

    public static LogRec make(DateTime time, LogLevel level, string logName, string msg) { return make(time, level, logName, msg, null); }
    public static LogRec make(DateTime time, LogLevel level, string logName, string msg, Err err)
    {
      LogRec self = new LogRec();
      make_(self, time, level, logName, msg, err);
      return self;
    }

    public static void make_(LogRec self, DateTime time, LogLevel level, string logName, string msg) { make_(self, time, level, logName, msg, null); }
    public static void make_(LogRec self, DateTime time, LogLevel level, string logName, string msg, Err err)
    {
      self.m_time    = time;
      self.m_level   = level;
      self.m_logName = logName;
      self.m_msg     = msg;
      self.m_err     = err;
    }

  //////////////////////////////////////////////////////////////////////////
  // Methods
  //////////////////////////////////////////////////////////////////////////

    public override Type @typeof() { return Sys.LogRecType; }

    public override string toStr()
    {
      string ts = m_time.toLocale("hh:mm:ss DD-MMM-YY");
      StringBuilder s = new StringBuilder();
      s.Append('[').Append(ts).Append(']')
       .Append(' ').Append('[').Append(m_level).Append(']')
       .Append(' ').Append('[').Append(m_logName).Append(']')
       .Append(' ').Append(m_msg);
      return s.ToString();
    }

    public void print() { print(Env.cur().@out()); }
    public void print(OutStream @out)
    {
      lock (@out)
      {
        @out.printLine(toStr());
        if (m_err != null) m_err.trace(@out, null, 2, true);
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    public DateTime m_time;
    public LogLevel m_level;
    public string m_logName;
    public string m_msg;
    public Err m_err;

  }
}