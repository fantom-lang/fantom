//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 Dec 07  Andy Frank  Creation
//

namespace Fan.Sys
{
  /// <summary>
  /// LogLevel provides a set of discrete levels used to customize logging.
  /// </summary>
  public class LogLevel : Enum
  {

  //////////////////////////////////////////////////////////////////////////
  // Range
  //////////////////////////////////////////////////////////////////////////

    public static readonly LogLevel m_debug  = new LogLevel(0, "debug");
    public static readonly LogLevel m_info   = new LogLevel(1, "info");
    public static readonly LogLevel m_warn   = new LogLevel(2, "warn");
    public static readonly LogLevel m_err    = new LogLevel(3, "err");
    public static readonly LogLevel m_silent = new LogLevel(4, "silent");

    static readonly LogLevel[] array = { m_debug, m_info, m_warn, m_err, m_silent };

    public static readonly List m_vals = (List)new List(Sys.LogLevelType, array).toImmutable();

  //////////////////////////////////////////////////////////////////////////
  // Implementation
  //////////////////////////////////////////////////////////////////////////

    private LogLevel(int ord, string name)
    {
      Enum.make_(this, ord, System.String.Intern(name));
      this.m_ord = ord;
    }

    public static LogLevel fromStr(string name) { return fromStr(name, true); }
    public static LogLevel fromStr(string name, bool check)
    {
      return (LogLevel)doFromStr(Sys.LogLevelType, name, check);
    }

    public override Type @typeof() { return Sys.LogLevelType; }

    internal readonly int m_ord;

  }
}