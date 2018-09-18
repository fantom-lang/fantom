//
// Copyright (c) 2018, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   17 Sep 2018  Andy Frank  Creation
//

**************************************************************************
** Command line tool support for build framework
**************************************************************************

internal class Main
{
  Int main()
  {
    cmd := Env.cur.args.first?.lower
    switch (cmd)
    {
      case "init": return InitCmd().run
      default:
        echo("usage: fan build init <podName>")
        return 1
    }
  }
}

**************************************************************************
** InitCmd
**************************************************************************

internal class InitCmd
{
  new make()
  {
    this.envDir = Env.cur.workDir
    this.srcDir = envDir + `src/`
    this.curDir = File.os(Env.cur.vars["user.dir"])
    this.hasEnv = curDir.pathStr.contains(envDir.pathStr)
  }

  ** Run init command.
  Int run()
  {
    try
    {
      parsePath
      createEnv
      createPod
      echo("INIT SUCCESS!")
      return 0
    }
    catch (Err err)
    {
      err.trace
      Env.cur.err.printLine("INIT FAILED!")
      return 1
    }
  }

  ** Parse pod name optional path.
  private Void parsePath()
  {
    // validate args
    arg := Env.cur.args.getSafe(1)
    if (arg == null) throw Err("Missing 'podName' argument")

    // parse path
    if (!arg.endsWith("/")) arg += "/"
    this.podPath = Uri.fromStr(arg)
    this.podName = podPath.path.last

    // validate pod name
    err := compiler::InitInput.isValidPodName(podName)
    if (err != null) throw Err(err)
  }

  ** Create a new env.
  private Void createEnv()
  {
    // short-circuit if already created
    if (hasEnv) return

    // check if dir exists
    if ((curDir + podPath).exists)
      throw Err("Cannot create env - directory already exists '$podPath'")

    // create new env using pod name; collapse podPath if specified
    this.envDir  = (curDir + podPath).create
    this.srcDir  = envDir + `src/`
    this.podPath = `${podName}/`

    // stub env dirs
    envDir.createDir("etc")
    envDir.createDir("lib")
    envDir.createDir("src")
    envDir.createFile("fan.props").out.print("").sync.close
    build := (envDir + `src/`).createFile("build.fan")
    build.out.printLine(buildGroup.replace("{{podName}}", podName)).sync.close
    build->executable = true

    echo("Created new env '${envDir.uri.relTo(curDir.uri)}'")
  }

  ** Create new pod source tree.
  private Void createPod()
  {
    // find podDir
    podDir := this.srcDir + this.podPath

    // verify pod does not already exist
    if (podDir.exists) throw Err("Pod '$podName' already exists")

    // stub pod dirs
    podDir.create
    podDir.createDir("fan")
    podDir.createDir("test")
    build := podDir.createFile("build.fan")
    build.out.printLine(buildPod.replace("{{podName}}", podName)).sync.close
    build->executable = true

    echo("Created new pod '${podDir.uri.relTo(envDir.uri)}'")
    if (hasEnv) echo("Remember to add '${podDir.uri.relTo(srcDir.uri)}build.fan' to 'src/build.fan'!")
  }

  ** Build group script template.
  private static const Str buildGroup :=
   """#! /usr/bin/env fan

      using build

      class Build : BuildGroup
      {
        new make()
        {
          childrenScripts =
          [
            `{{podName}}/build.fan`,
          ]
        }
      }"""

  ** Build pod script template.
  private static const Str buildPod :=
   """#! /usr/bin/env fan

      using build

      class Build : build::BuildPod
      {
        new make()
        {
          podName = "{{podName}}"
          summary = "Description of this pod"
          version = Version("1.0")
          // These values are optional, but recommended
          // See: http://fantom.org/doc/docLang/Pods#meta
          // meta = [
          //   "org.name":     "My Org",
          //   "org.uri":      "http://myorg.org/",
          //   "proj.name":    "My Project",
          //   "proj.uri":     "http://myproj.org/",
          //   "license.name": "Apache License 2.0",
          //   "vcs.name":     "Git",
          //   "vcs.uri":      "https://github.com/myorg/myproj"
          // ]
          depends = ["sys 1.0"]
          srcDirs = [`fan/`]
          // resDirs  = [,]
          // javaDirs = [,]
          // jsDirs   = [,]
          // docApi   = false   // defaults to 'true'
          // docSrc   = true    // defaults to 'false'
        }
      }"""

  private File envDir    // current Fantom env dir
  private File srcDir    // envDir + src/
  private File curDir    // current shell working dir
  private Bool hasEnv    // are we under an existing PathEnv
  private Str? podName   // pod name to create
  private Uri? podPath   // path to pod including podName
}