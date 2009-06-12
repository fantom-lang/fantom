//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//    9 Dec 08  Andy Frank  Creation
//

using compiler

**
** Fan source to Javascript source compiler.
**
class JsCompiler : Compiler
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  new make(CompilerInput input)
    : super(input)
  {
    this.output = CompilerOutput()
    this.nativeDirs = File[,]
  }

//////////////////////////////////////////////////////////////////////////
// Pipeline
//////////////////////////////////////////////////////////////////////////

  override Void backend()
  {
    Translate(this).run
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  **
  ** Directory to write compiled Javascript source files to
  **
  File? outDir

  **
  ** Directories of native javascript files to include in output.
  **
  File[] nativeDirs

  **
  ** Force all types and slots to be compiled even if they do
  ** have the @javascript facet.
  **
  Bool force := false

}