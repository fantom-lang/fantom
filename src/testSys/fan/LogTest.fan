//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   3 Jul 06  Brian Frank  Creation
//

**
** LogTest
**
class LogTest : Test
{

//////////////////////////////////////////////////////////////////////////
// LogLevel
//////////////////////////////////////////////////////////////////////////

  Void testLogLevel()
  {
    verifyEq(LogLevel#.qname, "sys::LogLevel")
    verifyEq(LogLevel.values, [LogLevel.debug, LogLevel.info, LogLevel.warn, LogLevel.error, LogLevel.silent])
    verifyEq(LogLevel.values.isRO, true)

    verifyEq(LogLevel.debug.ordinal,  0)
    verifyEq(LogLevel.info.ordinal,   1)
    verifyEq(LogLevel.warn.ordinal,   2)
    verifyEq(LogLevel.error.ordinal,  3)
    verifyEq(LogLevel.silent.ordinal, 4)

    verifySame(LogLevel.fromStr("warn"), LogLevel.warn)

    verify(LogLevel.silent > LogLevel.error)
    verify(LogLevel.error  > LogLevel.debug)
    verify(LogLevel.error  > LogLevel.warn)
    verify(LogLevel.warn   > LogLevel.info)
  }

//////////////////////////////////////////////////////////////////////////
// Make
//////////////////////////////////////////////////////////////////////////

  Void testMake()
  {
    log := log()
    verifyErr(ArgErr#) |,| { TestLog.make(log.name) }
    verifyEq(log.name, "testSys.TestLog")
    verifyEq(log.level, LogLevel.info)
// TODO
//    verifySame("/sys/logs/$log.name".toUri.resolve.obj, log)

    verify(Log.list.contains(log))
    verifySame(Log.get(log.name),  log)
    verifySame(Log.find(log.name), log)
    verifySame(Log.find(log.name, true), log)
    verifyEq(Log.find("testSys.foobar", false), null)
    verifyErr(Err#) |,| { Log.find("testSys.foobar") }
    verifyErr(Err#) |,| { Log.find("testSys.foobar", true) }
    verifyErr(NameErr#) |,| { Log.get("@badName") }
    verifyErr(NameErr#) |,| { Log.make("no good") }
    verifyErr(NameErr#) |,| { TestLog.make("no good") }
  }

//////////////////////////////////////////////////////////////////////////
// Error
//////////////////////////////////////////////////////////////////////////

  Void testError()
  {
    log := log()
    err := Err.make

    log.level = LogLevel.silent
    reset
    log.error("xyz")
    verifyLog(null)
    reset
    log.error("xyz", err)
    verifyLog(null)

    verifyFalse(log.isEnabled(LogLevel.error))
    verifyFalse(log.isError)
    verifyFalse(log.isWarn)
    verifyFalse(log.isInfo)
    verifyFalse(log.isDebug);

    [LogLevel.error, LogLevel.warn, LogLevel.info, LogLevel.debug].each |LogLevel level|
    {
      log.level = level
      reset
      log.error("xyz")
      verifyLog(LogLevel.error, "xyz", null)
      reset
      log.error("xyz", err)
      verifyLog(LogLevel.error, "xyz", err)
    }
  }



//////////////////////////////////////////////////////////////////////////
// Warning
//////////////////////////////////////////////////////////////////////////

  Void testWarning()
  {
    log := log()
    err := Err.make;

    [LogLevel.silent, LogLevel.error].each |LogLevel level|
    {
      log.level = level
      reset
      log.warn("xyz")
      verifyLog(null)
      reset
      log.warn("xyz", err)
      verifyLog(null);
    };

    [LogLevel.warn, LogLevel.info, LogLevel.debug].each |LogLevel level|
    {
      log.level = level
      reset
      log.warn("xyz")
      verifyLog(LogLevel.warn, "xyz", null)
      reset
      log.warn("xyz", err)
      verifyLog(LogLevel.warn, "xyz", err)
    }
  }

//////////////////////////////////////////////////////////////////////////
// Info
//////////////////////////////////////////////////////////////////////////

  Void testInfo()
  {
    log := log()
    err := Err.make;

    [LogLevel.silent, LogLevel.error, LogLevel.warn].each |LogLevel level|
    {
      log.level = level
      reset
      log.info("xyz")
      verifyLog(null)
      reset
      log.info("xyz", err)
      verifyLog(null);
    };

    [LogLevel.info, LogLevel.debug].each |LogLevel level|
    {
      log.level = level
      reset
      log.info("xyz")
      verifyLog(LogLevel.info, "xyz", null)
      reset
      log.info("xyz", err)
      verifyLog(LogLevel.info, "xyz", err)
    }
  }

//////////////////////////////////////////////////////////////////////////
// Debug
//////////////////////////////////////////////////////////////////////////

  Void testDebug()
  {
    log := log()
    err := Err.make;

    [LogLevel.silent, LogLevel.error, LogLevel.warn, LogLevel.info].each |LogLevel level|
    {
      log.level = level
      reset
      log.debug("xyz")
      verifyLog(null)
      reset
      log.debug("xyz", err)
      verifyLog(null);
    };

    [LogLevel.debug].each |LogLevel level|
    {
      log.level = level
      reset
      log.debug("xyz")
      verifyLog(LogLevel.debug, "xyz", null)
      reset
      log.debug("xyz", err)
      verifyLog(LogLevel.debug, "xyz", err)
    }
  }

//////////////////////////////////////////////////////////////////////////
// Handlers
//////////////////////////////////////////////////////////////////////////

  Void testHandlers()
  {
    console := Log.handlers.first
    Log.removeHandler(console)
    try
    {
      h := |LogRecord rec|
      {
        Thread.locals["testSys.logRecord"] = rec
      }

      Log.addHandler(h)
      verify(Log.handlers.contains(h))
      verifyErr(NotImmutableErr#) |,| { Log.addHandler(&mutableHandler) }

      reset
      Log.get("testSys.LogTestToo").info("what")
      verifyLog(LogLevel.info, "what", null)

      Log.removeHandler(h)
      verify(!Log.handlers.contains(h))

      reset
      Log.get("testSys.LogTestToo").info("what")
      verifyLog(null)
    }
    finally
    {
      Log.addHandler(console)
    }
  }

  Void mutableHandler(LogRecord rec) {}

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  Void verifyLog(LogLevel? level, Str? msg := null, Err? err := null)
  {
    log := log()
    LogRecord rec := Thread.locals["testSys.logRecord"]
    if (level == null)
    {
      verifyEq(level, null)
    }
    else
    {
      verify(start.ticks <= rec.time.ticks && rec.time.ticks < start.ticks + 1sec.ticks)
      verifyEq(rec.level, level)
      verifyEq(rec.message,  msg)
      verifyEq(rec.err,  err)
    }
  }

  Void reset()
  {
    Thread.locals["testSys.logRecord"] = null
  }

  // Lazy Log Construction
  static TestLog log()
  {
    log := Log.find("testSys.TestLog", false)
    if (log == null) log = TestLog.make("testSys.TestLog")
    return (TestLog)log
  }

  DateTime start := DateTime.now
}

//////////////////////////////////////////////////////////////////////////
// TestLog
//////////////////////////////////////////////////////////////////////////

const class TestLog : Log
{
  new make(Str name) : super(name) {}

  override Void log(LogRecord rec)
  {
    // super.log(time, level, msg, err)
    if (isEnabled(level))
      Thread.locals["testSys.logRecord"] = rec
  }

}