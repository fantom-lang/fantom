//
// Copyright (c) 2025, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 May 2025  Brian Frank  Creation
//

using build
using compiler
using util

**
** Java transpiler command
**
internal class JavaCmd : TranspileCmd
{
  override Str name() { "java" }

  override Str summary() { "Transpile to Java" }

  @Opt { help = "Run javac on all target pods after transpile" }
  Bool javac

  @Opt { help = "Create jar for targets under outDir after transpile" }
  Str? jar

  override Int usage(OutStream out := Env.cur.out)
  {
    ret := super.usage(out)
    out.printLine("Examples:")
    out.printLine("  fanc java foo               // generate Java source for 'foo' pod and its depends")
    out.printLine("  fanc java foo -javac        // generate Java and run javac")
    out.printLine("  fanc java foo -jar foo.jar  // generate Java, run javac, build jar file")
    return ret
  }

//////////////////////////////////////////////////////////////////////////
// Run
//////////////////////////////////////////////////////////////////////////

  override Int run()
  {
    super.run
    if (javac || jar != null) compileJava
    if (jar != null) compileJar
    return 0
  }

  override CompilerInput stdCompilerInput(TranspilePod pod, |CompilerInput|? f := null)
  {
    input := super.stdCompilerInput(pod, f)
    input.wrapperPerParameterizedCollectionType = true
    input.coerceParameterizedCollectionTypes = true
    return input
  }

//////////////////////////////////////////////////////////////////////////
// Gen
//////////////////////////////////////////////////////////////////////////

  override Void genPod(PodDef p)
  {
    // special handling for sys
    if (p.name == "sys")
    {
      JavaNativeGen(this).genSys(p)
      return
    }

    // generate all non-synthetic types
    super.genPod(p)

    // if we have native code copy it
    JavaNativeGen(this).genPod(p)
  }

  override Void genType(TypeDef t)
  {
    if (t.isSynthetic) return
    if (t.isNative) return

    JavaUtil.typeFile(outDir, t).withOut(null) |out|
    {
      JavaTypePrinter(out).type(t)
    }
  }

//////////////////////////////////////////////////////////////////////////
// Java Tools
//////////////////////////////////////////////////////////////////////////

  once File jvmDir()
  {
    outDir.plus(`out/`)
  }

  Void compileJava()
  {
    info("\n## Javac [$jvmDir.osPath]")

    // javac
    cmd := [jdk.javacExe]

    // always assume UTF-8
    cmd.add("-encoding").add("utf-8")

    // -d outDir
    jvmDir.create
    cmd.add("-d").add(jvmDir.osPath)

    // source for each target
    pods.each |p|
    {
      addJavaFiles(cmd, JavaUtil.podDir(outDir, p.name))
    }

    // fanx
    JavaUtil.fanxDirs(outDir).each |dir| { addJavaFiles(cmd, dir) }

    // execute
    r := Process(cmd, Env.cur.workDir).run.join
    if (r != 0) throw Err("Javac failed")
  }

  private Void addJavaFiles(Str[] acc, File dir)
  {
    dir.list.each |f|
    {
      if (f.ext == "java") acc.add(f.osPath)
    }
  }

  Void compileJar()
  {
    prepJar

    jarFile := outDir + `$jar`
    info("\n## Jar [$jarFile.osPath]")

    // javac
    cmd := [jdk.jarExe]

    cmd.add("cf").add(jarFile.osPath)
    cmd.add("-C").add(jvmDir.osPath)
    cmd.add(".")

    // execute
    r := Process(cmd, Env.cur.workDir).run.join
    if (r != 0) throw Err("Jar failed")
  }

  Void prepJar()
  {
    // etc files required
    JarDist.doEtcFiles(Env.cur.homeDir) |path, file|
    {
      file.copyTo(jvmDir + path)
    }

    // copy reflect info for each pod
    pods.each |p|
    {
      JarDist.doReflect(p.name, p.podFile) |path, file|
      {
        file.copyTo(jvmDir + path)
      }
    }
  }

  JdkTask jdk()
  {
    JdkTask(DummyBuildScript())
  }
}

internal class DummyBuildScript : BuildScript {}

