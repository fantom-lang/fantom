//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//    9 Dec 08  Andy Frank  Creation
//

using compiler

**
** Fan source to JavaScript source compiler.
**
class JsCompiler : Compiler
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  new make(CompilerInput input)
    : super(input)
  {
  }

//////////////////////////////////////////////////////////////////////////
// Pipeline
//////////////////////////////////////////////////////////////////////////

  override Void backend()
  {
    Init(this).run
    FindTypes(this).run
    Translate(this).run
    Cleanup(this).run
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  OutStream? out                 // output of compiler
  Buf? buf                       // Init/Cleanup
  Bool force := false            // FindTypes; force compile all types
  TypeDef[]? toCompile           // FindTypes
  TypeDef[] synth := TypeDef[,]  // FindTypes
  File[]? nativeDirs             // FindTypes; dir to look for js natives
  [Str:File]? natives            // FindTypes


}