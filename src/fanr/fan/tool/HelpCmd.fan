//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//    3 May 11  Brian Frank  Creation
//

**
** HelpCmd prints help on a specific command
**
internal class HelpCmd : Command
{

//////////////////////////////////////////////////////////////////////////
// Usage
//////////////////////////////////////////////////////////////////////////

  override Str name() { "help" }

  override Str summary() { "print help on a specific command" }

//////////////////////////////////////////////////////////////////////////
// Args/Opts
//////////////////////////////////////////////////////////////////////////

  ** Command name argument
  @CommandArg
  {
    name = "command"
    help = "show help for given command name"
  }
  Str? command

//////////////////////////////////////////////////////////////////////////
// Execution
//////////////////////////////////////////////////////////////////////////

  override Void run()
  {
    // find command
    c := Main().commands.find |c| { c.name == command }
    if (c == null) throw err("Help command not found: $command")

    // print usage
    c.usage
  }
}