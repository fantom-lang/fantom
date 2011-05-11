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
      formatPod(byName[name].sortr)
    }
  }

  private Void formatPod(PodSpec[] versions)
  {
    top := versions.first

    // ensure summary isn't too long
    summary := top.summary
    if (summary.size > 100) summary = summary[0..100] + "..."

    // figure out alignment padding for versions
    verPad := 6
    versions.each |x| { verPad = verPad.max(x.version.toStr.size) }

    // print it
    out.printLine(top.name)
    out.printLine("  $summary")
    versions.each |x|
    {
      // build details as "ts, size"
      details := StrBuf()
      if (x.ts != null) details.join(x.ts.date.toLocale("DD-MMM-YYYY"), ", ")
      if (x.size != null) details.join(x.size.toLocale("B"), ", ")

      // print version info line
      verStr := x.version.toStr.padr(verPad)
      out.printLine("  $verStr ($details)")
    }
  }
}