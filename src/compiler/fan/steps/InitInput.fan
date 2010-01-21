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
    input = compiler.input
  }

//////////////////////////////////////////////////////////////////////////
// Run
//////////////////////////////////////////////////////////////////////////

  **
  ** Run the step
  **
  override Void run()
  {
    validateInput
    initPodFacets
    initNamespace
    initPod
    initDepends
    initFiles
  }

//////////////////////////////////////////////////////////////////////////
// Validate Input
//////////////////////////////////////////////////////////////////////////

  **
  ** Validate that all the required input fields are set.
  **
  private Void validateInput()
  {
    try
      input.validate
    catch (CompilerErr err)
      throw errReport(err)
  }

//////////////////////////////////////////////////////////////////////////
// Pod Facets
//////////////////////////////////////////////////////////////////////////

  **
  ** Init this step's podFacets field
  **
  private Void initPodFacets()
  {
    switch (input.mode)
    {
      case CompilerInputMode.str:  initPodFacetsStrMode
      case CompilerInputMode.file: initPodFacetsFileMode
      default: throw err("Unknown input mode $input.mode", null)
    }
  }

  private Void initPodFacetsStrMode()
  {
    // if "pod.fan" as passed in then parse it
    if (input.podStr != null)
      parsePodFacets(Location("pod.fan"), input.podStr)
  }

  private Void initPodFacetsFileMode()
  {
    // verify podDef exists
    podDef := input.podDef
    if (!podDef.exists) throw err("Invalid podDef: $podDef", null)

    // parse pod facets
    loc := Location.makeFile(podDef)
    parsePodFacets(loc, podDef.readAllStr)
  }

  private Void parsePodFacets(Location loc, Str src)
  {
    try
      podFacets = PodFacetsParser(loc, src).parse
    catch (CompilerErr e)
      throw errReport(e)
    catch (Err e)
      throw errReport(CompilerErr("Cannot parse pod facets: $e", loc, e))
  }

  private Obj? podFacet(Str qname, Obj def)
  {
    if (podFacets == null) return def
    try
      return podFacets.get(qname, false, def.typeof) ?: def
    catch (CompilerErr e)
      throw errReport(e)
  }

//////////////////////////////////////////////////////////////////////////
// Init Namespace
//////////////////////////////////////////////////////////////////////////

  **
  ** Init the compiler.ns with an appropriate CNamespace
  **
  private Void initNamespace()
  {
    checkDependsDir
    if (input.dependsDir == null)
      compiler.ns = ReflectNamespace(compiler)
    else
      compiler.ns = FPodNamespace(compiler, input.dependsDir)
  }

  **
  ** If dependsDir is not null, then check it out.
  ** This is used for bootstrap to use fcode instead of
  ** reflection for dependencies.
  **
  private Void checkDependsDir()
  {
    // if null then we are using
    // compiler's own pods via reflection
    dir := input.dependsDir
    if (dir == null) return

    // check that it isn't the same as boot repo, in
    // which case we're better off using reflection
    if (dir.normalize == (Repo.boot.home + `lib/fan/`).normalize)
    {
      input.dependsDir = null
      return
    }

    // check that fan pods directory exists
    if (!dir.exists) throw err("Invalid dependsDir: $dir", loc)

    // save it away
    input.dependsDir = dir
    log.info("Depends [$dir]")
  }

//////////////////////////////////////////////////////////////////////////
// Init Pod
//////////////////////////////////////////////////////////////////////////

  **
  ** Init the compiler.pod with PodDef
  **
  private Void initPod()
  {
    // verify "pod.fan" matches podName passed in
    podName := input.podName
    if (podFacets != null && podName!= podFacets.podName)
      throw err("CompilerInput.podName does not match 'pod.fan': $podName != $podFacets.podName", podFacets.location)

    // init compiler fields
    compiler.pod   = PodDef(ns, Location(podName), podName)
    compiler.isSys = podName == "sys"
  }

//////////////////////////////////////////////////////////////////////////
// Init Depends
//////////////////////////////////////////////////////////////////////////

  **
  ** Init the compiler.depends with list of Depends
  **
  private Void initDepends()
  {
    // depends are specified with @podDepends facet
    compiler.depends = podFacet("sys::podDepends", Depend[,])
  }

//////////////////////////////////////////////////////////////////////////
// Init Source and Resource Files
//////////////////////////////////////////////////////////////////////////

  **
  ** Init the compiler's srcFiles and resFiles field (file mode only)
  **
  private Void initFiles()
  {
    if (input.mode !== CompilerInputMode.file) return

    // map pod facets to src/res files
    compiler.srcFiles = findFiles("sys::podSrcDirs", "fan")
    compiler.resFiles = findFiles("sys::podResDirs", null)

    // "pod.fan" is always implicit include in source
    compiler.srcFiles.insert(0, input.podDef)

    if (compiler.srcFiles.isEmpty && compiler.resFiles.isEmpty)
      throw err("No fan source files found", null)

    // map sure no duplicate names in srcFiles
    map := Str:File[:]
    compiler.srcFiles.each |file|
    {
      if (map[file.name] != null)
        throw err("Cannot have source files with duplicate names: $file.name", Location.makeFile(file))
      map[file.name] = file
    }

    log.info("FindSourceFiles [${compiler.srcFiles.size} files]")
  }

  private File[] findFiles(Str qname, Str? ext)
  {
    base := input.podDef
    acc := File[,]
    uris := (Uri[])podFacet(qname, Uri[,])
    uris.each |uri|
    {
      dir := base + uri
      if (!dir.isDir) throw err("Invalid directory", Location.makeFile(dir))
      dir.list.each |file|
      {
        if (file.isDir) return
        if (ext == null || file.ext == ext) acc.add(file)
      }
    }
    return acc
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private Location loc                // ctor
  private CompilerInput input         // ctor
  private PodFacetsParser? podFacets  // parsePodFacets

}