//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   4 Nov 06  Brian Frank  Creation
//

using compiler

**
** Run the Java compiler to produce a directory of Java classfiles.
**
class CompileJava : JdkTask
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  **
  ** Construct uninitialized javac task
  **
  new make(BuildScript script)
    : super(script)
  {
    cp.add(rtJar)
  }

//////////////////////////////////////////////////////////////////////////
// Configuration
//////////////////////////////////////////////////////////////////////////

  **
  ** Extra parameters to pass to javac.  Default is
  ** to target 1.5 classfiles.
  **
  Str[] params := ["-target", "1.5"]

//////////////////////////////////////////////////////////////////////////
// Add
//////////////////////////////////////////////////////////////////////////

  **
  ** Add all the jars found in lib/java/ext and lib/java/ext/os
  ** to the class path.
  **
  Void cpAddExtJars()
  {
    cpAddJars(script.devHomeDir + `lib/java/ext/`)
    cpAddJars(script.devHomeDir + `lib/java/ext/$Env.cur.platform/`)
  }

  **
  ** Add all the jar files found in the specified
  ** directory to the classpath.
  **
  Void cpAddJars(File dir)
  {
    dir.list.each |File f| { if (f.ext == "jar") cp.add(f) }
  }

//////////////////////////////////////////////////////////////////////////
// Run
//////////////////////////////////////////////////////////////////////////

  **
  ** Run the javac task
  **
  override Void run()
  {
    log.info("CompileJava")

    try
    {
      // build command
      cmd := [javacExe]

      cmd.addAll(params)

      // -d outDir
      if (outDir != null)
      {
        cmd.add("-d").add(outDir.osPath)
      }

      // -cp <classpath>
      cmd.add("-cp")
      cmd.add(cp.join(File.pathSep) |File f->Str| { return f.osPath })

      // src files/dirs
      listFiles(cmd, src)
      log.debug(cmd.join(" "))
      r := Process(cmd).run.join
      if (r != 0) throw Err.make
    }
    catch (Err err)
    {
      throw fatal("CompileJava failed")
    }
  }

  internal Void listFiles(Str[] list, File[] files)
  {
    files.each |File f|
    {
      if (f.isDir) listFiles(list, f.list)
      else if (f.ext == "java") list.add(f.osPath)
    }
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  ** Class path - list of jars to compile against,
  ** rt.jar is automatically included
  File[] cp := File[,]

  ** List of source files or directories to compile.  If
  ** a directory is specified, then it is recursively searched
  ** for all ".java" files.
  File[] src := File[,]

  ** Output directory
  File? outDir


}