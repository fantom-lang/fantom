//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//    9 Dec 08  Andy Frank  Creation
//

using compiler

**
** Fantom source to JavaScript source compiler.
**
abstract class JsCompilerStep : CompilerStep
{

  new make(JsCompiler c)
    : super(c)
  {
    this.compiler = c
  }

  override JsCompiler compiler

}