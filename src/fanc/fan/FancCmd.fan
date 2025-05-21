//
// Copyright (c) 2025, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 May 2025  Brian Frank  Creation
//

using util

**
** Fantom CLI compiler command plugin.  To create:
**
**  1. Define subclass of FancCmd
**  2. Register type qname via indexed prop as "fanc.cmd" (if not in this pod)
**  3. Annotate options and args using `util::AbstractMain` design
**
abstract class FancCmd : AbstractMain
{
  ** Find a specific command or return null
  static FancCmd? find(Str name)
  {
    list.find |cmd| { cmd.name == name || cmd.aliases.contains(name) }
  }

  ** List installed commands
  static FancCmd[] list()
  {
    acc := FancCmd[,]

    // this pod
    FancCmd#.pod.types.each |t|
    {
      if (t.fits(FancCmd#) && !t.isAbstract) acc.add(t.make)
    }

    // other pods via index
    Env.cur.index("fanc.cmd").each |qname|
    {
      try
      {
        type := Type.find(qname)
        cmd := (FancCmd)type.make
        acc.add(cmd)
      }
      catch (Err e) echo("ERROR: invalid fanc.cmd $qname\n  $e")
    }

    acc.sort |a, b| { a.name <=> b.name }
    return acc
  }

  ** App name is "fanc {name}"
  override final Str appName() { "fanc $name" }

  ** Log name is "fanc"
  override Log log() { Log.get("fanc") }

  ** Command name
  abstract Str name()

  ** Command name alises/shortcuts
  virtual Str[] aliases() { Str[,] }

  ** Name and aliases
  Str[] names() { [name].addAll(aliases) }

  ** Run the command.  Return zero on success
  abstract override Int run()

  ** Single line summary of the command for help
  abstract Str summary()

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  ** Print a line to stdout
  Void printLine(Str line := "") { echo(line) }

  ** Print info message
  Void info(Str msg) { printLine(msg) }

  ** Print error message and return 1
  Int err(Str msg) { printLine("ERROR: $msg"); return 1 }

}

