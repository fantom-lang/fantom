//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   3 Nov 06  Brian Frank  Creation
//

**
** BuildPod is the base class for build scripts used to manage
** building a Fan source code and resources into a Fan pod.
**
** See `docTools::Build` for details.
**
abstract class BuildPod : BuildScript
{

//////////////////////////////////////////////////////////////////////////
// Pod Meta-Data
//////////////////////////////////////////////////////////////////////////

  **
  ** Programatic name of the pod.  Required.
  **
  Str podName

  **
  ** Short one sentence description of the pod.  Required.
  **
  Str description

  **
  ** User defined pod level facets.  Optional.
  **
  Str:Obj podFacets

  **
  ** Version of the pod - typically set to
  ** `BuildScript.globalVersion`.  Required.
  **
  Version version

  **
  ** Dependencies of the pod formatted as a list
  ** of `sys::Depend` strings.  Required.
  **
  Str[] depends

  **
  ** The directory to look in for the dependency pod file (and
  ** potentially their recursive dependencies).  If null then we
  ** use the compiler's own pod definitions via reflection (which
  ** is more efficient).
  **
  Uri dependsDir

  **
  ** List of Uris relative to `scriptDir` of directories containing
  ** the Fan source files to compile.  Required.
  **
  Uri[] srcDirs

  **
  ** List of Uris relative to `scriptDir` of directories of resources
  ** files to package into pod zip file.  Optional.
  **
  Uri[] resDirs

  **
  ** List of Uris relative to `scriptDir` of directories containing
  ** the Java source files to compile for Java native jar.
  **
  Uri[] javaDirs

  **
  ** List of Uris relative to `scriptDir` of Java jar files which
  ** are automatically included in the classpath when compiling the
  ** `javaDirs`.
  **
  Uri[] javaLibs

  **
  ** List of Uris relative to `scriptDir` of directories containing
  ** the C# source files to compile for .NET native dll.
  **
  Uri[] netDirs

  **
  ** List of Uris relative to `scriptDir` of .NET assemblies which
  ** are automatically included in the library path when compiling
  ** the `netDirs`.
  **
  Uri[] netLibs

//////////////////////////////////////////////////////////////////////////
// Setup
//////////////////////////////////////////////////////////////////////////

  **
  ** Validate subclass constructor setup required meta-data.
  **
  internal override Void validate()
  {
    if (podFacets == null) podFacets = Str:Obj[:]

    ok := true
    ok &= validateReqField("podName")
    ok &= validateReqField("version")
    ok &= validateReqField("depends")
    if (!ok) throw FatalBuildErr.make

    // boot strap checking - ensure that we aren't
    // overwriting sys, build, or compiler
    if (podName == "sys" || podName == "build" || podName == "compiler")
    {
      if (Sys.homeDir == devHomeDir)
        throw fatal("Must update /lib/sys.props devHome for bootstrap build")
    }
  }

//////////////////////////////////////////////////////////////////////////
// BuildScript
//////////////////////////////////////////////////////////////////////////

  **
  ** Default target is `compile`.
  **
  override Target defaultTarget()
  {
    if (javaDirs == null && netDirs == null)
      return target("compile")
    else
      return target("full")
  }

//////////////////////////////////////////////////////////////////////////
// Compile
//////////////////////////////////////////////////////////////////////////

  @target="compile fan source into pod"
  virtual Void compile(Bool full := false)
  {
    log.info("compile [$podName]")
    log.indent
    fanc := CompileFan.make(this)
      fanc.includeDoc = full
      fanc.includeSrc = full
    fanc.run
    log.unindent
  }

  internal Depend[] parseDepends()
  {
    return (Depend[])depends.map(Depend[,]) |Str s->Depend| { return Depend.fromStr(s) }
  }

//////////////////////////////////////////////////////////////////////////
// Clean
//////////////////////////////////////////////////////////////////////////

  @target="delete all intermediate and target files"
  virtual Void clean()
  {
    log.info("clean [$podName]")
    log.indent
    Delete.make(this, libFanDir+"${podName}.pod".toUri).run
    Delete.make(this, libJavaDir+"${podName}.jar".toUri).run
    Delete.make(this, libNetDir+"${podName}.dll".toUri).run
    Delete.make(this, libNetDir+"${podName}.pdb".toUri).run
    Delete.make(this, libDir+"tmp/${podName}.dll".toUri).run
    Delete.make(this, libDir+"tmp/${podName}.pdb".toUri).run
    Delete.make(this, scriptDir+"temp-java/".toUri).run
    Delete.make(this, scriptDir+"temp-net/".toUri).run
    log.unindent
  }

//////////////////////////////////////////////////////////////////////////
// JavaNative
//////////////////////////////////////////////////////////////////////////

  @target="build native Java jar file"
  virtual Void javaNative()
  {
    if (javaDirs == null) return

    log.info("javaNative [$podName]")
    log.indent

    // env
    jtemp    := scriptDir + `temp-java/`
    jstub    := jtemp + "${podName}.jar".toUri
    jdk      := JdkTask.make(this)
    javaExe  := jdk.javaExe
    jarExe   := jdk.jarExe
    curPod   := libFanDir + "${podName}.pod".toUri
    curJar   := libJavaDir + "${podName}.jar".toUri
    javaDirs := resolveDirs(javaDirs)
    javaLibs := resolveFiles(javaLibs)
    depends  := parseDepends

    // start with a clean directory
    Delete.make(this, jtemp).run
    CreateDir.make(this, jtemp).run

    // stub the pods fan classes into Java classfiles
    // by calling the JStub tool in the jsys runtime
    Exec.make(this, [javaExe.osPath,
                     "-cp", "${libJavaDir}sys.jar",
                     "fanx.tools.Jstub",
                     "-d", jtemp.osPath,
                     podName]).run

    // compile
    javac := CompileJava.make(this)
    javac.outDir = jtemp
    javac.cp.add(jtemp+"${podName}.jar".toUri).addAll(javaLibs)
    javac.cpAddExtJars
    depends.each |Depend d| { javac.cp.add(libJavaDir+(d.name+".jar").toUri) }
    javac.src = javaDirs
    javac.run

    // extract stub jar into the temp directory
    Exec.make(this, [jarExe.osPath, "-xf", jstub.osPath], jtemp).run

    // now we can nuke the stub jar (and manifest)
    Delete.make(this, jstub).run
    Delete.make(this, jtemp + `meta-inf/`).run

    // jar everything back up to lib/java/{pod}.jar
    Exec.make(this, [jarExe.osPath, "cf", curJar.osPath, "-C", jtemp.osPath, "."], jtemp).run

    // append files to the pod zip (we use java's jar tool)
    Exec.make(this, [jarExe.osPath, "-fu", curPod.osPath, "-C", jtemp.osPath, "."], jtemp).run

    // cleanup temp
    Delete.make(this, jtemp).run

    log.unindent
  }

//////////////////////////////////////////////////////////////////////////
// NetNative
//////////////////////////////////////////////////////////////////////////

  @target="build native .NET assembly"
  virtual Void netNative()
  {
    if (netDirs == null) return

    if (!isWindows)
    {
      log.info("netNative skipping [$podName]")
      return
    }

    log.info("netNative [$podName]")
    log.indent

    // env
    ntemp := scriptDir + `temp-net/`
    nstub := ntemp + "${podName}.dll".toUri
    nout  := ntemp + "${podName}Native_.dll".toUri
    ndirs := netDirs
    nlibs := ["${libNetDir}sys.dll".toUri, nstub.uri]
    if (netLibs != null) nlibs.addAll(nlibs)
    nstubExe := binDir + `nstub`

    // start with a clean directory
    Delete.make(this, ntemp).run
    CreateDir.make(this, ntemp).run

    // stub the pods fan classes into Java classfiles
    // by calling the JStub tool in the jsys runtime
    Exec.make(this, [nstubExe.osPath, "-d", ntemp.osPath, podName]).run

    // compile
    csc := CompileCs.make(this)
    csc.output = nout
    csc.targetType = "library"
    csc.src  = resolveDirs(ndirs)
    csc.libs = resolveFiles(nlibs)
    csc.run

    // append files to the pod zip (we use java's jar tool)
    jdk    := JdkTask.make(this)
    jarExe := jdk.jarExe
    curPod := libFanDir + "${podName}.pod".toUri
    Exec.make(this, [jarExe.osPath, "-fu", curPod.osPath, "-C", ntemp.osPath,
      "${podName}Native_.dll", "${podName}Native_.pdb"], ntemp).run

    // cleanup temp
    Delete.make(this, ntemp).run

    log.unindent
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
    netNative
  }

//////////////////////////////////////////////////////////////////////////
// Doc
//////////////////////////////////////////////////////////////////////////

  @target="build fandoc HTML docs"
  virtual Void doc()
  {
    // use docCompiler reflectively
    docCompiler := Type.find("docCompiler::Main").make
    Int r := docCompiler->run(Str[podName])
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
    Exec.make(this, [fant.osPath, podName]).run

    log.unindent
  }

}