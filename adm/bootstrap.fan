#! /usr/bin/env fan
//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   18 Dec 09  Brian Frank  Creation
//

using util

**
** Perform a check-out from hg tip and clean bootstrap build
**
class Bootstrap : AbstractMain
{

//////////////////////////////////////////////////////////////////////////
// Env
//////////////////////////////////////////////////////////////////////////

  Str repo := "http://hg.fantom.org/repos/fan-1.0"
  Str? hgVer
  Str? jdkVer
  File? jdkHome
  Str relVer
  File relHome

  @opt="Dir to clone repo and build"
  File devHome

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  new make()
  {
    relVer  = Str#.pod.version.toStr
    relHome = homeDir.plus(`../`).normalize
    devHome = relHome.plus(`../fan/`).normalize
  }

//////////////////////////////////////////////////////////////////////////
// Main
//////////////////////////////////////////////////////////////////////////

  override Int run()
  {
    try
    {
      initEnv
      printEnv
      checks
      confirm
      hgPull
      configEtcs
      build
      return 0
    }
    catch (CancelledErr e) return 1
  }

//////////////////////////////////////////////////////////////////////////
// InitEnv
//////////////////////////////////////////////////////////////////////////

  Void initEnv()
  {
    // hgVer
    hgVer = execToStr(["hg", "version"])

    // javaVer
    jdkVer = execToStr(["javac", "-version"])

    // javaHome
    javaHome := Sys.env.find |v, k| { k.lower == "java_home" }
    if (javaHome != null)
      jdkHome = File.os(javaHome).normalize

    // devHome
    devHome = devHome.uri.plusSlash.toFile.normalize
  }

//////////////////////////////////////////////////////////////////////////
// PrintEnv
//////////////////////////////////////////////////////////////////////////

  Void printEnv()
  {
    echo("")
    echo("Bootstrap Environment:")
    echo("  repo:      $repo")
    echo("  hgVer:     $hgVer")
    echo("  jdkVer:    $jdkVer (need 1.6+)")
    echo("  jdkHome:   $jdkHome")
    echo("  relVer:    $relVer")
    echo("  relHome:   $relHome")
    echo("  devHome:   $devHome")
    echo("")
  }

//////////////////////////////////////////////////////////////////////////
// Checks
//////////////////////////////////////////////////////////////////////////

  Void checks()
  {
    if (!hgVer.contains("Mercurial"))
      fatal("check that 'hg' is installed in your path")

    if (!jdkVer.contains("javac"))
      fatal("check that 'javac' is installed in your path")

    if (relHome == devHome)
      fatal("relHome == devHome")

    if (jdkHome == null || !jdkHome.exists)
      fatal("check that 'java_home' env var points to your JDK")
  }

//////////////////////////////////////////////////////////////////////////
// Confirm
//////////////////////////////////////////////////////////////////////////

  Void confirm()
  {
    Sys.out.print("Continue with these settings? [y|n] ").flush
    line := Sys.in.readLine
    if (!line.lower.startsWith("y"))
    {
      echo("CANCELLED")
      throw CancelledErr()
    }
  }

//////////////////////////////////////////////////////////////////////////
// Hg Pull
//////////////////////////////////////////////////////////////////////////

  Void hgPull()
  {
    // ensure working dir exists
    devHome.create

    // clone or pull+update
    cmd := devHome.plus(`.hg/`).exists ?
           ["hg", "pull", "-u", repo] :
           ["hg", "clone", repo, devHome.osPath]

    echo("")
    echo(cmd.join(" "))
    r := Process(cmd, devHome).run.join
    if (r != 0) fatal("could not hg clone/pull repo")
  }

//////////////////////////////////////////////////////////////////////////
// Config Etcs
//////////////////////////////////////////////////////////////////////////

  Void configEtcs()
  {
    echo("")
    echo("Config etcs:")
    updateEtc(relHome + `etc/build/pod.fansym`, "buildDevHome", devHome.uri)
    updateEtc(relHome + `etc/build/pod.fansym`, "buildJdkHome", jdkHome.uri)
    updateEtc(devHome + `etc/build/pod.fansym`, "buildJdkHome", jdkHome.uri)
  }

  Void updateEtc(File f, Str key, Uri val)
  {
    echo("  $f.osPath: $key=$val.toCode")
    newLine := "$key=$val.toCode"
    lines := f.readAllLines
    i := lines.findIndex |line| { line.startsWith("$key=") || line.startsWith("//$key=") }
    if (i != null)
      lines[i] = newLine
    else
      lines.add(newLine)
    f.out.print(lines.join("\n")).close
  }

//////////////////////////////////////////////////////////////////////////
// Build
//////////////////////////////////////////////////////////////////////////

  Void build()
  {
    runBuild(relHome, `src/buildall.fan`, "superclean")
    runBuild(relHome, `src/buildboot.fan`, "full")
    runBuild(devHome, `src/buildpods.fan`, "full", ["FAN_HOME":devHome.osPath])
  }

  Void runBuild(File envHome, Uri script, Str target, [Str:Str]? env := null)
  {
    // figure out which launcher to use
    bin := (Sys.os) == "win32" ? `bin/fan.exe` : `bin/fan`

    // buildboot using rel
    cmd := [envHome.plus(bin).osPath, devHome.plus(script).osPath, target]
    echo("")
    echo(cmd.join(" "))
    p := Process(cmd)
    if (env != null) p.env.setAll(env)
    r := p.run.join
    if (r != 0) fatal("$script $target failed")
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  Void fatal(Str msg)
  {
    echo("##")
    echo("## FATAL: $msg")
    echo("##")
    throw CancelledErr()
  }

  Str execToStr(Str[] cmd)
  {
    buf := Buf()
    p := Process(cmd) { out = buf.out }
    r := p.run.join
    return r != 0 ? "" : buf.flip.readAllLines.first
  }

}