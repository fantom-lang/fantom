//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//    23 Jun 11  Brian Frank  Creation
//

**
** UninstallCmd uninstalls a pod from the local environment
** with safety checks for dependencies.
**
internal class UninstallCmd : Command
{

//////////////////////////////////////////////////////////////////////////
// Usage
//////////////////////////////////////////////////////////////////////////

  override Str name() { "uninstall" }

  override Str summary() { "uninstall a pod from local env" }

//////////////////////////////////////////////////////////////////////////
// Args/Opts
//////////////////////////////////////////////////////////////////////////

  @CommandArg
  {
    name = "query"
    help = "query filter for pods to uninstall"
  }
  Str? query

//////////////////////////////////////////////////////////////////////////
// Execution
//////////////////////////////////////////////////////////////////////////

  override Void run()
  {
    // perform query
    specs := env.query(query)

    // handle no pods found
    if (specs.isEmpty)
    {
      out.printLine("No pods found")
      return
    }

    // format to output
    out.printLine
    specs.sort.each |spec|
    {
      printPodVersion(spec)
    }

    // ensure uninstall won't break any depends
    out.printLine
    if (!checkDepends(specs))
    {
      out.printLine
      out.printLine("Cannot uninstall without breaking above dependencies")
      return
    }

    // confirm
    msg := specs.size == 1 ?
      "Uninstall $specs.first.name?" :
      "Uninstall $specs.size pods?"
    if (!confirm(msg)) return

    // nuke each spec
    out.printLine
    specs.each |spec| { delete(spec) }
    out.printLine
    out.printLine("Uninstall successful ($specs.size pods)")
  }

  private Bool checkDepends(PodSpec[] specs)
  {
    // map specs by name
    map := Str:PodSpec[:].setList(specs) |s| { s.name }

    // walk thru all install pods not in our spec list
    ok := true
    env.queryAll.each |pod|
    {
      // if this pod in our uninstall list, then skip it
      if (map[pod.name] != null) return

      // we are keeping this guy, so make sure that none
      // of the pods to uninstall are in its depend list
      pod.depends.each |d|
      {
        if (map[d.name] != null)
        {
          out.printLine("ERROR: '$pod.name' depends on '$d.name'")
          ok = false
        }
      }
    }

    return ok
  }

  private Void delete(PodSpec spec)
  {
    file := Env.cur.findPodFile(spec.name)
    out.print("Deleting $file.osPath ... ").flush
    file.delete
    out.printLine("Complete")
  }

}