//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   23 Jun 11  Brian Frank  Creation
//

**
** EnvCmd is used to query the local env pods
**
internal class EnvCmd : Command
{

//////////////////////////////////////////////////////////////////////////
// Usage
//////////////////////////////////////////////////////////////////////////

  override Str name() { "env" }

  override Str summary() { "query pods installed in local environment" }

//////////////////////////////////////////////////////////////////////////
// Args/Opts
//////////////////////////////////////////////////////////////////////////

  @CommandArg
  {
    name = "query"
    help = "query filter used to match pods in env"
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
    specs.sort.each |spec|
    {
      printPodVersion(spec)
    }
  }

}