//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   16 Sep 08  Brian Frank  Creation
//

using fwt
using flux

**
** Build tool
**
class Build : FluxCommand
{
  new make(Str id) : super(id) {}

  override Void invoked(Event? event)
  {
    frame.command(CommandId.saveAll).invoke(event)
    if (!findBuildFile) return
    if (!findFanHome) return
    if (!checkFanHome) return
    exec
  }

  **
  ** Try to find the build.fan script associated with
  ** the current tab by looking up the directory tree.
  **
  Bool findBuildFile()
  {
    // check that current view tab is file resource
    r := frame.view.resource
    if (r isnot FileResource)
    {
      Dialog.openErr(frame, "Current view is not file resource: $r.typeof")
      return false
    }

    // get the current resource as a file, if this file is
    // the build.fan file itself, then we're done
    f := ((FileResource)r).file
    if (f.name == "build.fan") { buildFile = f; return true }

    // lookup up directory tree until we find "build.fan"
    if (!f.isDir) f = f.parent
    while (f.path.size > 0)
    {
      buildFile = f + `build.fan`
      if (buildFile.exists) return true
      f = f.parent
    }

    Dialog.openErr(frame, "Cannot find build.fan file: $r")
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

    Dialog.openErr(frame, "Cannot compile core pod using Fan installation for Flux itself: $fanHome")
    return false
  }

  **
  ** Execute the build.fan script.
  **
  Void exec()
  {
    fan := fanHome + (Desktop.isWindows ? `bin/fan.exe` : `bin/fan`)
    cmd := [fan.osPath, buildFile.osPath]
    frame.console.show.exec(cmd)
  }

  static const Str[] corePods := ["sys", "jfan", "nfan",
    "build", "compile", "fwt", "flux", "fluxText"]

  File? buildFile
  File? fanHome
}