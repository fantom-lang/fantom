//
// Copyright (c) 2023, SkyFoundry LLC
// All Rights Reserved
//
// History:
//   27 Jul 2023  Matthew Giannini  Creation
//

using util

internal class HelpCmd : NodeJsCmd
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
      cmdName :=commandName[0]
      cmd := find(cmdName)
      if (cmd == null) return err("Unknown help command '${cmdName}'")
      printLine
      printLine(cmd.summary)
      printLine
      if (!cmd.aliases.isEmpty)
      {
        printLine("Aliases:")
        printLine("  " + cmd.aliases.join(" "))
      }
      ret := cmd.usage
      printLine
      return ret
    }

    // show summary for all commands; find longest command name
    cmds := list
    maxName := 4
    cmds.each |cmd| { maxName = maxName.max(cmd.name.size) }

    // print help
    printLine
    printLine("nodeJs commands:")
    printLine
    list.each |cmd|
    {
      printLine(cmd.name.padr(maxName) + "  " + cmd.summary)
    }
    printLine
    return 0
  }
}
