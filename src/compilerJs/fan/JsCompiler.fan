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
    init
    jsPod.write(JsWriter(out))
    cleanup
  }

//////////////////////////////////////////////////////////////////////////
// Steps
//////////////////////////////////////////////////////////////////////////

  Void init()
  {
    // TODO - is the correct behavoir?
    // if compiling script, force
    if (input.mode == CompilerInputMode.str) force = true
    output = CompilerOutput()
    output.mode = input.output

    // redirect to buf if output is str
    if (output.mode == CompilerOutputMode.str)
    {
      buf = Buf()
      out = buf.out
    }

    // find natives to compile
    natives = Str:File[:]
    if (nativeDirs != null) {
      nativeDirs.each |dir| {
        dir.listFiles.each |f| { natives[f.name] = f }
      }
    }

    // define pod
    jsPod = JsPod(CompilerSupport(this), pod, types)
  }

  Void cleanup()
  {
    // if str target, copy buf contents back into output
    if (output.mode == CompilerOutputMode.str)
      output.str = buf.flip.in.readAllStr
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  OutStream? out        // output of compiler
  Buf? buf              // buf output for str output
  Bool force := false   // force compile all types
  File[]? nativeDirs    // dir to look for js natives
  [Str:File]? natives   // native filename map
  JsPod? jsPod          // JsPod AST

}