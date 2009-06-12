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
  }

//////////////////////////////////////////////////////////////////////////
// Pipeline
//////////////////////////////////////////////////////////////////////////

  override Void backend()
  {
    // TODO: move into steps

    // if compiling script, force
    if (input.mode == CompilerInputMode.str)
      force = true

    output = CompilerOutput()
    output.mode = input.output

    Buf? buf
    toStr := output.mode == CompilerOutputMode.str
    if (toStr) { buf = Buf(); out = buf.out }

    Translate(this).run

    if (toStr) output.str = buf.flip.in.readAllStr
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  OutStream? out       // all js gets written to this stream
  File[]? nativeDirs   // dirs of native js to include in output
  Bool force := false  // ignore @javascript facet and compile all types

}