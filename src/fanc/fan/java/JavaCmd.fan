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

  @Opt { help = "Generate javadoc under outDir after transpile" }
  Bool javadoc

  @Opt { help = "Print and confirm preview of compile plan" }
  Bool preview

  override Int usage(OutStream out := Env.cur.out)
  {
    ret := super.usage(out)
    out.printLine("Examples:")
    out.printLine("  fanc java foo              // generate Java source for 'foo' pod and its depends")
    out.printLine("  fanc java -javac foo       // generate Java and run javac")
    out.printLine("  fanc java -jar foo.jar foo // generate Java, run javac, build jar file")
    return ret
  }

//////////////////////////////////////////////////////////////////////////
// Run
//////////////////////////////////////////////////////////////////////////

  override Int transpile()
  {
    if (preview) if (!showPreview) return 1
    super.transpile
    if (runJavac) compileJava
    if (jar != null) compileJar
    if (javadoc) compileJavadoc
    return 0
  }

  override CompilerInput stdCompilerInput(TranspilePod pod, |CompilerInput|? f := null)
  {
    input := super.stdCompilerInput(pod, f)
    input.wrapperPerParameterizedCollectionType = true
    input.coerceParameterizedCollectionTypes = true
    return input
  }

  private Bool runJavac() { javac || jar != null }

//////////////////////////////////////////////////////////////////////////
// Preview
//////////////////////////////////////////////////////////////////////////

  private Bool showPreview()
  {
    if (!preview) return true

    OutStream out := Env.cur.out
    out.printLine
    out.printLine("=== Java Transpile ===")
    out.printLine("pods:")
    pods.each |p| { out.printLine("  $p.name [$p.version]") }
    out.printLine("outDir:  $outDir.osPath")
    out.printLine("jar:     " + jarFile?.osPath)
    out.printLine("javadoc: " + javadocDir?.osPath)
    out.printLine("javac:   $runJavac")
    out.printLine

    return promptConfirm("Continue?")
  }

//////////////////////////////////////////////////////////////////////////
// Gen
//////////////////////////////////////////////////////////////////////////

  override Void genPod(PodDef p)
  {
    // run assemble with no fcode
    assemble

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

    JavaUtil.typeFile(outDir, t).withOut |out|
    {
      JavaTypePrinter(out).type(t)
    }
  }

//////////////////////////////////////////////////////////////////////////
// Assemble
//////////////////////////////////////////////////////////////////////////

  private Void assemble()
  {
    fpod := Assembler(compiler).assemblePodNoCode
    fpod.doWrite |uri|
    {
      file := jvmDir + `reflect/${compiler.pod.name}$uri`
      return file.out
    }
  }

//////////////////////////////////////////////////////////////////////////
// Java Tools
//////////////////////////////////////////////////////////////////////////

  private Void compileJava()
  {
    info("\n## Javac [$jvmDir.osPath]")

    // javac
    cmd := [jdk.javacExe]

    // always assume UTF-8
    cmd.add("-encoding").add("utf-8")

    // need big stack size for some pods like markdown
    cmd.add("-J-Xss4m")

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

//////////////////////////////////////////////////////////////////////////
// Jar
//////////////////////////////////////////////////////////////////////////

  private Void compileJar()
  {
    prepJar

    jarFile := this.jarFile
    info("\n## Jar [$jarFile.osPath]")

    // javac
    cmd := [jdk.jarExe]

    cmd.add("cf").add(jarFile.osPath)
    cmd.add("-C").add(jvmDir.osPath)
    cmd.add(".")

    // execute
    r := Process(cmd, Env.cur.workDir).run.join
    if (r != 0) throw Err("Jar failed")
    echo("Jar size: " + jarFile.size.toLocale("B"))
  }

  private Void prepJar()
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
        // fcode handled in assemble (without code section for reflect only)
        if (path.path.first == "reflect") return false

        // skip js files
        if (path.ext == "js") return false
        if (path.ext == "mjs") return false
        if (path.ext == "map") return false

        // skip fandoc files
        if (path.ext == "fandoc") return false

        file.copyTo(jvmDir + path)
        return true
      }
    }

    // reflect/pods.txt
    podNames = pods.map |p->Str| { p.name}
    JarDist.doReflectPodManifest(podNames) |path, file|
    {
      file.copyTo(jvmDir + path)
    }
  }

//////////////////////////////////////////////////////////////////////////
// Javadoc
//////////////////////////////////////////////////////////////////////////

  private Void compileJavadoc()
  {
    dir := outDir + `doc/`
    info("\n## Javadoc [$dir.osPath]")

    // javadoc
    cmd := [jdk.javadocExe]

    cmd.add("-sourcepath").add(outDir.osPath)
    cmd.add("-d").add(javadocDir.osPath)
    cmd.add("-Xdoclint:-missing")
    cmd.add("-quiet")
    pods.each |p| { cmd.add("fan.$p.name") }

    // execute
    r := Process(cmd, Env.cur.workDir).run.join
    if (r != 0) throw Err("Javadoc failed")
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  private once File jvmDir()
  {
    outDir.plus(`out/`)
  }

  private File? javadocDir()
  {
    !javadoc ? null : outDir + `doc/`
  }

  private File? jarFile()
  {
    jar == null ? null : outDir + `$jar`
  }

  private JdkTask jdk()
  {
    JdkTask(DummyBuildScript())
  }
}

internal class DummyBuildScript : BuildScript {}

