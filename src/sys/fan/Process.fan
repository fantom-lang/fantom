//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   5 Nov 06  Brian Frank  Creation
//

**
** Process manages spawning external OS processes.
**
final class Process
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  **
  ** Construct a Process instanced used to launch an external
  ** OS process with the specified command arguments.
  **
  new make(Str[] cmd := Str[,], File? dir := null)

//////////////////////////////////////////////////////////////////////////
// Configuration
//////////////////////////////////////////////////////////////////////////

  **
  ** Command argument list used to launch process.
  **
  Str[] command

  **
  ** Environment variables to pass to new process.  This
  ** map is initialized with the current process environment.
  **
  Str:Str env()

  **
  ** Working directory of process.
  **
  File? dir

  **
  ** If true, then stderr is redirected to the output
  ** stream configured via the 'out' field, and the 'err'
  ** field is ignored.  The default is true.
  **
  Bool mergeErr := true

  **
  ** The output stream used to sink the process stdout.
  ** Default is to send to `Sys.out`.  If set to null, then
  ** output is silently consumed like /dev/null.
  **
  OutStream? out := Sys.out

  **
  ** The output stream used to sink the process stderr.
  ** Default is to send to `Sys.err`.  If set to null, then
  ** output is silently consumed like /dev/null.  Note
  ** this field is ignored if `mergeErr` is set
  ** true, in which case stderr goes to the stream configured
  ** via 'out'.
  **
  OutStream? err := Sys.err

  **
  ** The input stream used to source the process stdin.
  ** If null, then the new process will block if it attempts
  ** to read stdin.  Default is null.
  **
  InStream? in := null

//////////////////////////////////////////////////////////////////////////
// Lifecycle
//////////////////////////////////////////////////////////////////////////

  **
  ** Spawn this process.  See `join` to wait until the process
  ** finished and to get the exit code.  Return this.
  **
  This run()

  **
  ** Wait for this process to exit and return the exit code.
  ** This method may only be called once after 'run'.
  **
  Int join()

}