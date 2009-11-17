//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   5 May 06  Brian Frank  Creation
//

using compiler

**
** Main is the main entry point for the Fantom documentation compiler.
**
class Main
{

//////////////////////////////////////////////////////////////////////////
// Run
//////////////////////////////////////////////////////////////////////////

  **
  ** Main entry point for compiler.  Return 0 on success.
  **
  Int run(Str[] args)
  {
    t1 := Duration.now
    success := true

    // process args
    if (!parseArgs(args)) return 0

    // process each directory specified
    try
    {
      pipeline.callList([compiler])
    }
    catch (CompilerErr err)
    {
      // all errors should already be logged by Compiler
      success = false
    }
    catch (Err err)
    {
      compiler.log.compilerErr(CompilerErr("Internal compiler error", null, err))
      err.trace
      success = false
    }

    t2 := Duration.now
    if (success)
    {
      println("SUCCESS (" + (t2-t1).toMillis + "ms)")
      return 0
    }
    else
    {
      println("FAILED (" + (t2-t1).toMillis + "ms)")
      return -1
    }
  }

  **
  ** Process command line args and return false if we should exit.
  **
  Bool parseArgs(Str[] args)
  {
    if (args.isEmpty)
    {
      help
      return false
    }

    enoughArgs := false
    for (i:=0; i<args.size; ++i)
    {
      a := args[i]
      if (a.isEmpty) continue
      if (a == "-help" || a == "-h" || a == "-?")
      {
        help
        return false
      }
      else if (a == "-version")
      {
        version
        return false
      }
      else if (a == "-d")
      {
        if (i+1 >= args.size)
        {
          println("ERROR: must specified dir with -d option")
          return false
        }
        compiler.outDir = File(args[++i].toUri).normalize
      }
      else if (a == "-v")
      {
        compiler.log.level = LogLevel.debug
      }
      else if (a == "-silent")
      {
        compiler.log.level = LogLevel.silent
      }
      else if (a == "-topindex")
      {
        pipeline = |DocCompiler c| { c.compileTopIndexToHtml }
        enoughArgs = true
      }
      else if (a[0] == '-')
      {
        println("WARNING: Unknown option " + a)
      }
      else
      {
        compiler.pod = Pod.find(a, false)
        if (compiler.pod == null)
        {
          println("ERROR: Pod not found: $a")
          return false
        }
        enoughArgs = true
      }
    }

    // if no dirs were specified, assume current dir
    if (!enoughArgs)
    {
      println("ERROR: not enough arguments")
      help
      return false
    }

    return true
  }

  **
  ** Dump help usage.
  **
  Void help()
  {
    println("Fantom Doc Compiler")
    println("Usage:")
    println("  docCompiler [options] <podName>")
    println("Options:")
    println("  -help, -h, -?  print usage help")
    println("  -version       print version information")
    println("  -d <dir>       output directory for pod file")
    println("  -v             verbose mode (more logging)")
    println("  -silent        silent mode (no logging)")
    println("  -topindex      compile top index")
  }

  **
  ** Dump version.
  **
  Void version()
  {
    println("Fantom Doc Compiler")
    println("Copyright (c) 2007, Brian Frank and Andy Frank")
    println("Licensed under the Academic Free License version 3.0")
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  Void println(Obj s)
  {
    compiler.log.printLine(s)
  }

//////////////////////////////////////////////////////////////////////////
// Main
//////////////////////////////////////////////////////////////////////////

  static Void main()
  {
    Sys.exit(make.run(Sys.args))
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  DocCompiler compiler := DocCompiler();
  |DocCompiler c| pipeline := |DocCompiler c| { c.compilePodToHtml }

}