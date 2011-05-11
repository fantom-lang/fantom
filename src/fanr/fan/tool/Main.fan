//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//    3 May 11  Brian Frank  Creation
//

**
** Command line main for 'fanr'
**
class Main
{
  ** Map of command names to command types
  Command[] commands :=
  [
    HelpCmd(),
    ConfigCmd(),
    QueryCmd(),
    PublishCmd(),
  ]

  ** Run a command where the first arg is the command name and
  ** subsequent args are command specific arguments.  Return 0
  ** on success or non-zero on failure.
  Int main(Str[] args)
  {
    // if no args print uage
    if (args.isEmpty) return usage
    n := args.first

    // if arg is -? or -help print usage
    if (n == "-?" || n == "-help") return usage

    // map to command
    matches := commands.findAll |c| { c.name.startsWith(n) }
    if (matches.size == 0) return usage("Unknown command: $n")
    if (matches.size > 1)  return usage("Ambiguous command: " + matches.join(", " ) { it.name})
    cmd := matches.first

    try
    {
      // initialize command
      if (!cmd.init(args[1..-1])) return 1

      // execute command
      cmd.run
      return 0
    }
    catch (CommandErr e)
    {
      // command errors should already be logged
      return 1
    }
    catch (Err e)
    {
      cmd.out.printLine("ERROR: Internal error")
      e.trace(cmd.out)
      return 1
    }
  }

  ** Print usage help and return non-zero
  private Int usage(Str? errMsg := null, OutStream out := Env.cur.out)
  {
    // find command with longest name
    maxName := 10
    commands.each |cmd| { maxName = maxName.max(cmd.name.size) }
    maxName += 2

    // print standard heading
    out.printLine("Fantom Repository Manager")
    out.printLine("usage:")
    out.printLine("  fanr <command> [options] [args]")
    out.printLine("commands:")

    // print print "{name} {summary}"
    out.printLine("  " + "-?, -help".padr(maxName) + " print usage help")
    commands.each |c| { out.printLine("  ${c.name.padr(maxName)} $c.summary") }

    // if we had error message, print that too
    if (errMsg != null) out.printLine.printLine(errMsg)
    return 1
  }
}