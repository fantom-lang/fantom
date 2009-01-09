//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 Sep 05  Brian Frank  Creation
//    3 Jun 06  Brian Frank  Ported from Java to Fan - Megan's b-day
//

**
** Main is the main entry point for the Fan compiler.  It handles
** all the argument processing and misc commands like help, version,
**
class Main
{

//////////////////////////////////////////////////////////////////////////
// Run
//////////////////////////////////////////////////////////////////////////

  **
  ** Main entry point for compiler.
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
      compile
    }
    catch (CompilerErr err)
    {
      // all errors should already be logged by Compiler
      success = false;
    }
    catch (Err err)
    {
      log.compilerErr(CompilerErr.make("Internal compiler error", null, err));
      err.trace
      success = false;
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
        outDir = File.make(args[++i].toUri).normalize
      }
      else if (a == "-src")
      {
        includeSrc = true
      }
      else if (a == "-doc")
      {
        includeDoc = true
      }
      else if (a == "-v")
      {
        log.level = LogLevel.debug
      }
      else if (a == "-silent")
      {
        log.level = LogLevel.silent
      }
      else if (a[0] == '-')
      {
        println("WARNING: Unknown option " + a)
      }
      else
      {
        if (podName == null)
          podName = a
        else
          srcDirs.add(File.make(a.toUri))
      }
    }

    // if no dirs were specified, assume current dir
    if (podName == null || srcDirs.isEmpty)
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
    println("Fan Compiler (the one written in Fan itself)")
    println("Usage:")
    println("  ffanc [options] <podName> <srcDir>*")
    println("Options:")
    println("  -help, -h, -?  print usage help")
    println("  -version       print version information")
    println("  -d <dir>       output directory for pod file")
    println("  -doc           include fandoc in pod")
    println("  -src           include source code in pod")
    println("  -v             verbose debug mode (more logging)")
    println("  -silent        silent mode (no logging)")
  }

  **
  ** Dump version.
  **
  Void version()
  {
    println("Fan Compiler - Version ${type.pod.version}")
    println("Copyright (c) 2006, Brian Frank and Andy Frank")
    println("Licensed under the Academic Free License version 3.0")
  }

  **
  ** Compile using current configuration
  **
  Void compile()
  {
    input := CompilerInput.make
    input.podName    = podName
    input.log        = log
    input.mode       = CompilerInputMode.file
    input.homeDir    = srcDirs.first.parent
    input.srcDirs    = srcDirs
    input.includeDoc = includeDoc
    input.includeSrc = includeSrc
    input.output     = CompilerOutputMode.podFile
    if (outDir != null) input.outDir = outDir

    Compiler.make(input).compile
  }

  **
  ** Compile the script file into a transient pod.
  ** See `sys::Sys.compile` for option definitions.
  **
  static Pod compileScript(Str podName, File file, [Str:Obj]? options := null)
  {
    input := CompilerInput.make
    input.podName        = podName
    input.log.level      = LogLevel.error
    input.isScript       = true
    input.srcStr         = file.readAllStr
    input.srcStrLocation = Location.makeFile(file)
    input.mode           = CompilerInputMode.str
    input.output         = CompilerOutputMode.transientPod

    if (options != null)
    {
      log := options["log"]
      if (log != null) input.log = log

      logOut := options["logOut"]
      if (logOut != null) input.log = CompilerLog(logOut)

      logLevel := options["logLevel"]
      if (logLevel != null) input.log.level = logLevel

      fcodeDump := options["fcodeDump"]
      if (fcodeDump == true) input.fcodeDump = true
    }

    return Compiler.make(input).compile.transientPod
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  Void println(Obj? s)
  {
    log.printLine(s)
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

  Str? podName
  File[] srcDirs := File[,]    // directories to build
  File? outDir := null         // -d output directory
  CompilerLog log := CompilerLog.make  // logging, -v verbose output
  Bool includeDoc := false     // include fandoc in output pod
  Bool includeSrc := false     // include source code in output pod

}