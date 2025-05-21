//
// Copyright (c) 2025, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 May 2025  Brian Frank  Creation
//

using util


**************************************************************************
** HelpCmd
**************************************************************************

internal class HelpCmd : FancCmd
{
  override Str name() { "help" }

  override Str[] aliases() { ["-h", "-?"] }

  override Str summary() { "Print listing of available commands" }

  @Arg Str[] commandName := [,]

  override Int run()
  {
    // if we have a command name, print its usage
    if (commandName.size > 0)
    {
      cmdName := commandName[0]
      cmd := find(cmdName)
      if (cmd == null) return err("Unknown help command '$cmdName'")
      printLine
      ret := cmd.usage
      printLine
      return ret
    }

    // show summary for all commands; find longest command name
    cmds := list
    Str[] names := cmds.map |cmd->Str| { cmd.names.join(", ") }
    maxName := 4
    names.each |n| { maxName = maxName.max(n.size) }

    // print help
    printLine
    printLine("Fantom Compiler Tools:")
    printLine
    list.each |cmd, i|
    {
      printLine(names[i].padr(maxName) + "  " + cmd.summary)
    }
    printLine
    return 0
  }
}

**************************************************************************
** VersionCmd
**************************************************************************

internal class VersionCmd : FancCmd
{
  override Str name() { "version" }

  override Str[] aliases() { ["-v"] }

  override Str summary() { "Print version info" }

  override Int run()
  {
    props := Str:Obj[:] { ordered = true }
    runtimeProps(props)
    props["fanc.version"] = typeof.pod.version.toStr

    out := Env.cur.out
    out.printLine
    out.printLine("Fantom Compiler Tools")
    out.printLine("Copyright (c) 2006-${Date.today.year}, Brian Frank and Andy Frank")
    out.printLine("Licensed under the Academic Free License version 3.0")
    out.printLine
    printProps(props, ["out":out])
    out.printLine
    return 0
  }
}

**************************************************************************
** DumpSysCmd
**************************************************************************

/*
internal class DumpSysCmd : FancCmd
{
  override Str name() { "dumpsys" }

  override Str summary() { "Dump sys stats" }

  override Int run()
  {
    echo
    count := 0
    Pod.find("sys").types.each |t|
    {
      t.methods.each |m|
      {
        if (m.parent != t) return
        funcs := m.params.any |p| { p.type.fits(Func#) }
        if (funcs) { echo(m.qname); count++ }
      }
    }
    echo("sys methods with funcs: $count")
    return 0
  }
}
*/

