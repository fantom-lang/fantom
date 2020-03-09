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
** Perform a check-out from git tip and clean bootstrap build
**
class Bootstrap : AbstractMain
{

//////////////////////////////////////////////////////////////////////////
// Env
//////////////////////////////////////////////////////////////////////////

  @Opt { help = "Git repository to clone" }
  Str gitRepo := "https://github.com/fantom-lang/fantom"

  @Opt { help = "Skip git pull step" }
  Bool skipPull := false

  @Opt { help = "Dir to clone repo and build" }
  File devHome

  Str? gitVer
  Str? jdkVer
  File? jdkHome
  Str relVer
  File relHome

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
      gitPull
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
    // gitVer
    if (skipPull)
      gitRepo = gitVer = "*** SKIP ***"
    else
      gitVer = execToStr(["git", "--version"])

    // javaHome
    javaHome := Env.cur.vars.find |v, k| { k.lower == "java_home" }
    if (javaHome != null)
      jdkHome = File.os(javaHome).normalize

    // javaVer: either must be in path or vai java_home env var
    if (jdkHome == null)
      jdkVer = execToStr(["javac", "-version"])
    else
      jdkVer = execToStr([(jdkHome+`bin/javac`).osPath, "-version"])

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
    echo("  gitRepo:   $gitRepo")
    echo("  gitVer:    $gitVer")
    echo("  jdkVer:    $jdkVer (need 1.8+)")
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
    if (!gitVer.contains("git") && !skipPull)
      fatal("check that 'git' is installed in your path")

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
    Env.cur.out.print("Continue with these settings? [y|n] ").flush
    line := Env.cur.in.readLine
    if (!line.lower.startsWith("y"))
    {
      echo("CANCELLED")
      throw CancelledErr()
    }
  }

//////////////////////////////////////////////////////////////////////////
// Git Pull
//////////////////////////////////////////////////////////////////////////

  Void gitPull()
  {
    if (skipPull) return

    // clone or pull+update
    if(devHome.plus(`.git/`).exists)
      runPullCmd(["git", "pull"], devHome)
    else
      runPullCmd(["git", "clone", gitRepo, devHome.osPath], devHome.parent)
  }

  Void runPullCmd(Str[] cmd, File workDir)
  {
    echo("")
    echo(cmd.join(" "))
    r := Process(cmd, workDir).run.join
    if (r != 0) fatal("could not git clone/pull repo")
  }

//////////////////////////////////////////////////////////////////////////
// Config Etcs
//////////////////////////////////////////////////////////////////////////

  Void configEtcs()
  {
    echo("")
    echo("Config etcs:")
    updateEtc(relHome + `etc/build/config.props`, "devHome", devHome.uri)
    updateEtc(relHome + `etc/build/config.props`, "jdkHome", jdkHome.uri)
    updateEtc(devHome + `etc/build/config.props`, "jdkHome", jdkHome.uri)
  }

  Void updateEtc(File f, Str key, Uri val)
  {
    echo("  $f.osPath: $key=$val.toCode")
    newLine := "$key=$val"
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
    runBuild(relHome, `src/buildall.fan`,  "superclean")
    runBuild(relHome, `src/buildboot.fan`, "compile")
    runBuild(devHome, `src/buildpods.fan`, "compile", ["FAN_HOME":devHome.osPath])
  }

  Void runBuild(File envHome, Uri script, Str target, [Str:Str]? env := null)
  {
    // figure out which launcher to use
    exec := envHome.plus(`bin/fan`).osPath
    opts := [devHome.plus(script).osPath, target]
    if (Env.cur.os == "win32")
    {
      opts = ["/C", exec].addAll(opts)
      exec = "cmd.exe"
    }
    cmd := [exec].addAll(opts)
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
