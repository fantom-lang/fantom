//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   5 Jun 06  Brian Frank  Creation
//

**
** Tokenize is responsible for parsing all the source files into a
** a list of tokens.  Each source file is mapped to a CompilationUnit
** and stored in the PodDef.units field:
**   Compiler.srcFiles -> Compiler.pod.units
**
** During the standard pipeline this step is called by the InitInput step.
**
class Tokenize : CompilerStep
{

  new make(Compiler compiler)
    : super(compiler)
  {
    input = compiler.input
  }

  override Void run()
  {
    log.debug("Tokenize")
    switch (input.mode)
    {
      case CompilerInputMode.str:  runStrMode
      case CompilerInputMode.file: runFileMode
      default: throw UnsupportedErr()
    }
  }

  private Void runStrMode()
  {
    if (input.podStr != null) tokenize(Location("pod.fan"), input.podStr)
    tokenize(input.srcStrLocation, input.srcStr)
  }

  private Void runFileMode()
  {
    compiler.srcFiles.each |file|
    {
      location := Location.makeFile(file)
      try
      {
        src := file.readAllStr
        tokenize(location, src)
      }
      catch (CompilerErr err)
      {
        throw err
      }
      catch (Err e)
      {
        if (file.exists)
          throw err("Cannot read source file: $e", location)
        else
          throw err("Source file not found", location)
      }
    }
  }

  CompilationUnit tokenize(Location location, Str src)
  {
    unit := CompilationUnit(location, pod)
    tokenizer := Tokenizer(compiler, location, src, input.includeDoc)
    unit.tokens = tokenizer.tokenize
    pod.units.add(unit)
    return unit
  }

  CompilerInput input
}