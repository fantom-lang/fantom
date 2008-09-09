//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   4 Nov 06  Brian Frank  Creation
//

**
** Java Developer Kit task provides a common set of
** environment variables for the Java environment.
**
class JdkTask : Task
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  **
  ** Initialize the JDK environment fields.
  **
  new make(BuildScript script)
    : super(script)
  {
    // jdkHomeDir
    jdkHomeProp := Sys.env["fan.build.jdkHome"]
    try
    {
      jdkHomeDir = jdkHomeProp.toUri.toFile
      if (!jdkHomeDir.exists || !jdkHomeDir.isDir) throw Err.make
    }
    catch
    {
      throw fatal("Missing or invalid URI for fan.build.jdkHome: $jdkHomeProp")
    }

    // derived files
    jdkBinDir = jdkHomeDir + `bin/`
    javaExe   = jdkBinDir  + "java$script.exeExt".toUri
    javacExe  = jdkBinDir  + "javac$script.exeExt".toUri
    jarExe    = jdkBinDir  + "jar$script.exeExt".toUri
    rtJar     = jdkHomeDir + `jre/lib/rt.jar`
  }

//////////////////////////////////////////////////////////////////////////
// Run
//////////////////////////////////////////////////////////////////////////

  **
  ** Run not implemented
  **
  override Void run()
  {
    throw fatal("not implemented")
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  ** Home directory for jdk installation
  ** configured via Sys.env["fan.build.jdkHome"]
  File jdkHomeDir

  ** JDK bin for executables: {jdkHomeDir}/bin/
  File jdkBinDir

  ** Java runtime executable: {jdkBinDir}/java
  File javaExe

  ** Javac compiler executable: {jdkBinDir}/javac
  File javacExe

  ** Jar (Java Archive) executable: {jdkBinDir}/jar
  File jarExe

  ** Standard runtime library jar file: {jdkHomeDir}/jre/lib/rt.jar
  File rtJar

}