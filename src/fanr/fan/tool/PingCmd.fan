//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//    22 Jun 11  Brian Frank  Creation
//

**
** PingCmd is used to ping the repo
**
internal class PingCmd : Command
{

//////////////////////////////////////////////////////////////////////////
// Usage
//////////////////////////////////////////////////////////////////////////

  override Str name() { "ping" }

  override Str summary() { "ping the repo for availability" }

//////////////////////////////////////////////////////////////////////////
// Execution
//////////////////////////////////////////////////////////////////////////

  override Void run()
  {
    // perform query
    t1 := Duration.now
    ping := repo.ping
    t2 := Duration.now

    // ping
    out.printLine("Ping: $repo.uri [${(t2-t1).toLocale}]")
    out.printLine
    ping.keys.sort.each |n| { out.printLine("$n: " + ping[n]) }
    out.printLine
  }
}