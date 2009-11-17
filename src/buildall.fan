#! /usr/bin/env fansubstitute
//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   6 Nov 06  Brian Frank  Creation
//

using build

**
** buildall.fan
**
** This is the top level build script for building Fan - it routes
** build functions to two sub-scripts buildboot and buildpods.  This
** top level script itself and buildboot.fan must be hosted by a
** substitute runtime defined in sys.props used to bootstrap this
** development environment to a self-buildable state.
**
class Build : BuildGroup
{

//////////////////////////////////////////////////////////////////////////
// Setup
//////////////////////////////////////////////////////////////////////////

  override Void setup()
  {
    childrenScripts =
    [
      `buildboot.fan`,
      `buildpods.fan`,
    ]
  }

  override Target[] makeTargets()
  {
    return BuildScript.super.makeTargets
  }

//////////////////////////////////////////////////////////////////////////
// Compile
//////////////////////////////////////////////////////////////////////////

  @target="run compile on all pods"
  Void compile()
  {
    spawnOnChildren("compile")
  }

//////////////////////////////////////////////////////////////////////////
// Clean
//////////////////////////////////////////////////////////////////////////

  @target="run clean on all pods"
  Void clean()
  {
    runOnChildren("clean")
  }

//////////////////////////////////////////////////////////////////////////
// Compile All
//////////////////////////////////////////////////////////////////////////

  @target="run compileAll on all pods"
  Void compileAll()
  {
    spawnOnChildren("compileAll")
  }

//////////////////////////////////////////////////////////////////////////
// Full
//////////////////////////////////////////////////////////////////////////

  @target="run full on all pods"
  Void full()
  {
    runOnChildren("clean")
    spawnOnChildren("full")
  }

//////////////////////////////////////////////////////////////////////////
// Test
//////////////////////////////////////////////////////////////////////////

  @target="run test on all pods"
  Void test()
  {
    fantExe := (binDir+"fant$exeExt".toUri).osPath
    Exec.make(this, [fantExe, "-all"]).run
  }

//////////////////////////////////////////////////////////////////////////
// Doc
//////////////////////////////////////////////////////////////////////////

  @target="build fandoc HTML docs"
  Void doc()
  {
    fanExe := (binDir+"fan$exeExt".toUri).osPath
    allBuildPodScripts.each |BuildPod script|
    {
      if (script.podName.startsWith("test")) return
      Exec.make(this, [fanExe, "docCompiler", script.podName]).run
    }

    Exec.make(this, [fanExe, "docCompiler", "-topindex"]).run
  }

//////////////////////////////////////////////////////////////////////////
// Examples
//////////////////////////////////////////////////////////////////////////

  @target="build example HTML docs"
  Void examples()
  {
    fanExe := (binDir+"fan$exeExt".toUri).osPath
    Exec.make(this, [fanExe, (scriptDir+`../examples/build.fan`).osPath]).run
  }

//////////////////////////////////////////////////////////////////////////
// Superclean
//////////////////////////////////////////////////////////////////////////

  @target="delete lib dir"
  Void superclean()
  {
    // fanLib nuke it all
    Delete.make(this, libFanDir).run

    // doc nuke it all
    Delete.make(this, devHomeDir + `doc/`).run

    // javaLib (keep ext/)
    libJavaDir.list.each |File f|
    {
      if (f.name != "ext")
        Delete.make(this, f).run
    }

    deleteNonDist
  }

//////////////////////////////////////////////////////////////////////////
// Zip
//////////////////////////////////////////////////////////////////////////

  @target="create build zip file"
  Void zip()
  {
    moniker := "fantom-${@buildVersion.val}"
    zip := CreateZip(this)
    {
      outFile = devHomeDir + `${moniker}.zip`
      inDir = devHomeDir
      pathPrefix = "$moniker/".toUri
      filter = |File f, Str path->Bool|
      {
        if (f.name == ".hg")       return false
        if (f.name == ".hgignore") return false
        if (f.name == "tmp")       return false
        // TODO: ship fandoc pod files?
        if (f.isDir) log.info("  $path")
        return true
      }
    }
    zip.run
  }

//////////////////////////////////////////////////////////////////////////
// Dist
//////////////////////////////////////////////////////////////////////////

  @target="build distributation full, test, doc"
  Void dist()
  {
    superclean
    full
    doc
    test
    examples
    deleteNonDist
    zip
  }

  @target="delete non-distribution files"
  Void deleteNonDist()
  {
    Delete.make(this, devHomeDir+`tmp/`).run
    Delete.make(this, devHomeDir+`lib/tmp/`).run
    Delete.make(this, devHomeDir+`lib/types.db`).run
    Delete.make(this, devHomeDir+`lib/tmp`).run
    Delete.make(this, devHomeDir+`src/sys/java/temp/`).run
    Delete.make(this, devHomeDir+`flux/session/`).run

    libJavaDir.list.each |File f|
    {
      if (f.name != "sys.jar" && f.name != "ext")
        Delete.make(this, f).run
    }
  }

//////////////////////////////////////////////////////////////////////////
// Debug Env
//////////////////////////////////////////////////////////////////////////

  @target="Dump env details to help debugging bootstrap"
  override Void dumpenv()
  {
    super.dumpenv
    spawnOnChildren("dumpenv")
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  override Void spawnOnChildren(Str target)
  {
    // make exec task to spawn buildboot and buildpods
    boot := makeSpawnExec(`buildboot.fan`, target)
    pods := makeSpawnExec(`buildpods.fan`, target)

    // ensure that buildpods has its FAN_HOME variable set correctly
    // because on UNIX this script's FAN_SUBSTITUTE will export the
    // wrong FAN_HOME to buildpods.fan
    pods.process.env["FAN_HOME"] = devHomeDir.osPath

    // spawn
    boot.run
    pods.run
  }

  private Exec makeSpawnExec(Uri script, Str target)
  {
    fanExe := (binDir + "fan$exeExt".toUri).osPath
    return Exec.make(this, [fanExe, (scriptDir + script).osPath, target])
  }

  BuildPod[] allBuildPodScripts(BuildScript[] children := this.children)
  {
    // recursively find all the BuildPod scripts in
    // my children scripts and their descendents
    acc := BuildPod[,]
    children.each |BuildScript child|
    {
      if (child is BuildGroup)
      {
        group := child as BuildGroup
        acc.addAll((BuildPod[])group.children.findType(BuildPod#))
        acc.addAll(allBuildPodScripts(group.children))
      }
    }
    return acc
  }

}