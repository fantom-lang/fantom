//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//    3 May 11  Brian Frank  Creation
//

**
** QueryCmd is used to query the repo to list pods available
**
internal class QueryCmd : Command
{

//////////////////////////////////////////////////////////////////////////
// Usage
//////////////////////////////////////////////////////////////////////////

  override Str name() { "query" }

  override Str summary() { "query repo to list pods available" }

//////////////////////////////////////////////////////////////////////////
// Args/Opts
//////////////////////////////////////////////////////////////////////////

  @CommandArg
  {
    name = "query"
    help = "query filter used to match pods in repo"
  }
  Str? query

  @CommandOpt
  {
    name   = "n"
    help   = "Number of versions per pod limit"
    config = "numVersions"
  }
  Int numVersions := 5

//////////////////////////////////////////////////////////////////////////
// Execution
//////////////////////////////////////////////////////////////////////////

  override Void run()
  {
    // perform query
    specs := repo.query(query, numVersions)

    // handle no pods found
    if (specs.isEmpty)
    {
      out.printLine("No pods found")
      return
    }

    // group by name
    byName := Str:PodSpec[][:]
    specs.each |spec|
    {
      byName.getOrAdd(spec.name, |->PodSpec[]| { PodSpec[,] }).add(spec)
    }

    // format to output
    byName.keys.sort.each |name|
    {
      printPodVersions(byName[name])
    }
  }

}