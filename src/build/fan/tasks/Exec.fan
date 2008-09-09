//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   4 Nov 06  Brian Frank  Creation
//

**
** Exec is used to run an external OS process
**
class Exec : Task
{

  new make(BuildScript script, Str[] cmd, File dir := null)
    : super(script)
  {
    this.process = Process.make(cmd, dir)
  }

  override Void run()
  {
    cmd := process.command.join(" ")
    try
    {
      log.info("Exec [$cmd]")
      result := process.run
      if (result != 0) throw Err.make
    }
    catch (Err err)
    {
      if (log.isDebug) err.trace
      throw fatal("Exec failed [$cmd]")
    }
  }

  Process process
}