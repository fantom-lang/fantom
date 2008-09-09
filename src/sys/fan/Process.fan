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
** TODO: currently this API provides the bare necessities, need to add:
**    - async management
**    - stdin, stdout, stderr management
**    - env variables
**    - working directory
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
  new make(Str[] cmd, File dir := null)

//////////////////////////////////////////////////////////////////////////
// Configuration
//////////////////////////////////////////////////////////////////////////

  **
  ** Command list used to launch process.
  **
  Str[] command

  **
  ** Working directory of process.
  **
  File dir

//////////////////////////////////////////////////////////////////////////
// Lifecycle
//////////////////////////////////////////////////////////////////////////

  **
  ** Run this process and wait until it completes.  Return the
  ** exit code of the process.
  **
  Int run()

}