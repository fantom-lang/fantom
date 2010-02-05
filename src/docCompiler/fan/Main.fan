//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   5 May 06  Brian Frank  Creation
//

using util
using compiler

**
** Main is the main entry point for the Fantom documentation compiler.
**
class Main : AbstractMain
{

//////////////////////////////////////////////////////////////////////////
// Options
//////////////////////////////////////////////////////////////////////////

  @Opt { help = "Print version information" }
  Bool version := false

  @Opt { help = "Compile top index" }
  Bool topindex := false

  @Opt { help = "Verbose mode (more logging)"; aliases = ["v"] }
  Bool verbose := false

  @Opt { help = "Silent mode (no logging)" }
  Bool silent := false

  @Opt { help = "Output directory for pod file" }
  File? d := null

  @Opt { help = "Directory of source code" }
  File? src := null

  @Arg { help = "Pod name(s) to compile" }
  Str[] pods := Str[,]

//////////////////////////////////////////////////////////////////////////
// Run
//////////////////////////////////////////////////////////////////////////

  override Int run()
  {
    // top level routing
    if (version) return doVersion
    if (topindex) return doTopindex
    if (pods.isEmpty) return usage

    // compile each pod specified
    try
    {
      pods.each |podName|
      {
        c := makeCompiler
        c.pod = Pod.find(podName)
        c.compilePodToHtml
      }
      return 0
    }
    catch (UnknownPodErr e)
    {
      log.err(e.toStr)
      return 1
    }
    catch (CompilerErr err)
    {
      // all errors should already be logged by Compiler
      return 1
    }
    catch (Err e)
    {
      log.err("Internal compiler error", e)
      return 1
    }
  }

  private DocCompiler makeCompiler()
  {
    c := DocCompiler()
    if (silent)      c.log.level = LogLevel.silent
    if (verbose)     c.log.level = LogLevel.debug
    if (d != null)   c.outDir = d
    if (src != null) c.srcDir = src
    return c
  }

//////////////////////////////////////////////////////////////////////////
// Top Index
//////////////////////////////////////////////////////////////////////////

  private Int doTopindex()
  {
    try
    {
      makeCompiler.compileTopIndexToHtml
      return 0
    }
    catch (Err e)
    {
      log.err("Topindex failed", e)
      return 1
    }
  }

//////////////////////////////////////////////////////////////////////////
// Version
//////////////////////////////////////////////////////////////////////////

  private Int doVersion(OutStream out := Env.cur.out)
  {
    out.printLine("Fantom Doc Compiler ${Pod.of(this).version}")
    out.printLine("Copyright (c) 2007, Brian Frank and Andy Frank")
    out.printLine("Licensed under the Academic Free License version 3.0")
    return 1
  }
}