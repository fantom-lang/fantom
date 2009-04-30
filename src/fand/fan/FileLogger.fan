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
**    sysLogger := FileLogger(scriptDir + `logs/sys.log`)
**    sysLogger.start
**    Log.addHandler(&sysLogger.writeLogRecord)
**
**
const class FileLogger : ActorPool
{

  **
  ** Constructor.
  **
  new make(|This|? f := null) { if (f != null) f(this) }

  **
  ** File to append log records.  This value can be
  ** configured as a const field, or by `open` method.
  **
  const File? file

  **
  ** Open the specified file to write for the file logger.
  ** The file is used instead of the `file` field.  This method
  ** must be called before attempting to write to the log.
  **
  Void open(File file)
  {
    actor.send(file)
  }

  **
  ** Append string log message to file.
  **
  Void writeLogRecord(LogRecord rec)
  {
    actor.send(rec.toStr)
  }

  **
  ** Append string log message to file.
  **
  Void writeStr(Str msg)
  {
    actor.send(msg)
  }

  **
  ** Run the script
  **
  internal Void receive(Obj msg, Context cx)
  {
    // if file message, this is an open()
    file := this.file
    write := true
    if (msg is File)
    {
      file = msg
      write = false
      cx["error"] = null
    }

    // if we are in error condition ignore
    if (cx["error"] != null) return

    // open file if first time thru
    OutStream? out := cx["out"]
    if (out == null)
    {
      // if no file configured
      if (file == null)
      {
        cx["error"] = true
        log.error("No file configured")
        return
      }

      // open it to append
      try
      {
        if (!file.exists) file.create
        out = file.out(true)
        cx["out"] = out
      }
      catch (Err e)
      {
        cx["error"] = true
        log.error("Cannot open log file: $file", e)
        return
      }
    }

    // append to file
    if (write) out.printLine(msg).flush
  }

  private const static Log log := Log.get("logger")
  private const Actor actor := Actor(this, &receive)

}