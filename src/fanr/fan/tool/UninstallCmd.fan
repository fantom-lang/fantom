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
    specs := env.query(query, out)

    // handle no pods found
    if (specs.isEmpty)
    {
      out.printLine("No pods found")
      return
    }

// calculate dependencies
// TODO

    // format to output
    specs.sort.each |spec|
    {
      printPodVersion(spec)
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

  private Void delete(PodSpec spec)
  {
    file := Env.cur.findPodFile(spec.name)
    out.print("Deleting $file.osPath ... ").flush
    file.delete
    out.printLine("Complete")
  }

}