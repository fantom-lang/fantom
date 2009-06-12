//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//    12 Jun 09  Andy Frank  Creation
//

using compiler

**
** Initialize the compiler.
**
class Init : JsCompilerStep
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  new make(JsCompiler compiler)
    : super(compiler)
  {
  }

//////////////////////////////////////////////////////////////////////////
// Run
//////////////////////////////////////////////////////////////////////////

  override Void run()
  {
    log.debug("Init")

    // TODO - is the correct behavoir?
    // if compiling script, force
    if (compiler.input.mode == CompilerInputMode.str)
      compiler.force = true

    compiler.output = CompilerOutput()
    compiler.output.mode = compiler.input.output

    // redirect to buf if output is str
    if (compiler.output.mode == CompilerOutputMode.str)
    {
      compiler.buf = Buf()
      compiler.out = compiler.buf.out
    }
  }

}

