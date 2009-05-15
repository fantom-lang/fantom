//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   4 Nov 06  Brian Frank  Creation
//

**
** CompilerInput encapsulates all the input needed run the compiler.
** The compiler can be run in one of two modes - file or str.  In
** file mode the source code and resource files are read from the
** file system.  In str mode we compile a single source file from
** an in-memory string.
**
class CompilerInput
{

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  **
  ** Location to use for reporting errors associated with the input
  ** itself - typically this is mapped to the build script.
  **
  Location inputLoc := Location.make("CompilerInput")

  **
  ** Required name of output pod
  **
  Str? podName

  **
  ** Flag to indicate if we are are compiling a script.  Scripts
  ** don't require explicit depends and can import any type via the
  ** using statement or with qualified type names.
  **
  Bool isScript := false

  **
  ** Version to include in ouput pod's manifest.
  **
  Version? version

  **
  ** Description to include in output pod's manifest.
  **
  Str? description

  **
  ** User defined pod level facets.
  **
  Str:Obj podFacets := Str:Obj[:]

  **
  ** List of this pod's dependencies used for both the
  ** compiler checking and output in the pod's manifest.
  **
  Depend[] depends := Depend[,]

  **
  ** The directory to look in for the dependency pod file (and
  ** potentially their recursive dependencies).  If null then we
  ** use the compiler's own pod definitions via reflection (which
  ** is more efficient).
  **
  File? dependsDir := null

  **
  ** What type of output should be generated - the compiler
  ** can be used to generate a transient in-memory pod or
  ** to write out a pod zip file to disk.
  **
  CompilerOutputMode? output := null

  **
  ** Log used for reporting compile status
  **
  CompilerLog log := CompilerLog.make

  **
  ** Output directory to write pod to, defaults to the
  ** current runtime's lib directory
  **
  File outDir := Sys.homeDir + `lib/fan/`

  **
  ** Include fandoc in output pod, default is false
  **
  Bool includeDoc := false

  **
  ** Include source code in output pod, default is false
  **
  Bool includeSrc := false

  **
  ** Is this compile process being run inside a test, default is false
  **
  Bool isTest := false

  **
  ** If set to true, then disassembled fcode is dumped to 'log.out'.
  **
  Bool fcodeDump := false

  **
  ** This mode determines whether the source code is input
  ** from the file system or from an in-memory string.
  **
  CompilerInputMode? mode := null

//////////////////////////////////////////////////////////////////////////
// CompilerInputMode.file
//////////////////////////////////////////////////////////////////////////

  **
  ** Root directory of source tree - this directory is used to create
  ** the relative paths of the resource files in the pod zip.
  **
  File? homeDir

  **
  ** List of directories containing fan source files (file mode only)
  **
  File[]? srcDirs

  **
  ** Optional list of directories containing resources files to
  ** include in the pod zip (file mode only)
  **
  File[] resDirs := File[,]

//////////////////////////////////////////////////////////////////////////
// CompilerInputMode.str
//////////////////////////////////////////////////////////////////////////

  **
  ** Fan source code to compile (str mode only)
  **
  Str? srcStr

  **
  ** Location to use for SourceFile facet (str mode only)
  **
  Location? srcStrLocation

//////////////////////////////////////////////////////////////////////////
// Validation
//////////////////////////////////////////////////////////////////////////

  **
  ** Validate the CompilerInput is correctly
  ** configured, throw CompilerErr is not.
  **
  internal Void validate()
  {
    validateReqField("podName")
    validateReqField("version")
    validateReqField("description")
    validateReqField("depends")
    validateReqField("output")
    validateReqField("outDir")
    validateReqField("includeDoc")
    validateReqField("includeSrc")
    validateReqField("isTest")
    validateReqField("mode")
    switch (mode)
    {
      case CompilerInputMode.file:
        validateReqField("homeDir")
        validateReqField("srcDirs")
        validateReqField("resDirs")
      case CompilerInputMode.str:
        validateReqField("srcStr")
        validateReqField("srcStrLocation")
    }
  }

  **
  ** Check that the specified field is non-null, if not
  ** then log an error and return false.
  **
  private Void validateReqField(Str field)
  {
    val := type.field(field).get(this)
    if (val == null)
      throw ArgErr("CompilerInput.${field} not set", null)
  }
}

**************************************************************************
** CompilerInputMode
**************************************************************************

**
** Input source from the file system
**
enum CompilerInputMode
{
  file,
  str
}