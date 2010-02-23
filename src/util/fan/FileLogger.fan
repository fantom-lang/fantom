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
**    sysLogger := FileLogger
**    {
**      dir = scriptDir
**      filename = "sys-{YYMM}.log"
**    }
**    sysLogger.start
**    Log.addHandler |rec| { sysLogger.writeLogRec(rec) }
**
** See `filename` for specifying a datetime pattern for your log files.
**
const class FileLogger : ActorPool
{

  **
  ** Constructor must set `dir` and `filename`
  **
  new make(|This|? f := null)
  {
    if (f != null) f(this)
    if (dir === noDir) throw ArgErr("Must configure 'dir'")
    if (filename.isEmpty) throw ArgErr("Must configure 'filename'")
  }

  **
  ** Directory used to store log file(s).
  **
  const File dir := noDir
  private static const File noDir := File(`no-dir-configured`)

  **
  ** Log filename pattern.  The name may contain a pattern between
  ** '{}' using the pattern format of `sys::DateTime.toLocale`.  For
  ** example to maintain a log file per month, use a filename such
  ** as "mylog-{YYYY-MM}.log".
  **
  const Str filename := ""

  **
  ** Append string log message to file.
  **
  Void writeLogRec(LogRec rec)
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
  internal Obj? receive(Obj msg)
  {
    try
    {
      // get or initialize current state
      state := Actor.locals["state"] as FileLoggerState
      if (state == null)
        Actor.locals["state"] = state = FileLoggerState(dir, filename)

      // append to current file
      state.out.printLine(msg).flush
    }
    catch (Err e)
    {
      log.err("FileLogger.receive", e)
    }
    return null
  }

  private const static Log log := Log.get("logger")
  private const Actor actor := Actor(this) |msg| { receive(msg) }

}

internal class FileLoggerState
{
  new make(File dir, Str filename)
  {
    this.dir = dir
    this.filename = filename
    i := filename.index("{")
    if (i != null)
      this.pattern = filename[i+1 ..< filename.index("}")]
    else
      this.curOut = (dir + filename.toUri).out(true)
  }

  OutStream out()
  {
    // check if we need to open a new file
    if (pattern != null && DateTime.now.toLocale(pattern) != curPattern)
    {
      // if we currently have a file open, then close it
      curOut?.close

      // open new file with new pattern
      curPattern = DateTime.now.toLocale(pattern)
      newName := filename[0..<filename.index("{")] +
                 curPattern +
                 filename[filename.index("}")+1..-1]
      curFile := dir + newName.toUri
      curOut = curFile.out(true)
    }

    // current output stream
    return curOut
  }

  const Str filename
  const File dir
  Str? pattern
  Str curPattern := ""
  OutStream? curOut
}