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
  [Str:Obj]? podFacets

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
  ** is more efficient).  As a general rule you shouldn't mess
  ** with this field - it is used by the 'build' and 'compiler'
  ** build scripts for bootstrap build.
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
  ** If true compile any Types with the '@javascript' facet into
  ** Javascript source.
  **
  Bool hasJavascript

  **
  ** List of Uris relative to `scriptDir` of directories containing
  ** the Javascript source files to include for native Javascript
  ** support.
  **
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
    if  (podFacets == null) podFacets = Str:Obj[:]

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
    Delete.make(this, libDotnetDir+"${podName}.dll".toUri).run
    Delete.make(this, libDotnetDir+"${podName}.pdb".toUri).run
    Delete.make(this, libDir+"tmp/${podName}.dll".toUri).run
    Delete.make(this, libDir+"tmp/${podName}.pdb".toUri).run
    Delete.make(this, scriptDir+"temp-java/".toUri).run
    Delete.make(this, scriptDir+"temp-dotnet/".toUri).run
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

    // if there are no javaDirs we only only stubbing
    stubOnly := javaDirs.isEmpty

    // start with a clean directory
    Delete.make(this, jtemp).run
    if (!stubOnly) CreateDir.make(this, jtemp).run

    // stub the pods fan classes into Java classfiles
    // by calling the JStub tool in the jsys runtime
    stubDir := stubOnly ? libJavaDir : jtemp
    Exec.make(this, [javaExe.osPath,
                     "-cp", "${libJavaDir}sys.jar",
                     "fanx.tools.Jstub",
                     "-d", stubDir.osPath,
                     podName]).run

    // if there are no javaDirs we only only stubbing
    if (stubOnly) return

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
// Javascript
//////////////////////////////////////////////////////////////////////////

  @target="compile Fan source to Javasript"
  virtual Void javascript()
  {
    if (!hasJavascript) return
    // use compilerJavascript reflectively
    compilerJavascript := Type.find("compilerJavascript::Main").make
    Int r := compilerJavascript->run(scriptFile.uri)
    if (r != 0) fatal("Cannot compile javascript '$podName'")
  }

//////////////////////////////////////////////////////////////////////////
// JavascriptNative
//////////////////////////////////////////////////////////////////////////

  @target="include native Javascript source files"
  virtual Void javascriptNative()
  {
    if (javascriptDirs == null) return

    // if run directly, we have to run the javascript target first
    if (toRun.size == 1 && toRun.first.name == "javascriptNative")
      javascript

    log.info("javascriptNative [$podName]")
    log.indent

    // env
    jstemp := scriptDir + `temp-javascript/`
    jsDirs := resolveDirs(javascriptDirs)
    target := jstemp + "$podName-native.js".toUri

    // start with a clean directory
    Delete.make(this, jstemp).run
    CreateDir.make(this, jstemp).run

    // get original javascript file
    jdk    := JdkTask.make(this)
    jarExe := jdk.jarExe
    curPod := libFanDir + "${podName}.pod".toUri
    Exec.make(this, [jarExe.osPath, "-fx", curPod.osPath, "${podName}.js"], jstemp).run
    orig := jstemp + "${podName}.js".toUri
    if (!orig.exists) orig.create

    // merge
    out := target.out
    jsDirs.each |File f|
    {
      files := f.isDir ? f.listFiles : [f]
      files.each |File js|
      {
        in := js.in
        in.pipe(out)
        in.close
        out.printLine("")
      }
    }
    out.close

    // minify
    min := jstemp + "$podName-min.js".toUri
    in  := target.in
    out = min.out
    minify(in, out)
    in.close
    out.close

    // append to orig
    in  = min.in
    out = orig.out(true)
    out.printLine("")
    in.pipe(out)
    in.close
    out.close

    // add back into pod
    Exec.make(this, [jarExe.osPath, "fu", curPod.osPath, "-C", jstemp.osPath, orig.name], jstemp).run

    // cleanup temp
    //Delete.make(this, jstemp).run

    log.unindent
  }

  private Void minify(InStream in, OutStream out)
  {
    inBlock := false
    in.readAllLines.each |line|
    {
      s := line
      // line comments
      i := s.index("//")
      if (i != null) s = s[0...i]
      // block comments
      temp := s
      a := temp.index("/*")
      if (a != null)
      {
        s = temp[0...a]
        inBlock = true
      }
      if (inBlock)
      {
        b := temp.index("*/")
        if (b != null)
        {
          s = (a == null) ? temp[b+2..-1] : s + temp[b+2..-1]
          inBlock = false
        }
      }
      // trim and print
      s = s.trim
      if (inBlock) return
      if (s.size == 0) return
      out.printLine(s)
    }
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
    javascript
    javascriptNative
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
    javascript
    javascriptNative
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