//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//    3 May 11  Brian Frank  Creation
//

**
** ConfigCmd prints basic config and version info
**
internal class ConfigCmd : Command
{

//////////////////////////////////////////////////////////////////////////
// Usage
//////////////////////////////////////////////////////////////////////////

  override Str name() { "config" }

  override Str summary() { "print config and version info" }

//////////////////////////////////////////////////////////////////////////
// Execution
//////////////////////////////////////////////////////////////////////////

  override Void run()
  {
    config := typeof.pod.props(`config.props`, 1ms)

    out.printLine("Fantom Repository Manager")
    out.printLine("Copyright (c) 2011, Brian Frank and Andy Frank")
    out.printLine("Licensed under the Academic Free License version 3.0")
    out.printLine
    out.printLine("sys.version:    ${Str#.pod.version}")
    out.printLine("fanr.version:   $typeof.pod.version")
    out.printLine("env.platform:   ${Env.cur.platform}")
    out.printLine("env.home:       ${Env.cur.homeDir}")
    out.printLine("env.work:       ${Env.cur.workDir}")
    out.printLine
    config.keys.sort.each |key|
    {
      keyStr := "${key}:".padr(15)
      val := config[key]
      out.printLine("$keyStr $val")
    }
  }
}