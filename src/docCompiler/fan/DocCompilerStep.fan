//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   17 Dec 09  Brian Frank  Creation
//

**
** DocCompilerStep
**
class DocCompilerStep : DocCompilerSupport
{

  **
  ** Constructor takes the associated Compiler
  **
  new make(DocCompiler compiler)
  {
    this.compiler = compiler
  }

  **
  ** Parent compiler instance
  **
  override DocCompiler compiler

}