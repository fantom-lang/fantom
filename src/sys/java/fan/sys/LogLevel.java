//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   3 Jul 06  Brian Frank  Creation
//
package fan.sys;

/**
 * LogLevel provides a set of discrete levels used to customize logging.
 */
public class LogLevel
  extends Enum
{

//////////////////////////////////////////////////////////////////////////
// Range
//////////////////////////////////////////////////////////////////////////

  public static final int DEBUG  = 0;
  public static final int INFO   = 1;
  public static final int WARN   = 2;
  public static final int ERR    = 3;
  public static final int SILENT = 4;

  public static final LogLevel debug  = new LogLevel(DEBUG,  "debug");
  public static final LogLevel info   = new LogLevel(INFO,   "info");
  public static final LogLevel warn   = new LogLevel(WARN,   "warn");
  public static final LogLevel err    = new LogLevel(ERR,    "err");
  public static final LogLevel silent = new LogLevel(SILENT, "silent");

  static final LogLevel[] array = { debug, info, warn, err, silent };

  public static final List<LogLevel> vals = (List)new List(Sys.LogLevelType, array).toImmutable();

//////////////////////////////////////////////////////////////////////////
// Implementation
//////////////////////////////////////////////////////////////////////////

  private LogLevel(int ord, String name)
  {
    Enum.make$(this, FanInt.pos[ord], name.intern());
    this.ord = ord;
  }

  public static LogLevel fromStr(String name) { return fromStr(name, true); }
  public static LogLevel fromStr(String name, boolean checked)
  {
    return (LogLevel)doFromStr(Sys.LogLevelType, name, checked);
  }

  public Type typeof() { return Sys.LogLevelType; }

  final int ord;

}

