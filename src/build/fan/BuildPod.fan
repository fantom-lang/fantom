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
  Str? podName

  **
  ** Version of the pod - typically set to
  ** `BuildScript.globalVersion`.  Required.
  **
  Version? version

  **
  ** Dependencies of the pod formatted as a list
  ** of `sys::Depend` strings.  Required.
  **
  Str[]? depends

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
  ** List of Uris relative to `scriptDir` of directories containing
  ** the Fan source files to compile.  Required.
  **
  Uri[]? srcDirs

  **
  ** List of Uris relative to `scriptDir` of directories of resources
  ** files to package into pod zip file.  Optional.
  **
  Uri[]? resDirs

  **
  ** List of Uris relative to `scriptDir` of directories containing
  ** the Java source files to compile for Java native jar.
  **
  Uri[]? javaDirs

  **
  ** List of Uris relative to `scriptDir` of Java jar files which
  ** are automatically included in the classpath when compiling the
  ** `javaDirs`.
  **
  Uri[]? javaLibs

  **
  ** List of Uris relative to `scriptDir` of directories containing
  ** the C# source files to compile for .NET native dll.
  **
  Uri[]? dotnetDirs

  **
  ** List of Uris relative to `scriptDir` of .NET assemblies which
  ** are automatically included in the library path when compiling
  ** the `dotnetDirs`.
  **
  Uri[]? dotnetLibs

  **
  ** If true compile any Types with the '@js' facet into JavaScript source.
  **
// TODO FIXIT
//  Bool jsCompile
Bool hasJavascript

  **
  ** List of Uris relative to `scriptDir` of directories containing
  ** the JavaScript source files to include for native JavaScript
  ** support.
  **
// TODO FIXIT
//  Uri[]? jsDirs
Uri[]? javascriptDirs

  **
  ** Include the full set of source code in the pod file.
  ** This is required to generate links in HTML doc to HTML
  ** formatted source.  Defaults to false.
  **
  Bool includeSrc

  **
  ** Include the fandoc API in the pod file.  This is required to
  ** access the doc at runtime and to run the fandoc compiler.
  ** Default is true.
  **
  Bool includeFandoc

  ** TODO-SYM
  Str? description

//////////////////////////////////////////////////////////////////////////
// Setup
//////////////////////////////////////////////////////////////////////////

  **
  ** Internal initialization before setup is called
  **
  internal override Void initEnv()
  {
    super.initEnv
    includeSrc = false
    includeFandoc = true
  }

  **
  ** Validate subclass constructor setup required meta-data.
  **
  internal override Void validate()
  {
    ok := true
    ok &= validateReqField("podName")
    ok &= validateReqField("version")
    ok &= validateReqField("depends")
    if (!ok) throw FatalBuildErr.make

    // boot strap checking - ensure that we aren't
    // overwriting sys, build, or compiler
    if (podName == "sys" || podName == "build" ||
        podName == "compiler" || podName == "compilerJava")
    {
      if (Sys.homeDir == devHomeDir)
      {
        props := Sys.homeDir + `lib/sys.props`
        throw fatal("Must update $props.osPath 'fan.build.devHome' for bootstrap build")
      }
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
    if (javaDirs == null && dotnetDirs == null && !hasJavascript && javascriptDirs == null)
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
    fanc.includeDoc = includeFandocAndSrc && includeFandoc
    fanc.includeSrc = includeFandocAndSrc && includeSrc
    fanc.run
    log.unindent
  }

  internal Depend[] parseDepends()
  {
    depends.map |Str s->Depend| { Depend.fromStr(s) }
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
    if (javaDirs == null) return

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
    javaDirs := resolveDirs(javaDirs)
    javaLibs := resolveFiles(javaLibs)
    depends  := parseDepends

    // if there are no javaDirs we only only stubbing
    stubOnly := javaDirs.isEmpty

    // start with a clean directory
    Delete(this, jtemp).run
    if (!stubOnly) CreateDir(this, jtemp).run

    // stub the pods fan classes into Java classfiles
    // by calling the JStub tool in the jsys runtime
    stubDir := stubOnly ? libJavaDir : jtemp
    Exec(this, [javaExe.osPath,
                     "-cp", "${libJavaDir}sys.jar",
                     "fanx.tools.Jstub",
                     "-d", stubDir.osPath,
                     podName]).run

    // if there are no javaDirs we only only stubbing
    if (stubOnly) return

    // compile
    javac := CompileJava(this)
    javac.outDir = jtemp
    javac.cp.add(jtemp+"${podName}.jar".toUri).addAll(javaLibs)
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
    if (dotnetDirs == null) return

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
    ndirs := dotnetDirs
    nlibs := ["${libDotnetDir}sys.dll".toUri, nstub.uri]
    if (dotnetLibs != null) nlibs.addAll(nlibs)
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

  @target="compile Fan source to JavaScript"
  virtual Void js()
  {
    if (!hasJavascript) return

    log.info("js [$podName]")
    log.indent

    // env
    nativeDirs := resolveDirs(javascriptDirs)
    jsTemp := scriptDir + `temp-js/`

    // start with a clean directory
    Delete(this, jsTemp).run
    CreateDir(this, jsTemp).run

    // compile javascript
    out := jsTemp.createFile("${podName}.js").out
    jsc := CompileJs(this)
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
    Exec(this, [fant.osPath, podName]).run

    log.unindent
  }

}