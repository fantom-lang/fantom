//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   3 Nov 06  Brian Frank  Creation
//

using compiler

**
** BuildPod is the base class for build scripts used to manage
** building a Fantom source code and resources into a Fantom pod.
**
** See `docTools::Build` for details.
**
abstract class BuildPod : BuildScript
{

//////////////////////////////////////////////////////////////////////////
// Pod Meta-Data
//////////////////////////////////////////////////////////////////////////

  **
  ** Location of "pod.fan" which defines the pod meta-data
  ** needed to compile the pod from source.  By default this
  ** is assumed to be a peer to the build script.
  **
  File? podDef

  **
  ** Programatic name of the pod.  Required to match name in "pod.fan".
  **
  Str? podName

  **
  ** Version of the pod - default is set to @buildVersion.  Required.
  **
  Version? version

  **
  ** The directory to look in for the dependency pod file (and
  ** potentially their recursive dependencies).  If null then we
  ** use the compiler's own pod definitions via reflection (which
  ** is more efficient).  As a general rule you shouldn't mess
  ** with this field - it is used by the 'build' and 'compiler'
  ** build scripts for bootstrap build.
  **
  Uri? dependsDir

  **
  ** Directory to write pod file.  By default it goes into
  ** "Repo.working + fan/lib"
  **
  Uri? outDir

//////////////////////////////////////////////////////////////////////////
// Setup
//////////////////////////////////////////////////////////////////////////

  **
  ** Internal initialization before setup is called
  **
  internal override Void initEnv()
  {
    super.initEnv
    podDef = scriptDir + `pod.fan`
  }

  **
  ** Validate subclass constructor setup required meta-data.
  **
  internal override Void validate()
  {
    if (version == null) version = @buildVersion.val
    if (outDir == null)  outDir  = (Repo.working.home + `lib/fan/`).uri
    ok := true
    ok = ok.and(validateReqField("podName"))
    if (!ok) throw FatalBuildErr.make

    // boot strap checking - ensure that we aren't
    // overwriting sys, build, or compiler
    if (podName == "sys" || podName == "build" ||
        podName == "compiler" || podName == "compilerJava")
    {
      if (Repo.boot.home == devHomeDir)
        throw fatal("Must update @buildDevHome for bootstrap build")
    }
  }

//////////////////////////////////////////////////////////////////////////
// Pod Facets
//////////////////////////////////////////////////////////////////////////

  **
  ** Parse the facets from the "pod.fan" source file.
  **
  PodFacetsParser podFacets()
  {
    if (podFacetsParser == null)
    {
      if (!podDef.exists) throw fatal("podDef does not exist: $podDef")
      try
        podFacetsParser = PodFacetsParser(Loc.makeFile(podDef), podDef.readAllStr).parse
      catch (CompilerErr e)
        throw fatal("$e.msg [$e.loc.toLocStr]")
    }
    return podFacetsParser
  }
  private PodFacetsParser? podFacetsParser

  **
  ** Pod facet `@sys::podDepends`
  **
  once Depend[] podDepends() { podFacets.get("sys::podDepends", false, Depend[]#) ?: Depend[,] }

  **
  ** Pod facet `@sys::podSrcDirs`
  **
  once Uri[]? podSrcDirs() { podFacets.get("sys::podSrcDirs", false, Uri[]#) }

  **
  ** Pod facet `@sys::podResDirs`
  **
  once Uri[]? podResDirs() { podFacets.get("sys::podResDirs", false, Uri[]#) }

  **
  ** Pod facet `@sys::podJavaDirs`
  **
  once Uri[]? podJavaDirs() { podFacets.get("sys::podJavaDirs", false, Uri[]#) }

  **
  ** Pod facet `@sys::podDotnetDirs`
  **
  once Uri[]? podDotnetDirs() { podFacets.get("sys::podDotnetDirs", false, Uri[]#) }

  **
  ** Pod facet `@sys::podJsDirs`
  **
  once Uri[]? podJsDirs() { podFacets.get("sys::podJsDirs", false, Uri[]#) }

  **
  ** Pod facet `@sys::js`
  **
  once Bool podJs() { podFacets.get("sys::js", false) == true }

  **
  ** Pod facet `@sys::nodoc`
  **
  once Bool podNodoc() { podFacets.get("sys::nodoc", false) == true }

//////////////////////////////////////////////////////////////////////////
// BuildScript
//////////////////////////////////////////////////////////////////////////

  **
  ** Default target is `compile`.
  **
  override Target defaultTarget()
  {
    if (podJavaDirs == null && podDotnetDirs == null && !podJs && podJsDirs == null)
      return target("compile")
    else
      return target("full")
  }

//////////////////////////////////////////////////////////////////////////
// Compile
//////////////////////////////////////////////////////////////////////////

  @target="compile fan source into pod"
  virtual Void compile(Bool includeFandocAndSrc := false)
  {
    log.info("compile [$podName]")
    log.indent
    fanc := CompileFan(this)
    fanc.includeDoc = !podNodoc
    fanc.includeSrc = !podNodoc
    fanc.run
    log.unindent
  }

//////////////////////////////////////////////////////////////////////////
// Clean
//////////////////////////////////////////////////////////////////////////

  @target="delete all intermediate and target files"
  virtual Void clean()
  {
    log.info("clean [$podName]")
    log.indent
    Delete(this, libFanDir+"${podName}.pod".toUri).run
    Delete(this, libJavaDir+"${podName}.jar".toUri).run
    Delete(this, libDotnetDir+"${podName}.dll".toUri).run
    Delete(this, libDotnetDir+"${podName}.pdb".toUri).run
    Delete(this, libDir+"tmp/${podName}.dll".toUri).run
    Delete(this, libDir+"tmp/${podName}.pdb".toUri).run
    Delete(this, scriptDir+"temp-java/".toUri).run
    Delete(this, scriptDir+"temp-dotnet/".toUri).run
    log.unindent
  }

//////////////////////////////////////////////////////////////////////////
// JavaNative
//////////////////////////////////////////////////////////////////////////

  @target="build native Java jar file"
  virtual Void javaNative()
  {
    if (podJavaDirs == null) return

    log.info("javaNative [$podName]")
    log.indent

    // env
    jtemp    := scriptDir + `temp-java/`
    jstub    := jtemp + "${podName}.jar".toUri
    jdk      := JdkTask(this)
    javaExe  := jdk.javaExe
    jarExe   := jdk.jarExe
    curPod   := libFanDir + "${podName}.pod".toUri
    curJar   := libJavaDir + "${podName}.jar".toUri
    javaDirs := resolveDirs(podJavaDirs)
    depends  := podDepends

    // if there are no javaDirs we only only stubbing
    stubOnly := javaDirs.isEmpty

    // start with a clean directory
    Delete(this, jtemp).run
    if (!stubOnly) CreateDir(this, jtemp).run

    // stub the pods fan classes into Java classfiles
    // by calling the JStub tool in the jsys runtime
    stubDir := stubOnly ? libJavaDir : jtemp
    Exec(this, [javaExe.osPath,
                     "-cp", (libJavaDir + `sys.jar`).osPath,
                     "-Dfan.home=$Repo.working.home.osPath",
                     "fanx.tools.Jstub",
                     "-d", stubDir.osPath,
                     podName]).run

    // if there are no javaDirs we only only stubbing
    if (stubOnly) return

    // compile
    javac := CompileJava(this)
    javac.outDir = jtemp
    javac.cp.add(jtemp+"${podName}.jar".toUri)
    javac.cpAddExtJars
    depends.each |Depend d| { javac.cp.add(libJavaDir+(d.name+".jar").toUri) }
    javac.src = javaDirs
    javac.run

    // extract stub jar into the temp directory
    Exec(this, [jarExe.osPath, "-xf", jstub.osPath], jtemp).run

    // now we can nuke the stub jar (and manifest)
    Delete(this, jstub).run
    Delete(this, jtemp + `meta-inf/`).run

    // jar everything back up to lib/java/{pod}.jar
    Exec(this, [jarExe.osPath, "cf", curJar.osPath, "-C", jtemp.osPath, "."], jtemp).run

    // append files to the pod zip (we use java's jar tool)
    Exec(this, [jarExe.osPath, "-fu", curPod.osPath, "-C", jtemp.osPath, "."], jtemp).run

    // cleanup temp
    Delete(this, jtemp).run

    log.unindent
  }

//////////////////////////////////////////////////////////////////////////
// DotnetNative
//////////////////////////////////////////////////////////////////////////

  @target="build native .NET assembly"
  virtual Void dotnetNative()
  {
    if (podDotnetDirs == null) return

    if (!isWindows)
    {
      log.info("dotnetNative skipping [$podName]")
      return
    }

    log.info("dotnetNative [$podName]")
    log.indent

    // env
    ntemp := scriptDir + `temp-dotnet/`
    nstub := ntemp + "${podName}.dll".toUri
    nout  := ntemp + "${podName}Native_.dll".toUri
    ndirs := podDotnetDirs
    nlibs := ["${libDotnetDir}sys.dll".toUri, nstub.uri]
    nstubExe := binDir + `nstub`

    // start with a clean directory
    Delete(this, ntemp).run
    CreateDir(this, ntemp).run

    // stub the pods fan classes into Java classfiles
    // by calling the JStub tool in the jsys runtime
    Exec(this, [nstubExe.osPath, "-d", ntemp.osPath, podName]).run

    // compile
    csc := CompileCs(this)
    csc.output = nout
    csc.targetType = "library"
    csc.src  = resolveDirs(ndirs)
    csc.libs = resolveFiles(nlibs)
    csc.run

    // append files to the pod zip (we use java's jar tool)
    jdk    := JdkTask(this)
    jarExe := jdk.jarExe
    curPod := libFanDir + "${podName}.pod".toUri
    Exec(this, [jarExe.osPath, "-fu", curPod.osPath, "-C", ntemp.osPath,
      "${podName}Native_.dll", "${podName}Native_.pdb"], ntemp).run

    // cleanup temp
    Delete(this, ntemp).run

    log.unindent
  }

//////////////////////////////////////////////////////////////////////////
// JavaScript
//////////////////////////////////////////////////////////////////////////

  @target="compile Fantom source to JavaScript"
  virtual Void js()
  {
    if (!podJs) return

    log.info("js [$podName]")
    log.indent

    // env
    nativeDirs := resolveDirs(podJsDirs)
    jsTemp := scriptDir + `temp-js/`

    // start with a clean directory
    Delete(this, jsTemp).run
    CreateDir(this, jsTemp).run

    // compile javascript
    out := jsTemp.createFile("${podName}.js").out
    jsc := build::CompileJs(this)
    jsc.out = out
    jsc.nativeDirs = nativeDirs
    jsc.run
    out.close

    // append files to the pod zip (we use java's jar tool)
    jdk    := JdkTask(this)
    jarExe := jdk.jarExe
    curPod := libFanDir + "${podName}.pod".toUri
    Exec(this, [jarExe.osPath, "-fu", curPod.osPath, "-C", jsTemp.osPath,
      "${podName}.js"], jsTemp).run

    // cleanup temp
    Delete(this, jsTemp).run

    log.unindent
  }

//////////////////////////////////////////////////////////////////////////
// CompileAll
//////////////////////////////////////////////////////////////////////////

  @target="compile+native (no fandoc+src)"
  virtual Void compileAll()
  {
    compile(false)
    javaNative
    dotnetNative
    js
  }

//////////////////////////////////////////////////////////////////////////
// Full
//////////////////////////////////////////////////////////////////////////

  @target="clean+compile+native (with doc+src)"
  virtual Void full()
  {
    clean
    compile(true)
    javaNative
    dotnetNative
    js
  }

//////////////////////////////////////////////////////////////////////////
// Doc
//////////////////////////////////////////////////////////////////////////

  @target="build fandoc HTML docs"
  virtual Void doc()
  {
    // use docCompiler reflectively
    docCompiler := Type.find("docCompiler::Main").make
    docCompiler->d    = devHomeDir + `doc/`
    docCompiler->src  = scriptDir
    docCompiler->pods = [podName]
    Int r := docCompiler->run
    if (r != 0) fatal("Cannot doc compiler '$podName'")
  }

//////////////////////////////////////////////////////////////////////////
// Test
//////////////////////////////////////////////////////////////////////////

  @target="run fant for specified pod"
  virtual Void test()
  {
    log.info("test [$podName]")
    log.indent

    fant := binDir + "fant$exeExt".toUri
    Exec(this, [fant.osPath, podName]).run

    log.unindent
  }

}