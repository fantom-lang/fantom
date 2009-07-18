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

// TODO-SYM
podDef := compiler.input.podDef
if (podDef != null || compiler.input.podStr != null)
{
  if (podDef != null && !podDef.exists) throw err("podDef does not exist", loc)
  loc := podDef == null ? Location.make("podStr") : Location.makeFile(podDef)
  str := podDef == null ? compiler.input.podStr : podDef.readAllStr
  try
  {
    podFacets := PodFacetsParser(loc, str).parse
    compiler.depends = podFacets.get("sys::podDepends", false, Depend[]#) ?: Depend[,]
    compiler.srcDirs = toFiles(podFacets.get("sys::podSrcDirs", false, Uri[]#))
    compiler.resDirs = toFiles(podFacets.get("sys::podResDirs", false, Uri[]#))
    if (podDef != null)
      compiler.input.podName = podFacets.podName
  }
  catch (CompilerErr e) throw errReport(e)
  catch (Err e) { e.trace; throw errReport(CompilerErr("Cannot parse pod facets", loc, e)) }
}

    // create the appropiate namespace
    if (input.dependsDir == null)
      compiler.ns = ReflectNamespace(compiler)
    else
      compiler.ns = FPodNamespace(compiler, input.dependsDir)

    // init pod
    podName := input.podName
    compiler.pod = PodDef(ns, Location(podName), podName)
    compiler.isSys = podName == "sys"

    // process intput into tokens
    switch (input.mode)
    {
      case CompilerInputMode.str:
        Tokenize(compiler).runSource(input.srcStrLocation, input.srcStr)
        if (input.podStr != null)
          Tokenize(compiler).runSource(Location("pod.fan"), input.podStr)

      case CompilerInputMode.file:
        FindSourceFiles(compiler).run
        Tokenize(compiler).run

      default:
        throw err("Unknown input mode $input.mode", null)
    }
  }

// TODO-SYM
private File[] toFiles(Uri[]? uris)
{
  if (uris == null || uris.isEmpty) return File[,]
  homeDir := compiler.input.podDef.parent
  return uris.map |uri->File| { homeDir + uri }
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