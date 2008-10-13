//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 Apr 08  Brian Frank  Creation
//

**
** FileLogger appends Str log entries to a file.  You
** can add a FileLogger as a Log handler:
**
**    sysLogger := FileLogger(null, scriptDir + `logs/sys.log`)
**    sysLogger.start
**    Log.addHandler(&sysLogger.writeLogRecord)
**
**
const class FileLogger : Thread
{

  **
  ** Constructor.
  **
  new make(Str? name := null, File? file := null)
    : super(name)
  {
    if (file != null) this.file = file
  }

  **
  ** File to append log records.
  **
  const File file

  **
  ** Append string log message to file.
  **
  Void writeLogRecord(LogRecord rec)
  {
    writeStr(rec.toStr)
  }

  **
  ** Append string log message to file.
  **
  Void writeStr(Str msg)
  {
    sendAsync(msg)
  }

  **
  ** Run the script
  **
  override Obj? run()
  {
    // open file
    OutStream? out := null
    try
    {
      if ((Obj?)file == null)
      {
        log.error("No file configured")
      }
      else
      {
        if (!file.exists) file.create
        out = file.out(true)
      }
    }
    catch (Err e)
    {
      log.error("Cannot open log file: $file", e)
      return null
    }

    // dequeue strings and append to file
    loop |Obj msg->Obj?|
    {
      if (out != null) out.printLine(msg).flush
      return null
    }

    return null
  }

  private const static Log log := Log.get("logger")

}