//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//    12 Jun 09  Andy Frank  Creation
//

using compiler

**
** Cleanup after compiler.
**
class Cleanup : JsCompilerStep
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
    log.debug("Cleanup")

    // if str target, copy buf contents back into output
    if (compiler.output.mode == CompilerOutputMode.str)
      compiler.output.str = compiler.buf.flip.in.readAllStr
  }

}

