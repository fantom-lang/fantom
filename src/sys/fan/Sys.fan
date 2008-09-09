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
// Namespace
//////////////////////////////////////////////////////////////////////////

  **
  ** Get the namespace instance which manages the specified
  ** uri, or if uri is omitted, then get the root namespace.
  **
  static Namespace ns(Uri uri := null)

  **
  ** Mount a namespace under the specified Uri.  All requests
  ** to process uris contained by the specified uri are routed
  ** to the namespace instance for processing.  Throw ArgErr if
  ** the uri is already or mounted by another namespace.  Throw
  ** ArgErr if the uri isn't path absolute, has a query, or has
  ** fragment.
  **
  static Void mount(Uri uri, Namespace ns)

  **
  ** Unmount a namespace which was previously mounted by the
  ** `mount` method.  Throw UnresolvedErr is uri doesn't directly
  ** map to a mounted namespace.
  **
  static Void unmount(Uri uri)

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
  ** The following environment variables are always available:
  **   - os.name: name of the host operating system
  **   - os.version: version of the host operating system
  **
  static Str:Str env()

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
  ** Get the fan installation home directory.
  **
  static File homeDir()

  **
  ** Get the application home directory.  The appDir is
  ** automatically exposed into the namespace as part
  ** of the root Resource:
  **   - In 'fand' this is the app directory used to
  **     boot the namespace (TODO - revisit this)
  **   - In 'fant' this is the test directory.
  **   - In other VMs it is the current working directory.
  **
  static File appDir()

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
  ** Standard output stream.
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
  static Int idHash(Obj obj)

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
  **   - force: pass 'true' to not use caching, always forces
  **     a recompile
  **
  static Type compile(File f, Str:Obj options := null)

}