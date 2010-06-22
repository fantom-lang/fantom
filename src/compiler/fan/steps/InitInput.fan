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
// Init Namespace
//////////////////////////////////////////////////////////////////////////

  **
  ** Init the compiler.ns with an appropriate CNamespace
  **
  private Void initNamespace()
  {
    compiler.ns = input.ns
    input.ns.c = compiler
  }

//////////////////////////////////////////////////////////////////////////
// Init Pod
//////////////////////////////////////////////////////////////////////////

  **
  ** Init 'compiler.pod' with PodDef
  **
  private Void initPod()
  {
    meta := Str:Str[:] { ordered = true }
    meta["pod.name"]       = input.podName
    meta["pod.version"]    = input.version.toStr
    meta["pod.depends"]    = input.depends.join(";")
    meta["pod.summary"]    = input.summary
    meta["pod.isScript"]   = input.isScript.toStr
    meta["fcode.version"]  = FConst.FCodeVersion
    meta["build.host"]     = Env.cur.host
    meta["build.user"]     = Env.cur.user
    meta["build.time"]     = DateTime.now.toStr
    meta["build.compiler"] = typeof.pod.version.toStr
    meta["build.platform"] = Env.cur.platform
    meta.addAll(input.meta)

    pod := PodDef(ns, input.inputLoc, input.podName)
    pod.meta  = meta
    pod.index = input.index

    compiler.pod = pod
    compiler.isSys = pod.name == "sys"
  }

//////////////////////////////////////////////////////////////////////////
// Init Depends
//////////////////////////////////////////////////////////////////////////

  **
  ** Init the compiler.depends with list of Depends
  **
  private Void initDepends()
  {
    compiler.depends = input.depends
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
    compiler.srcFiles = findFiles(input.srcFiles, "fan")
    compiler.resFiles = findFiles(input.resFiles, null)
    compiler.jsFiles  = findFiles(input.jsFiles,  "js")

    if (compiler.srcFiles.isEmpty && compiler.resFiles.isEmpty)
      throw err("No fan source files found", null)

    // map sure no duplicate names in srcFiles
    map := Str:File[:]
    compiler.srcFiles.each |file|
    {
      if (map[file.name] != null)
        throw err("Cannot have source files with duplicate names: $file.name", Loc.makeFile(file))
      map[file.name] = file
    }

    log.info("FindSourceFiles [${compiler.srcFiles.size} files]")
  }

  private File[] findFiles(Uri[]? uris, Str? ext)
  {
    base := input.baseDir
    acc := File[,]
    uris?.each |uri|
    {
      f := base + uri
      if (!f.exists) throw err("Invalid file or directory", Loc.makeFile(f))
      if (f.isDir)
      {
        f.list.each |kid|
        {
          if (kid.isDir) return
          if (ext == null || kid.ext == ext) acc.add(kid)
        }
      }
      else
      {
        acc.add(f)
      }
    }
    return acc
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private Loc loc                // ctor
  private CompilerInput input    // ctor

}