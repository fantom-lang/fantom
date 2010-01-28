//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//    9 Jan 06  Brian Frank  Creation
//   27 Jan 10  Brian Frank  Rename Sys to Env
//

**
** Env defines a pluggable class used boot and manage a Fantom
** runtime environment.
**
abstract const class Env
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  **
  ** Get the current runtime environment
  **
  static Env cur()

  **
  ** Subclasses are constructed from a parent environment.
  ** Default implementation of all virtual methods is to
  ** delegate to the parent environment.
  **
  protected new make(Env parent := Env.cur)

//////////////////////////////////////////////////////////////////////////
// Non-Virtuals
//////////////////////////////////////////////////////////////////////////

  **
  ** Get the parent environment or null if this is the bootstrap
  ** environment.  All virtual methods delegate to their parent by
  ** default.
  **
  Env? parent()

  **
  ** Name of the host platform as a string formatted
  ** as "<os>-<arch>".  See `os` and `arch`.
  **
  Str platform()

  **
  ** Operating system name as one of the following constants:
  **   - "win32"
  **   - "macosx"
  **   - "linux"
  **   - "aix"
  **   - "solaris"
  **   - "hpux"
  **   - "qnx"
  **
  Str os()

  **
  ** Microprocessor architecture name as one of the following constants:
  **   - "x86"
  **   - "x86_64"
  **   - "ppc"
  **   - "sparc"
  **   - "ia64"
  **   - "ia64_32"
  **
  Str arch()

  **
  ** Virtual machine runtime as one of the following constants:
  **   - "java"
  **   - "dotnet"
  **   - "js"
  **
  Str runtime()

  **
  ** Return the default hash code of `Obj.hash` for the
  ** specified object regardless of whether the object
  ** has overridden the 'hash' method.  If null then
  ** return 0.
  **
  Int idHash(Obj? obj)

//////////////////////////////////////////////////////////////////////////
// Virtuals
//////////////////////////////////////////////////////////////////////////

  **
  ** Get the command line arguments used to run the fan process
  ** as an immutable List of strings.
  **
  virtual Str[] args()

  **
  ** Get the environment variables as a case insensitive, immutable
  ** map of Str name/value pairs.  The environment map is initialized
  ** from the following sources from lowest priority to highest priority:
  **   1. shell environment variables
  **   2. Java system properties (Java VM only obviously)
  **   3. {homeDir}/lib/sys.props
  **
  virtual Str:Str vars()

  **
  ** Poll for a platform dependent map of diagnostics name/value
  ** pairs for the current state of the VM.  Java platforms return
  ** key values from the 'java.lang.management' interface.
  **
  virtual Str:Obj diagnostics()

  **
  ** Run the garbage collector.  No guarantee is made
  ** to what the VM will actually do.
  **
  virtual Void gc()

  **
  ** Get the local host name of the machine running the
  ** virtual machine process.
  **
  virtual Str host()

  **
  ** Get the user name of the user account used to run the
  ** virtual machine process.
  **
  virtual Str user()

  **
  ** Terminate the current virtual machine.
  **
  virtual Void exit(Int status := 0)

  **
  ** Standard input stream.
  **
  virtual InStream in()

  **
  ** Standard output stream.
  **
  virtual OutStream out()

  **
  ** Standard error output stream.
  **
  virtual OutStream err()

  **
  ** Get the home directory of Fantom installation.
  **
  virtual File homeDir()

  **
  ** Get the working directory to use for saving compiled
  ** pods and configuration information.
  **
  virtual File workDir()

  **
  ** Get the temp directory to use for scratch files.
  **
  virtual File tempDir()

//////////////////////////////////////////////////////////////////////////
// Resolution
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
  virtual Type compileScript(File f, [Str:Obj]? options := null)

  **
  ** Find a file in the environment using a relative path such
  ** as "etc/foo/config.props".  If the URI is not relative then
  ** throw ArgErr.  If the file is not found in the environment
  ** then throw IOErr or return null based on checked flag.  If
  ** `findAllFiles` would return multiple matches, then this method
  ** should always return the file with the highest priority.
  **
  virtual File? findFile(Uri uri, Bool checked := true)

  **
  ** Find all the files in the environment which match a relative
  ** path such as "etc/foo/config.props".  It is possible to have
  ** multiple matches if the environment uses a search path model.
  ** If the list contains more than one item, then the first file
  ** has the highest priority and the last item has the lowest
  ** priority.  If the URI is not relative then throw ArgErr.
  ** Return empty list if the file is not found in environment.
  **
  virtual File[] findAllFiles(Uri uri)

  **
  ** Return a merged key/value map of all the prop files referenced
  ** by the uri via `findAllFiles`.  The files are parsed using
  ** `InStream.readProps` and merged according to their priority
  ** order (first file overwrites keys in other files).
  **
  ** The map is cached so that subsequent calls for the same uri
  ** doesn't require accessing the file system again.  The 'maxAge'
  ** parameter specifies the tolerance accepted before a cache
  ** refresh is performed to check if any of the files have been
  ** modified.
  **
  Str:Str props(Uri uri, Duration maxAge := 1min)

}

**************************************************************************
** BootEnv
**************************************************************************

internal const class BootEnv : Env {}


