#! /usr/bin/env fan
//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Jun 08  Brian Frank  Creation
//

using build

**
** Build: fwt
**
class Build : BuildPod
{
  override Void setup()
  {
    podName = "fwt"
  }

  @target="build native JavaFx files"
  Void javafx()
  {
    log.info("javafx [$podName]")
    log.indent

    src  := scriptFile.parent + `javafx/`
    dist := scriptFile.parent + `res/javafx/`

    // start with a clean directory
    Delete.make(this, dist).run
    CreateDir.make(this, dist).run

    // compile and package
    cmd := ["javafxpackager", "-src", src.osPath, "-appClass", "fan.fwt.Canvas", "-d", dist.osPath]
    r := Process.make(cmd).run.join
    if (r != 0) throw fatal("javafxpackager compiler reported errors")
    log.unindent

    // remove unnecessary files
    Delete.make(this, dist + `Canvas.html`).run
    Delete.make(this, dist + `Canvas.jnlp`).run
  }

}