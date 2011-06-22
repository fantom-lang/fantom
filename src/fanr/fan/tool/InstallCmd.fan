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
    // perform query
    specs := repo.query(query, 1)

// calculate dependencies
// TODO

    // print game plan and confirm
    specs.each |spec|
    {
      out.printLine
      printPodVersion(spec)
    }
    out.printLine
    if (!confirm("Install?")) return

    // copy each spec
    out.printLine
    specs.each |spec| { copy(spec) }
    out.printLine
    out.printLine("Installation successful ($specs.size pods)")
  }

  private Void copy(PodSpec spec)
  {
    out.print("Installing ${spec} ... ").flush
// TODO
dest := Env.cur.tempDir + `${spec.toStr}.pod`
    destOut := dest.out
    try
    {
      repo.read(spec).pipe(destOut)
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

}