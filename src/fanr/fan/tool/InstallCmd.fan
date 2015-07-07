//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//    22 Jun 11  Brian Frank  Creation
//

**
** InstallCmd installs a pod from the repo to the local environment
** and may install/upgrade other pods as part of the dependency chain.
**
internal class InstallCmd : Command
{

//////////////////////////////////////////////////////////////////////////
// Usage
//////////////////////////////////////////////////////////////////////////

  override Str name() { "install" }

  override Str summary() { "install a pod from repo to local env" }

//////////////////////////////////////////////////////////////////////////
// Args/Opts
//////////////////////////////////////////////////////////////////////////

  @CommandArg
  {
    name = "query"
    help = "query filter for pods to install"
  }
  Str? query

//////////////////////////////////////////////////////////////////////////
// Execution
//////////////////////////////////////////////////////////////////////////

  override Void run()
  {
    // perform query for pods to install
    specs := repo.query(query, 1)

    // if no matches we are done
    if (specs.isEmpty)
    {
      out.printLine("No install pods matched")
      return
    }

    // convert specs to install items
    specs.each |spec|
    {
      items[spec.name] = InstallItem(spec, env.find(spec.name))
    }

    // calculate dependencies and add to install items
    findDepends

    // print game plan and confirm
    printInstallPlan(items)
    if (!confirm("Install?")) return

    // create temp dir for staging
    ts := DateTime.now.toLocale("YYMMDD-hhmmss")
    rand := Buf.random(4).toHex
    stageDir := Env.cur.tempDir + `fanr-stage-${ts}-${rand}/`

    // download each pod to the staging dir
    out.printLine
    items.each |item| { download(item, stageDir) }
    out.printLine
    out.printLine("Download successful ($items.size pods)")

    // now that we have safely downloaded everything,
    // do the actual install to local environment
    out.printLine
    items.each |item| { install(item, stageDir) }
    out.printLine
    out.printLine("Installation successful ($items.size pods)")
  }

  private Void findDepends()
  {
    // recursively check dependencies until we have them all checked
    while (true)
    {
      again := false
      items.dup.each |item|
      {
        if (item.dependsChecked) return
        checkDepends(item)
        item.dependsChecked = true
        again = true
      }
      if (!again) break
    }
  }

  private Void checkDepends(InstallItem item)
  {
    item.spec.depends.each |d|
    {
      // check if we meet depend with locally installed pod
      curInstalled := env.find(d.name)
      if (curInstalled != null && d.match(curInstalled.version)) return

      // check if we meet depend on pod already in our install list
      toInstall := items[d.name]
      if (toInstall != null && d.match(toInstall.spec.version)) return

      // query the repo, eventually it would more optimized to
      // batch as many dependency queries as possible together
      newInstall := repo.query(d.toStr, 1).first
      if (newInstall != null)
      {
        items[newInstall.name] = InstallItem(newInstall, curInstalled)
        return
      }

      // give up
      throw err("Cannot meet dependency '$d' for '$item.name'")
    }
  }

  private Void printInstallPlan(Str:InstallItem items)
  {
    maxName   := (items.vals.max |a, b| { a.name.size <=> b.name.size }).name.size
    maxAction := (items.vals.max |a, b| { a.actionStr.size <=> b.actionStr.size }).actionStr.size
    maxOldVer := (items.vals.max |a, b| { a.oldVerStr.size <=> b.oldVerStr.size }).oldVerStr.size

    out.printLine
    items.keys.sort.each |name|
    {
      item := items[name]
      out.printLine(name.justl(maxName) + "  [" +
                    item.actionStr.justl(maxAction) + "]  " +
                    item.oldVerStr.justl(maxOldVer) + " => " +
                    item.newVerStr)
    }
    out.printLine
  }

  private Void download(InstallItem item, File stageDir)
  {
    out.print("Downloading ${item.name} ... ").flush
    dest := stageDir + `${item.name}.pod`
    destOut := dest.out
    try
    {
      repo.read(item.spec).pipe(destOut)
      destOut.close
    }
    catch (Err e)
    {
      out.printLine.printLine
      destOut.close
      throw e
    }
    out.printLine("Complete")
  }

  private Void install(InstallItem item, File stageDir)
  {
    out.print("Installing ${item.name} ... ").flush
    src := stageDir +  `${item.name}.pod`
    dest := Env.cur.workDir + `lib/fan/`
    src.copyInto(dest, ["overwrite":true])
    out.printLine("Complete")
  }

  Str:InstallItem items := [:]   // items to install
}

**************************************************************************
** InstallItem
**************************************************************************

internal class InstallItem
{
  new make(PodSpec spec, PodSpec? cur)
  {
    this.spec      = spec
    this.cur       = cur
    this.oldVerStr = cur == null ? "not-installed" : cur.version.toStr
    this.newVerStr = spec.version.toStr
  }

  Str name() { spec.name }

  Str actionStr()
  {
    if (isSkip)  return "skip"
    if (cur == null) return "install"
    if (cur.version > spec.version) return "downgrade"
    return "upgrade"
  }

  PodSpec spec         // what is being installed from repo
  PodSpec? cur         // current version installed or null
  Str oldVerStr        // not-installed or current version
  Str newVerStr        // up-to-date or version to install
  Bool dependsChecked  // have we checked depends on this guy

  ** If cur exactly matches spec
  Bool isSkip() { spec.version == cur?.version }

}