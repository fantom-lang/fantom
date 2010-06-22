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
// Env
//////////////////////////////////////////////////////////////////////////

  **
  ** Required name of the pod.
  **
  Str? podName := null

  **
  ** Required summary description of pod.
  **
  Str? summary := null

  **
  ** Version of the pod - default is set to `config` prop 'buildVersion'.
  **
  Version version := Version(config("buildVersion", "0"))

  **
  ** List of dependencies for pod formatted as `sys::Depend`.
  **
  Str[] depends := Str[,]

  **
  ** Pod meta-data name/value pairs to compile into pod.  See `sys::Pod.meta`.
  **
  Str:Str meta := Str:Str[:] { ordered = true }

  **
  ** Pod index name/value pairs to compile into pod.  See `sys::Env.index`.
  ** The index values can be a single Str or a Str[] if there are
  ** multiple values mapped to one key.
  **
  Str:Obj index := Str:Obj[:]

  **
  ** Indicates if if fandoc API should be included in the documentation.
  ** By default API *is* included.
  **
  Bool docApi := true

  **
  ** Indicates if if source code should be included in the documentation.
  ** By default source code it *not* included.
  **
  Bool docSrc := false

  **
  ** List of Uris relative to build script of directories containing
  ** the Fan source files to compile.
  **
  Uri[]? srcDirs

  **
  ** List of Uris relative to build script of directories of resources
  ** files to package into pod zip file.  Optional.
  **
  Uri[]? resDirs

  **
  ** List of Uris relative to build script of directories containing
  ** the Java source files to compile for Java native methods.
  **
  Uri[]? javaDirs

  **
  ** List of Uris relative to build script of directories containing
  ** the C# source files to compile for .NET native methods.
  **
  Uri[]? dotnetDirs

  **
  ** List of Uris relative to build script of directories containing
  ** the JavaScript source files to compile for JavaScript native methods.
  **
  Uri[]? jsDirs

  **
  ** The directory to look in for the dependency pod file (and
  ** potentially their recursive dependencies).  If null then we
  ** use the compiler's own pod definitions via reflection (which
  ** is more efficient).  As a general rule you shouldn't mess
  ** with this field - it is used by the 'build' and 'compiler'
  ** build scripts for bootstrap build.
  **
  Uri? dependsDir := null

  **
  ** Directory to write pod file.  By default it goes into
  ** "{Env.cur.workDir}/lib/fan/"
  **
  Uri outDir := Env.cur.workDir.plus(`lib/fan/`).uri

//////////////////////////////////////////////////////////////////////////
// Validate
//////////////////////////////////////////////////////////////////////////

  private Void validate()
  {
    if (podName == null) throw fatal("Must set BuildPod.podName")
    if (summary == null) throw fatal("Must set BuildPod.summary")

    // boot strap checking
    if (["sys", "build", "compiler", "compilerJava"].contains(podName))
    {
      if (Env.cur.homeDir == devHomeDir)
        throw fatal("Must update 'devHome' for bootstrap build")
    }
  }

//////////////////////////////////////////////////////////////////////////
// Compile
//////////////////////////////////////////////////////////////////////////

  **
  ** Compile the source into a pod file and all associated
  ** natives.  See `compileFan`, `compileJava`, and `compileDotnet`.
  **
  @Target { help = "Compile to pod file and associated natives" }
  virtual Void compile()
  {
    validate

    log.info("compile [$podName]")
    log.indent

    compileFan
    compileJava
// TODO-FACET
//    compileDotnet
    log.unindent
  }

//////////////////////////////////////////////////////////////////////////
// Compile Fan
//////////////////////////////////////////////////////////////////////////

  **
  ** Compile Fan code into pod file
  **
  virtual Void compileFan()
  {
    // add my own meta
    meta := this.meta.dup
    meta["pod.docApi"] = docApi.toStr
    meta["pod.docSrc"] = docSrc.toStr
    meta["pod.native.java"]   = (javaDirs   != null && !javaDirs.isEmpty).toStr
    meta["pod.native.dotnet"] = (dotnetDirs != null && !dotnetDirs.isEmpty).toStr
    meta["pod.native.js"]     = (jsDirs     != null && !jsDirs.isEmpty).toStr

    // map my config to CompilerInput structure
    ci := CompilerInput()
    ci.inputLoc    = Loc.makeFile(scriptFile)
    ci.podName     = podName
    ci.summary     = summary
    ci.version     = version
    ci.depends     = depends.map |s->Depend| { Depend(s) }
    ci.meta        = meta
    ci.index       = index
    ci.baseDir     = scriptDir
    ci.srcFiles    = srcDirs
    ci.resFiles    = resDirs
    ci.jsFiles     = jsDirs
    ci.log         = log
    ci.includeDoc  = docApi
    ci.mode        = CompilerInputMode.file
    ci.outDir      = outDir.toFile
    ci.output      = CompilerOutputMode.podFile

    if (dependsDir != null)
    {
      f := dependsDir.toFile
      if (!f.exists) throw fatal("Invalid dependsDir: $f")
      ci.ns = FPodNamespace(f)
    }

    try
    {
      Compiler(ci).compile
    }
    catch (CompilerErr err)
     {
      // all errors should already be logged by Compiler
      throw FatalBuildErr()
    }
    catch (Err err)
    {
      log.err("Internal compiler error")
      err.trace
      throw FatalBuildErr.make
    }
  }

//////////////////////////////////////////////////////////////////////////
// Compile Java
//////////////////////////////////////////////////////////////////////////

  **
  ** Compile native Java jar file if podJavaDirs is configured
  **
  virtual Void compileJava()
  {
    if (this.javaDirs == null) return
    javaDirs := resolveDirs(this.javaDirs)

    log.info("javaNative [$podName]")
    log.indent

    // env
    jtemp    := scriptDir + `temp-java/`
    jstub    := jtemp + "${podName}.jar".toUri
    jdk      := JdkTask(this)
    javaExe  := jdk.javaExe
    jarExe   := jdk.jarExe
    libJava  := devHomeDir + `lib/java/`
    curPod   := devHomeDir + `lib/fan/${podName}.pod`
    curJar   := devHomeDir + `lib/java/${podName}.jar`
    depends  := (Depend[])this.depends.map |s->Depend| { Depend(s) }

    // if there are no javaDirs we only only stubbing
    stubOnly := javaDirs.isEmpty

    // start with a clean directory
    Delete(this, jtemp).run
    if (!stubOnly) CreateDir(this, jtemp).run

    // stub the pods fan classes into Java classfiles
    // by calling the JStub tool in the jsys runtime
    stubDir := stubOnly ? libJava : jtemp
    Exec(this, [javaExe,
                "-cp", (libJava + `sys.jar`).osPath,
                "-Dfan.home=$Env.cur.workDir.osPath",
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
    depends.each |Depend d| { javac.cp.add(libJava+`${d.name}.jar`) }
    javac.src = javaDirs
    javac.run

    // extract stub jar into the temp directory
    Exec(this, [jarExe, "-xf", jstub.osPath], jtemp).run

    // now we can nuke the stub jar (and manifest)
    Delete(this, jstub).run
    Delete(this, jtemp + `meta-inf/`).run

    // jar everything back up to lib/java/{pod}.jar
    Exec(this, [jarExe, "cf", curJar.osPath, "-C", jtemp.osPath, "."], jtemp).run

    // append files to the pod zip (we use java's jar tool)
    Exec(this, [jarExe, "-fu", curPod.osPath, "-C", jtemp.osPath, "."], jtemp).run

    // cleanup temp
    Delete(this, jtemp).run

    log.unindent
  }

//////////////////////////////////////////////////////////////////////////
// DotnetNative
//////////////////////////////////////////////////////////////////////////

  **
  ** Compile native .NET assembly is podDotnetDirs configured
  **
  virtual Void compileDotnet()
  {
    if (dotnetDirs == null) return

    if (Env.cur.os != "win32")
    {
      log.info("dotnetNative skipping [$podName]")
      return
    }

    log.info("dotnetNative [$podName]")
    log.indent

    // env
    ntemp := scriptDir + `temp-dotnet/`
    nstub := ntemp + `${podName}.dll`
    nout  := ntemp + `${podName}Native_.dll`
    ndirs := resolveDirs(dotnetDirs)
    nlibs := [devHomeDir+`lib/dotnet/sys.dll`, nstub]
    nstubExe := devHomeDir + `bin/nstub`

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
    csc.src  = ndirs
    csc.libs = nlibs
    csc.run

    // append files to the pod zip (we use java's jar tool)
    jdk    := JdkTask(this)
    jarExe := jdk.jarExe
    curPod := devHomeDir + `lib/fan/${podName}.pod`
    Exec(this, [jarExe, "-fu", curPod.osPath, "-C", ntemp.osPath,
      "${podName}Native_.dll", "${podName}Native_.pdb"], ntemp).run

    // cleanup temp
    Delete(this, ntemp).run

    log.unindent
  }

//////////////////////////////////////////////////////////////////////////
// Clean
//////////////////////////////////////////////////////////////////////////

  **
  ** Delete all intermediate and target files
  **
  @Target { help = "Delete all intermediate and target files" }
  virtual Void clean()
  {
    log.info("clean [$podName]")
    log.indent
    Delete(this, devHomeDir+`lib/fan/${podName}.pod`).run
    Delete(this, devHomeDir+`lib/java/${podName}.jar`).run
    Delete(this, devHomeDir+`lib/dotnet/${podName}.dll`).run
    Delete(this, devHomeDir+`lib/dotnet/${podName}.pdb`).run
    Delete(this, devHomeDir+`lib/tmp/${podName}.dll`).run
    Delete(this, devHomeDir+`lib/tmp/${podName}.pdb`).run
    Delete(this, scriptDir+`temp-java/`).run
    Delete(this, scriptDir+`temp-dotnet/`).run
    log.unindent
  }

//////////////////////////////////////////////////////////////////////////
// Doc
//////////////////////////////////////////////////////////////////////////

  **
  ** Build the HTML documentation
  **
  @Target { help = "Build the HTML documentation" }
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

  **
  ** Run the unit tests using 'fant' for this pod
  **
  @Target { help = "Run the pod unit tests via fant" }
  virtual Void test()
  {
    log.info("test [$podName]")
    log.indent

    fant := Exec.exePath(devHomeDir + `bin/fant`)
    Exec(this, [fant, podName]).run

    log.unindent
  }

//////////////////////////////////////////////////////////////////////////
// Full
//////////////////////////////////////////////////////////////////////////

  **
  ** Run clean, compile, and test
  **
  @Target { help = "Run clean, compile, and test" }
  virtual Void full()
  {
    clean
    compile
    test
  }
}