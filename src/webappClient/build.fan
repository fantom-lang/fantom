#! /usr/bin/env fan
//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 Jan 09  Andy Frank  Creation
//

using build

**
** Build: webappClient
**
class Build : BuildPod
{

  override Void setup()
  {
    podName       = "webappClient"
    version       = globalVersion
    description   = "Client-side framework for building web applications"
    depends       = ["sys 1.0", "web 1.0", "webapp 1.0"]
    srcDirs       = [`fan/`, `test/`]
    hasJavascript = true
  }

  @target="compile Fan source to Javasript"
  override Void compileJavascript()
  {
    echo("javascript [$podName]")

    tempDir := scriptFile.parent + `temp-javascript/`
    tempDir.delete
    tempDir.create

    lib := tempDir.createFile("${podName}.js")
    out := lib.out

    // collect source files
    src := Str:File[:]
    (scriptDir + `javascript/`).walk |File f|
    {
      if (f.ext == "js") src[f.name] = f
    }

    // output ordered files first
    ordered.each |Str name|
    {
      f := src[name]
      if (f == null) throw Err("Required file not found: $name")
      append(f, out)
    }

    // output everyone else
    src.each |File f|
    {
      if (ordered.contains(f.name)) return
      append(f, out)
    }

    out.close

    // add into pod file
    jar := JdkTask.make(this).jarExe
    pod := Sys.homeDir + "lib/fan/${podName}.pod".toUri
    Exec.make(this, [jar.osPath, "fu", pod.osPath, "-C", tempDir.osPath, "."], tempDir).run

    tempDir.delete
  }

  private Void append(File f, OutStream out)
  {
    f.readAllLines.each |Str line|
    {
      // TODO - improve comment stripping, whitespace, etc
      s := line.trim
      if (s.size == 0) return
      if (s.startsWith("//")) return
      out.printLine(line)
    }
  }

  Str[] ordered := ["Sys.js", "Obj.js", "Type.js", "Num.js"]

}