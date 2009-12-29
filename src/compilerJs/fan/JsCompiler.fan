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

  override Void frontend()
  {
    InitInput(this).run
    Tokenize(this).run
    ResolveDepends(this).run
    ScanForUsingsAndTypes(this).run
    ResolveImports(this).run
    Parse(this).run
    OrderByInheritance(this).run
    CheckInheritance(this).run
    Inherit(this).run
    DefaultCtor(this).run
    InitEnum(this).run
    InitClosures(this).run
    Normalize(this).run
    ResolveExpr(this).run
    CheckErrors(this).run
    CheckParamDefs(this).run
    //ClosureVars(this).run
    ClosureToImmutable(this).run
    ConstChecks(this).run
  }

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
  JsPod? jsPod                   // FindTypes
  //JsType[]? jsTypes              // JsTypes

}