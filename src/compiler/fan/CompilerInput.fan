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
  Location inputLoc := Location("CompilerInput")

  **
  ** Name of output pod - required for scripts and str mode.
  ** For pods this is defined via podDef location of "pod.fan".
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
  ** Location of "pod.fan" which defines the pod meta-data
  ** needed to compile the pod from source.
  **
  File? podDef

//////////////////////////////////////////////////////////////////////////
// CompilerInputMode.str
//////////////////////////////////////////////////////////////////////////

  **
  ** Fan source code to compile (str mode only)
  **
  Str? srcStr

  **
  ** Fan source code for "pod.fan" (str mode only)
  ** For testing only!!!
  **
  @nodoc Str? podStr

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
    validateReqField("version")
    validateReqField("output")
    validateReqField("outDir")
    validateReqField("includeDoc")
    validateReqField("includeSrc")
    validateReqField("isTest")
    validateReqField("mode")
    validateReqField("podName")
    switch (mode)
    {
      case CompilerInputMode.file:
        validateReqField("podDef")
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