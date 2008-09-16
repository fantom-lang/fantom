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
// Add
//////////////////////////////////////////////////////////////////////////

  **
  ** Add all the jars found in lib/java/ext and lib/java/ext/os
  ** to the class path.
  **
  Void cpAddExtJars()
  {
    cpAddJars(script.libJavaExtDir)
    cpAddJars(script.libJavaExtOsDir)
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
      cmd := [javacExe.osPath]

      // -d outDir
      if (outDir != null)
      {
        cmd.add("-d").add(outDir.osPath)
      }

      // -cp <classpath>
      cmd.add("-cp")
      cmd.add(cp.join(File.pathSep) |File f->Str| { return f.osPath })

      // src files/dirs
      src.each |File f|
      {
        if (f.isDir)
        {
          f.list.each |File x| { if (x.ext == "java") cmd.add(x.osPath) }
        }
        else
        {
          cmd.add(f.osPath)
        }
      }
      log.debug(cmd.join(" "))
      r := Process.make(cmd).run.join
      if (r != 0) throw Err.make
    }
    catch (Err err)
    {
      throw fatal("CompileJava failed")
    }
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  ** Class path - list of jars to compile against,
  ** rt.jar is automatically included
  File[] cp := File[,]

  ** List of source files or directories to compile
  File[] src := File[,]

  ** Output directory
  File outDir


}