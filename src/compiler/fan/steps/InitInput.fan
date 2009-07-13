//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   5 Jun 06  Brian Frank  Creation
//

**
** InitInput is responsible:
**   - verifies the CompilerInput instance
**   - checks the depends dir
**   - constructs the appropiate CNamespace
**   - initializes Comiler.pod with a PodDef
**   - tokenizes the source code from file or string input
**
class InitInput : CompilerStep
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  **
  ** Constructor takes the associated Compiler
  **
  new make(Compiler compiler)
    : super(compiler)
  {
    loc = compiler.input.inputLoc
  }

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  **
  ** Run the step
  **
  override Void run()
  {
    // validate input
    input := compiler.input
    try
    {
      input.validate
    }
    catch (CompilerErr err)
    {
      throw errReport(err)
    }

    // figure out where our depends are coming from
    checkDependsDir(input)

    // create the appropiate namespace
    if (input.dependsDir == null)
      compiler.ns = ReflectNamespace(compiler)
    else
      compiler.ns = FPodNamespace(compiler, input.dependsDir)

    // init pod
    podName := input.podName
    compiler.pod = PodDef.make(ns, Location.make(podName), podName)
    compiler.isSys = podName == "sys"

    // process intput into tokens
    switch (input.mode)
    {
      case CompilerInputMode.str:
        Tokenize(compiler).runSource(input.srcStrLocation, input.srcStr)
        if (input.symbolsStr != null)
          Tokenize(compiler).runSource(Location("symbols.fan"), input.symbolsStr)

      case CompilerInputMode.file:
        FindSourceFiles(compiler).run
        Tokenize(compiler).run

      default:
        throw err("Unknown input mode $input.mode", null)
    }
  }

  **
  ** If depends home is not null, then check it out.
  **
  private Void checkDependsDir(CompilerInput input)
  {
    // if null then we are using
    // compiler's own pods via reflection
    dir := input.dependsDir
    if (dir == null) return

    // check that it isn't the same as Sys.homeDir, in
    // which we're better off using reflection
    if (dir.normalize == (Sys.homeDir + `lib/fan/`).normalize)
    {
      input.dependsDir = null
      return
    }

    // check that fan pods directory exists
    if (!dir.exists) throw err("Invalid dependsHomeDir: $dir", loc)

    // save it away
    input.dependsDir = dir
    log.info("Depends [$dir]")
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private Location loc
}