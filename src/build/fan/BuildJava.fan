//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   3 Nov 06  Brian Frank  Creation
//

**
** BuildJava is the base class for build scripts used to manage
** building Java source code into a Java jar file.
**
abstract class BuildJava : BuildScript
{

//////////////////////////////////////////////////////////////////////////
// Pod Meta-Data
//////////////////////////////////////////////////////////////////////////

  **
  ** Required target jar file to build
  **
  File jar

  **
  ** Required list of dotted package names to compile.  Each of these
  ** packages must have a corresponding source directory relative to the
  ** script directory.
  **
  Str[] packages

  **
  ** Main class name to add to manifest if not null.
  **
  Str? mainClass

//////////////////////////////////////////////////////////////////////////
// Setup
//////////////////////////////////////////////////////////////////////////

  **
  ** Validate subclass constructor setup required meta-data.
  **
  internal override Void validate()
  {
    ok := true
    ok &= validateReqField("jar")
    ok &= validateReqField("packages")
    if (!ok) throw FatalBuildErr.make

    // boot strap checking - ensure that we aren't overwriting sys.jar
    if (jar.name == "sys.jar")
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
  override Target defaultTarget() { return target("compile") }

//////////////////////////////////////////////////////////////////////////
// Dump Env
//////////////////////////////////////////////////////////////////////////

  @target="Dump env details to help build debugging"
  override Void dumpenv()
  {
    super.dumpenv

    oldLevel := log.level
    log.level = LogLevel.silent
    try
      log.out.printLine("  javaHome:    ${JdkTask(this).jdkHomeDir}")
    catch (Err e)
      log.out.printLine("  javaHome:    $e")
    finally
      log.level = oldLevel
  }

//////////////////////////////////////////////////////////////////////////
// Compile
//////////////////////////////////////////////////////////////////////////

  @target="compile Java source into jar"
  Void compile()
  {
    log.info("compile [${scriptDir.name}]")
    log.indent

    temp     := scriptDir + `temp/`
    jdk      := JdkTask.make(this)
    jarExe   := jdk.jarExe
    manifest := temp + `Manifest.mf`

    // make temp dir
    CreateDir.make(this, temp).run

    // find all the packages which have out of date files
    outOfDate := findOutOfDateDirs(temp)
    if (outOfDate.isEmpty)
    {
      log.info("Up to date!")
      return
    }

    // compile out of date packages
    javac := CompileJava.make(this)
    javac.src = outOfDate
    javac.cp.add(temp)
    javac.outDir = temp
    javac.run

    // write manifest
    log.info("Write Manifest [${manifest.osPath}]")
    out := manifest.out
    out.printLine("Manifest-Version: 1.0")
    if (mainClass != null) out.printLine("Main-Class: $mainClass")
    out.close

    // ensure jar target directory exists
    CreateDir.make(this, jar.parent).run

    // jar up temp directory
    log.info("Jar [${jar.osPath}]")
    Exec.make(this, [jarExe.osPath, "cfm", jar.osPath, manifest.osPath, "-C", temp.osPath, "."], temp).run

    log.unindent
  }

  private File[] findOutOfDateDirs(File temp)
  {
    acc := File[,]
    packages.each |Str p|
    {
      path := Uri.fromStr(p.replace(".", "/") + "/")
      srcDir := scriptDir + path
      outDir := temp + path
      if (anyOutOfDate(srcDir, outDir))
        acc.add(srcDir)
    }
    return acc
  }

  private Bool anyOutOfDate(File srcDir, File outDir)
  {
    return srcDir.list.any |File src->Bool|
    {
      if (src.ext != "java") return false
      out := outDir + (src.basename + ".class").toUri
      return !out.exists || out.modified < src.modified
    }
  }

//////////////////////////////////////////////////////////////////////////
// Clean
//////////////////////////////////////////////////////////////////////////

  @target="delete all intermediate and target files"
  Void clean()
  {
    log.info("clean [${scriptDir.name}]")
    log.indent
    Delete.make(this, scriptDir + `temp/`).run
    Delete.make(this, jar).run
    log.unindent
  }

//////////////////////////////////////////////////////////////////////////
// CompileAll
//////////////////////////////////////////////////////////////////////////

  @target="alias for compile"
  Void compileAll()
  {
    compile
  }

//////////////////////////////////////////////////////////////////////////
// Full
//////////////////////////////////////////////////////////////////////////

  @target="clean+compile"
  Void full()
  {
    clean
    compile()
  }

}