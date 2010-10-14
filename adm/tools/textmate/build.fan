#! /usr/bin/env fan
//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 Oct 10 Andy Frank  Creation - my bday!!
//

**
** Build tool
**
class Build
{
  static Void main()
  {
    args := Env.cur.args
    if (args.size != 1)
    {
      Env.cur.out.printLine("Usage: build <directory>")  
      Env.cur.exit(-1)
    }
    Build { dir=args.first }.build
  }
  
  **
  ** Find nearest build.fan file and build pod.
  **
  Void build()
  {
    if (!findBuildFile) Env.cur.exit(-1)
    if (!findFanHome)   Env.cur.exit(-1)
    if (!checkFanHome)  Env.cur.exit(-1)
    exec
  }

  **
  ** Try to find the build.fan script associated with
  ** the current tab by looking up the directory tree.
  **
  Bool findBuildFile()
  {
    // get the current resource as a file, if this file is
    // the build.fan file itself, then we're done
    f := File(`$dir`)
    if (f.name == "build.fan") { buildFile = f; return true }

    // lookup up directory tree until we find "build.fan"
    if (!f.isDir) f = f.parent
    while (f.path.size > 0)
    {
      buildFile = f + `build.fan`      
      if (buildFile.exists) return true
      f = f.parent
    }

    Env.cur.out.printLine("Cannot find build.fan file: $dir")
    return false
  }

  **
  ** Try to find the Fan installation associated with the
  ** build.fan file.  Right now we assume the source tree is
  ** directly under the fan installation so we look up the
  ** dir tree for "lib/fan".  If we can't find the fan
  ** installation, then assume the installation running Flux.
  **
  ** TODO: eventually we need some sort of project file which
  ** instructs the tools how to map a given source directory
  ** to the installation to use
  **
  Bool findFanHome()
  {
    f := buildFile.parent
    while (f.path.size > 0)
    {
      binDir := f + `bin/fan.exe`
      if (binDir.exists) { fanHome = f; return true }
      f = f.parent
    }

    fanHome = Env.cur.homeDir
    return true
  }

  **
  ** Check that we aren't trying to compile a core pod for the
  ** Fan installation being used by Flux itself since that could
  ** lead to some weird errors.
  **
  Bool checkFanHome()
  {
    // if different installations then we're ok
    if (fanHome.normalize != Env.cur.homeDir.normalize)
      return true

    // check for one of the core pods
    if (!corePods.contains(buildFile.parent.name))
      return true

    Env.cur.out.printLine("Cannot compile core pod using Fan installation for Flux itself: $fanHome")
    return false
  }

  **
  ** Execute the build.fan script.
  **
  Void exec()
  {
    fan  := fanHome + `bin/fan`
    cmd  := [fan.osPath, buildFile.osPath]
    proc := Process(cmd)
    proc.out = BuildOutStream()
    proc.run.join    
  }
  
  static const Str[] corePods := ["sys", "jfan", "nfan",
    "build", "compile", "fwt", "flux", "fluxText"]

  Str? dir
  File? buildFile
  File? fanHome
}

**************************************************************************
** BuildOutStream
**************************************************************************

internal class BuildOutStream : OutStream
{
  new make() : super(null) {}
  
  override This write(Int b)
  {
    str := Buf().write(b).flip.readAllStr.toXml.replace(" ", "&nbsp;")
    echo("$str")
    return this
  }

  override This writeBuf(Buf b, Int n := b.remaining)
  {
    str  := Buf().writeBuf(b, n).flip.readAllStr.toXml.replace(" ", "&nbsp;")
    line := checkLine(str)
    echo("$line<br/>")
    return this
  }
  
  private Str checkLine(Str s)
  {
    if (s.contains("BUILD&nbsp;SUCCESS")) return "<span style='color:#080'>$s</span>"
    if (s.contains("BUILD&nbsp;FAILED"))  return "<span style='color:red'>$s</span>"
    if (s.contains(".fan("))
    {
      openParen  := s.index(".fan(")
      closeParen := s.index(")", openParen)
      comma      := s.index(",", openParen)
      
      line  := s[openParen+5..<comma]
      col   := s[comma+1..<closeParen]

      slash := s.indexr("/", openParen)
      path  := s[0..openParen+3]
      file  := path[slash+1..-1]
      err   := s[closeParen+1..-1]
      
      return "<span style='white-space:nowrap;'>
                <a href='txmt://open?url=file://$path&line=$line&column=$col'>$file</a>($line,$col)$err
                </span>"
    }
    return s
  }
}
