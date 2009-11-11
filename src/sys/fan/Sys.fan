//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   9 Jan 06  Brian Frank  Creation
//

**
** Sys provides static access to the system's environment.
**
final class Sys
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  **
  ** Private constructor.
  **
  private new make()

//////////////////////////////////////////////////////////////////////////
// Environment
//////////////////////////////////////////////////////////////////////////

  **
  ** Get the command line arguments used to run the fan process
  ** as a readonly List of strings.
  **
  static Str[] args()

  **
  ** Get the environment variables as a case insensitive, readonly
  ** map of Str name/value pairs.  The environment map is initialized
  ** from the following sources from lowest priority to highest priority:
  **   1. shell environment variables
  **   2. Java system properties (Java VM only obviously)
  **   3. {homeDir}/lib/sys.props
  **
  static Str:Str env()

  **
  ** Operating system name as one of the following string constants:
  **   - "win"
  **   - "macosx"
  **   - "linux"
  **   - "aix"
  **   - "solaris"
  **   - "hpux"
  **   - "qnx"
  **
  static Str os()

  **
  ** List of 'arch' names:
  **   - "x86"
  **   - "x86_64"
  **   - "ppc"
  **   - "sparc"
  **   - "ia64"
  **   - "ia64_32"
  **
  static Str arch()

  **
  ** Name of the host platform as a string formatted
  ** as "<os>-<arch>".  See `os` and `arch`.
  **
  static Str platform()

  **
  ** Poll for a platform dependent map of diagnostics name/value
  ** pairs for the current state of the VM.  Java platforms return
  ** key values from the java.lang.management interface.
  **
  static Str:Obj diagnostics()

  **
  ** Run the garbage collector.  No guarantee is made
  ** to what the VM will actually do.
  **
  static Void gc()

  **
  ** Get the local host name of the machine running the
  ** virtual machine process.
  **
  static Str hostName()

  **
  ** Get the user name of the user account used to run the
  ** virtual machine process.
  **
  static Str userName()

  **
  ** Terminate the current virtual machine.
  **
  static Void exit(Int status := 0)

  **
  ** Standard input stream.
  **
  static InStream in()

  **
  ** Standard output stream.
  **
  static OutStream out()

  **
  ** Standard error output stream.
  **
  static OutStream err()

  **
  ** Return the default hash code of `Obj.hash` for the
  ** specified object regardless of whether the object
  ** has overridden the 'hash' method.  If null then
  ** return 0.
  **
  static Int idHash(Obj? obj)

//////////////////////////////////////////////////////////////////////////
// Compiler Utils
//////////////////////////////////////////////////////////////////////////

  **
  ** Compile a script file into a pod and return the first
  ** public type declared in the script file.  If the file
  ** has been previously compiled and hasn't changed, then a
  ** cached type is returned.  If the script contains errors
  ** then the first CompilerErr found is thrown.  The options
  ** available:
  **   - logLevel: the default `LogLevel` to use for logging
  **     the compilation process and errors
  **   - log: the `compiler::CompilerLog` to use for
  **     logging the compilation process and errors
  **   - logOut: an output stream to capture logging
  **   - force: pass 'true' to not use caching, always forces
  **     a recompile
  **
  static Type compile(File f, [Str:Obj]? options := null)

}