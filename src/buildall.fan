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
// BuildScript
//////////////////////////////////////////////////////////////////////////

  const Version version := Version(Pod.find("build").config("buildVersion"))

  new make()
  {
    childrenScripts =
    [
      `buildboot.fan`,
      `buildpods.fan`,
    ]
  }

  override TargetMethod[] targets()
  {
    acc := TargetMethod[,]
    typeof.methods.each |m|
    {
      if (!m.hasFacet(Target#)) return
      acc.add(TargetMethod(this, m))
    }
    return acc
  }

//////////////////////////////////////////////////////////////////////////
// Compile
//////////////////////////////////////////////////////////////////////////

  @Target { help = "Run 'compile' on all pods" }
  Void compile()
  {
    spawnOnChildren("compile")
  }

//////////////////////////////////////////////////////////////////////////
// Clean
//////////////////////////////////////////////////////////////////////////

  @Target { help = "Run 'clean' on all pods" }
  Void clean()
  {
    runOnChildren("clean")
  }

//////////////////////////////////////////////////////////////////////////
// Test
//////////////////////////////////////////////////////////////////////////

  @Target { help = "Run 'test' on all pods" }
  Void test()
  {
    fantExe := Exec.exePath(devHomeDir + `bin/fant`)
    Exec.make(this, [fantExe, "-all"]).run
  }

//////////////////////////////////////////////////////////////////////////
// Doc
//////////////////////////////////////////////////////////////////////////

  @Target { help = "Build fandoc HTML docs" }
  Void doc()
  {
    fanExe := Exec.exePath(devHomeDir + `bin/fan`)
    allBuildPodScripts.each |BuildPod script|
    {
      name := script.podName
      if (name.startsWith("test")) return
      src := script.scriptDir
      Exec.make(this, [fanExe, "docCompiler", "-src", src.osPath, name]).run
    }

    Exec.make(this, [fanExe, "docCompiler", "-topindex"]).run
  }

//////////////////////////////////////////////////////////////////////////
// Full
//////////////////////////////////////////////////////////////////////////

  @Target { help = "Run clean, compile, test on all pods" }
  Void full()
  {
    clean
    compile
    test
  }

//////////////////////////////////////////////////////////////////////////
// Examples
//////////////////////////////////////////////////////////////////////////

  @Target { help = "Build example HTML docs" }
  Void examples()
  {
    fanExe := Exec.exePath(devHomeDir + `bin/fan`)
    Exec.make(this, [fanExe, (scriptDir+`../examples/build.fan`).osPath]).run
  }

//////////////////////////////////////////////////////////////////////////
// Superclean
//////////////////////////////////////////////////////////////////////////

  @Target { help = "Delete every intermediate we can think of" }
  Void superclean()
  {
    // fanLib nuke it all
    Delete.make(this, devHomeDir + `lib/fan/`).run

    // doc nuke it all
    Delete.make(this, devHomeDir + `doc/`).run

    // javaLib (keep ext/)
    (devHomeDir + `lib/java/`).list.each |File f|
    {
      if (f.name != "ext")
        Delete.make(this, f).run
    }

    deleteNonDist
  }

//////////////////////////////////////////////////////////////////////////
// Zip
//////////////////////////////////////////////////////////////////////////

  @Target { help = "Create build zip file" }
  Void zip()
  {
    moniker := "fantom-$version"
    zip := CreateZip(this)
    {
      outFile = devHomeDir + `${moniker}.zip`
      inDirs = [devHomeDir]
      pathPrefix = "$moniker/".toUri
      filter = |File f, Str path->Bool|
      {
        n := f.name
        if (n.startsWith(".hg")) return false
        if (n == "tmp") return false
        if (n == "temp") return false
        if (f.isDir) log.info("  $path")
        return true
      }
    }
    zip.run
  }

//////////////////////////////////////////////////////////////////////////
// Dist
//////////////////////////////////////////////////////////////////////////

  @Target { help = "Build fantom-1.0.xx.zip distribution" }
  Void dist()
  {
    superclean
    compile
    doc
    test
    examples
    deleteNonDist
    zip
  }

  @Target { help = "Delete non-distribution files" }
  Void deleteNonDist()
  {
    Delete(this, devHomeDir+`tmp/`).run
    Delete(this, devHomeDir+`temp/`).run
    Delete(this, devHomeDir+`lib/tmp/`).run
    Delete(this, devHomeDir+`lib/temp/`).run
    Delete(this, devHomeDir+`src/sys/java/temp/`).run
    Delete(this, devHomeDir+`etc/sys/types.db`).run
    Delete(this, devHomeDir+`etc/flux/session/`).run
    Delete(this, devHomeDir+`examples/web/demo/logs/`).run

    (devHomeDir + `lib/java/`).list.each |File f|
    {
      if (f.name != "sys.jar" && f.name != "ext")
        Delete.make(this, f).run
    }
  }

//////////////////////////////////////////////////////////////////////////
// Debug Env
//////////////////////////////////////////////////////////////////////////

  override Void dumpEnv()
  {
    super.dumpEnv
    spawnOnChildren("-dumpEnv")
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
    fanExe := Exec.exePath(devHomeDir + `bin/fan`)
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