//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   1 Jan 08  Brian Frank  Creation
//

using compiler

**
** Fan Shell
**
class Shell
{

//////////////////////////////////////////////////////////////////////////
// Main Loop
//////////////////////////////////////////////////////////////////////////

  **
  ** Run the shell main loop.
  **
  Void run()
  {
    warmup
    out.printLine("Fan Shell v${type.pod.version} ('?' for help)")
    while (isAlive)
    {
      // input next line
      out.print("fansh> ").flush
      line := in.readLine

      // quit on eof
      if (line == null) break

      // skip empty lines
      line = line.trim
      if (line.size == 0) continue

      // check if line maps to predefined command
      if (command(line)) continue

      // evaluate the line
      Evaluator(this).eval(line)
    }
  }

  private Void warmup()
  {
    // launch a dummy evaluator to preload
    // all the compiler code into memory
    f := |,| { Evaluator(null).eval("0") }
    Thread(null, f).start
  }

//////////////////////////////////////////////////////////////////////////
// Commands
//////////////////////////////////////////////////////////////////////////

  **
  ** If the line maps to a command function, then run
  ** it and return true.  Otherwise return false.
  **
  Bool command(Str line)
  {
    switch (line)
    {
      case "bye":
      case "exit":
      case "quit":
        quit
        return true
      case "help":
      case "usage":
      case "?":
        help
        return true
      case "clear":
        scope.clear
        return true
      case "scope":
        dumpScope
        return true
      default:
        return false
    }
  }

  **
  ** Run the 'quit' command.
  **
  Void quit()
  {
    isAlive = false
  }

  **
  ** Run the 'help' command.
  **
  Void help()
  {
    out.printLine
    out.printLine("Fan Shell v${type.pod.version}")
    out.printLine("Commands:")
    out.printLine("  quit, exit, bye   exit shell")
    out.printLine("  ?, help, usage    help summary")
    out.printLine("  clear             clear the local variables")
    out.printLine("  scope             dump the local variables")
    out.printLine
  }

  **
  ** Run the 'scope' command.
  **
  Void dumpScope()
  {
    out.printLine
    out.printLine("Current Scope:")
    scope.values.sort.each |Var v|
    {
      out.printLine("  $v.of $v.name = $v.val")
    }
    out.printLine
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  Var? findInScope(Str name)
  {
    return scope.find |Var v->Bool| { echo("$v ?= $name"); return v.name == name }
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  OutStream out := Sys.out
  InStream in := Sys.in
  internal Bool isAlive := true
  internal Int evalCount := 0
  internal Str:Var scope := Str:Var[:]

}

**************************************************************************
** Var
**************************************************************************

internal class Var
{
  override Int compare(Obj obj) { return ((Var)obj).name <=> name }

  Type of := Obj#
  Str name
  Obj? val
}

**************************************************************************
** Main
**************************************************************************

**
** Main launcher for fan shell.
**
class Main { static Void main() { Shell.make.run } }