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
** Base class for transpiler commands
**
internal abstract class TranspileCmd : FancCmd
{

  @Opt { help = "Output directory" }
  File outDir := Env.cur.workDir + `gen/$name/`

  @Arg { help = "Target pod(s)" }
  Str[] pods := [,]

//////////////////////////////////////////////////////////////////////////
// Run
//////////////////////////////////////////////////////////////////////////

  ** Call compilePod on every target
  override Int run()
  {
    // always start fresh
    outDir.delete

    // generate code for every target pod
    pods.each |n|
    {
      build := buildScriptMap.get(n) ?: throw Err("No build script found for pod: $n")
      compilePod(n, build)
    }
    return 0
  }

  ** Map of pod name to build scripts for environment
  once Str:File buildScriptMap()
  {
    // we rely on the convention that all pods are in a directory
    // of their name and contain a fan/ source directory
    acc := Str:File[:]
    Env.cur.path.each |path|
    {
      path.plus(`src/`).walk |f|
      {
        if (f.name == "build.fan" && f.plus(`fan/`).exists)
        {
          podName := f.parent.name
          if (acc[podName] == null) acc[podName] = f
        }
      }
    }
    return acc.toImmutable
  }

//////////////////////////////////////////////////////////////////////////
// Compile
//////////////////////////////////////////////////////////////////////////

  ** Compile build script into AST
  virtual Void compilePod(Str podName, File build)
  {
    // info
    info("\n## Transpile $name [$podName]")

    // use the build script to generate compiler input
    pod := Env.cur.compileScript(build).pod
    type := pod.types.find |t| { t.fits(BuildPod#) }
    script := (BuildPod)type.make
    input := script.stdFanCompilerInput

    // run only the front end
    this.compiler = Compiler(input)
    compiler.frontend

    // transpile the pod
    genPod(compiler.pod)

    this.compiler = null
  }

//////////////////////////////////////////////////////////////////////////
// Generation
//////////////////////////////////////////////////////////////////////////

  ** Generate pod which calls genType for each non-synthetic
  virtual Void genPod(PodDef pod)
  {
    pod.typeDefs.each |type|
    {
      genType(type)
    }
  }

  ** Generate non-synthetic type
  virtual Void genType(TypeDef type)
  {
    echo("genType $type")
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  ** Compiler for current pod
  Compiler? compiler

}

