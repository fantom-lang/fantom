//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   5 May 07  Brian Frank  Creation
//

using compiler

**
** Init prepares the output directory.
**
class Init : DocCompilerStep
{

  new make(DocCompiler compiler)
    : super(compiler)
  {
  }

  Void run()
  {
    dir := compiler.outDir + `${compiler.pod.name}/`

    log.debug("  Delete [$dir]")
    dir.delete

    log.debug("  Create [$dir]")
    dir.create

    compiler.podOutDir = dir
  }
}