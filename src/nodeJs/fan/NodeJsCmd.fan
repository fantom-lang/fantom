//
// Copyright (c) 2023, SkyFoundry LLC
// All Rights Reserved
//
// History:
//   27 Jul 2023  Matthew Giannini  Creation
//

using compilerEs
using util

**
** NodeJs command target
**
abstract class NodeJsCmd : AbstractMain
{
  ** Find a specific target or return null
  static NodeJsCmd? find(Str name)
  {
    list.find |t| { t.name == name || t.aliases.contains(name) }
  }

  ** List installed commands
  static NodeJsCmd[] list()
  {
    NodeJsCmd[] acc := NodeJsCmd#.pod.types.mapNotNull |t->NodeJsCmd?|
    {
      if (t.isAbstract || !t.fits(NodeJsCmd#)) return null
      return t.make
    }
    acc.sort |a, b| { a.name <=> b.name }
    return acc
  }

  ** App name is "nodeJs {name}"
  override final Str appName() { "nodeJs ${name}" }

  ** Log name is "nodeJs"
  override Log log() { Log.get("nodeJs") }

  ** Command name
  abstract Str name()

  ** Command aliases/shortcuts
  virtual Str[] aliases() { Str[,] }

  ** Run the command. Return zero on success
  abstract override Int run()

  ** Single line summary of the command for help
  abstract Str summary()

  @Opt { help="Verbose debug output"; aliases=["v"] }
  Bool verbose

  @Opt { help = "Root directory for staging Node.js environment"; aliases = ["d"] }
  virtual File dir := Env.cur.tempDir.plus(`nodeJs/`)

  @Opt { help = "Emit CommonJs" }
  Bool cjs := false

//////////////////////////////////////////////////////////////////////////
// NodeJs
//////////////////////////////////////////////////////////////////////////

  protected Bool checkForNode()
  {
    cmd := ["which", "-s", "node"]
    if ("win32" == Env.cur.os) cmd = ["where", "node"]
    if (Process(cmd) { it.out = null }.run.join != 0)
    {
      err("Node not found")
      printLine("Please ensure Node.js is installed and available in your PATH")
      return false
    }
    return true
  }

  ** Get the module system environment
  once ModuleSystem ms()
  {
    return this.cjs ? CommonJs(this.dir) : Esm(this.dir)
  }

  ** Get the JS emit utility
  internal once EmitUtil emit() { EmitUtil(this) }

//////////////////////////////////////////////////////////////////////////
// Console
//////////////////////////////////////////////////////////////////////////

  ** Print a line to stdout
  Void printLine(Str line := "") { Env.cur.out.printLine(line) }

  ** Print error message and return 1
  Int err(Str msg) { printLine("ERROR: ${msg}"); return 1 }


}
