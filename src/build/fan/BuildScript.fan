//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   3 Nov 06  Brian Frank  Creation
//

using compiler

**
** BuildScript is the base class for build scripts - it manages
** the command line interface, argument parsing, environment, and
** target execution.
**
** See `docTools::Build` for details.
**
abstract class BuildScript
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  **
  ** Construct a new build script.
  **
  new make()
  {
    log = BuildLog.make
    initEnv
    try
    {
      setup
      validate
      targets = makeTargets.ro
    }
    catch (Err err)
    {
      log.error("Error initializing script [$scriptFile.osPath]")
      throw err
    }
  }

//////////////////////////////////////////////////////////////////////////
// Env
//////////////////////////////////////////////////////////////////////////

  ** The source file of this script
  File scriptFile

  ** The directory containing the this script
  File scriptDir

  ** Home directory of development installation.  By default this
  ** value is initialized by Sys.env["fan.build.devHome"], otherwise
  ** Sys.homeDir is used.
  File devHomeDir

  ** {devHomeDir}/bin/
  File binDir

  ** {devHomeDir}/lib/
  File libDir

  ** {devHomeDir}/lib/fan
  File libFanDir

  ** {devHomeDir}/lib/java
  File libJavaDir

  ** {devHomeDir}/lib/java/ext
  File libJavaExtDir

  ** {devHomeDir}/lib/java/ext/{os} or null if unknown.
  ** Currently we map to os:
  **   - Windows   => "win"
  **   - MAC OS X  => "mac"
  **   - Linux     => "linux"
  File libJavaExtOsDir

  ** {devHomeDir}/lib/net
  File libNetDir

  ** This is the global default version to use when building pods.  It
  ** is initialized by Sys.env["fan.build.globalVersion"], otherwise
  ** "0.0.0" is used as a default.
  Version globalVersion

  ** Executable extension: ".exe" on Windows and "" on Unix.
  Str exeExt

  **
  ** Initialize the environment
  **
  private Void initEnv()
  {
    // init devHomeDir
    devHomeDir = Sys.homeDir
    devHomeProp := Sys.env["fan.build.devHome"]
    if (devHomeProp != null)
    {
      try
      {
        f := File.make(devHomeProp.toUri)
        if (!f.exists || !f.isDir) throw Err.make
        devHomeDir = f
      }
      catch
      {
        log.error("Invalid URI for fan.build.devHome: $devHomeProp")
      }
    }

    // global version
    globalVersion = Version.fromStr("0.0.0")
    globalVersionProp := Sys.env["fan.build.globalVersion"]
    if (globalVersionProp != null)
    {
      try
      {
        globalVersion = Version.fromStr(globalVersionProp)
      }
      catch
      {
        log.error("Invalid Version for fan.build.globalVersion: $globalVersionProp")
      }
    }

    // are we running on a Window's box?
    osName := Sys.env.get("os.name", "?").lower
    isWindows = osName.contains("win")

    // exeExt
    exeExt = isWindows ? ".exe" : ""

    // directories
    scriptFile    = File.make(type->sourceFile.toStr.toUri)
    scriptDir     = scriptFile.parent
    binDir        = devHomeDir + `bin/`
    libDir        = devHomeDir + `lib/`
    libFanDir     = devHomeDir + `lib/fan/`
    libJavaDir    = devHomeDir + `lib/java/`
    libJavaExtDir = devHomeDir + `lib/java/ext/`
    libNetDir     = devHomeDir + `lib/net/`

    // try and figure out which lib/ext/{os} to use - this
    // is really going to work long term because it doesn't
    // address the variations in os/microprocessors
    if (isWindows)
      libJavaExtOsDir = libJavaExtDir + `win/`
    else if (osName.contains("os x"))
      libJavaExtOsDir = libJavaExtDir + `mac/`
    else if (osName.contains("linux"))
      libJavaExtOsDir = libJavaExtDir + `linux/`

    // debug
    if (log.isDebug)
    {
      log.printLine("BuildScript Environment:")
      log.printLine("  scriptFile:    $scriptFile")
      log.printLine("  scriptDir:     $scriptDir")
      log.printLine("  devHomeDir:    $devHomeDir")
      log.printLine("  binDir:        $binDir")
      log.printLine("  libDir:        $libDir")
      log.printLine("  libFanDir:     $libFanDir")
      log.printLine("  libJavaDir:    $libJavaDir")
      log.printLine("  libNetDir:     $libNetDir")
      log.printLine("  globalVersion: $globalVersion")
    }
  }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  **
  ** Return this script's source file path.
  **
  override Str toStr()
  {
    return type->sourceFile.toStr
  }

//////////////////////////////////////////////////////////////////////////
// Targets
//////////////////////////////////////////////////////////////////////////

  **
  ** Return the default target to execute when this script is run.
  **
  abstract Target defaultTarget()

  **
  ** Lookup a target by name.  If not found and checked is
  ** false return null, otherwise throw an exception.  This
  ** method cannot be called until after the script has completed
  ** its constructor.
  **
  Target? target(Str name, Bool checked := true)
  {
    if (targets == null) throw Err.make("script not setup yet")
    t := targets.find |Target t->Bool| { return t.name == name }
    if (t != null) return t
    if (checked) throw Err.make("Target not found: $name")
    return null
  }

  **
  ** This callback is invoked by the 'BuildScript' constructor after
  ** the call to `setup` to initialize the list of the targets this
  ** script publishes.  The list of  targets is built from all the
  ** methods annotated with the "target" facet.  The "target" facet
  ** should have a string value with a description of what the target
  ** does.
  **
  virtual Target[] makeTargets()
  {
    targets := Target[,]
    type.methods.each |Method m|
    {
      description := m.facet("target")
      if (description == null) return

      if (!(description is Str))
      {
        log.warn("Invalid target facet ${m.qname}@target")
        return
      }

      if (m.params.size > 0 && !m.params.first.hasDefault)
      {
        log.warn("Invalid target method ${m.qname}")
        return
      }

      targets.add(Target.make(this, m.name, description, toFunc(m)))
    }
    return targets
  }

  // TODO: need Func.curry
  private Func toFunc(Method m) { return |,| { m.callOn(this, null) } }

//////////////////////////////////////////////////////////////////////////
// Arguments
//////////////////////////////////////////////////////////////////////////

  **
  ** Parse the arguments passed from the command line.
  ** Return true for success or false to end the script.
  **
  private Bool parseArgs(Str[] args)
  {
    // check for usage
    if (args.contains("-?") || args.contains("-help"))
    {
      usage
      return false
    }

    success := true
    toRun = Target[,]

    // get published targetss
    published := targets
    if (published.isEmpty)
    {
      log.error("No targets available for script")
      return false
    }

    // process each argument
    for (i:=0; i<args.size; ++i)
    {
      arg := args[i]
      if (arg == "-v") log.level = LogLevel.debug
      else if (arg.startsWith("-")) log.warn("Unknown build option $arg")
      else
      {
        // add target to our run list
        target := published.find |Target t->Bool| { return t.name == arg }
        if (target == null)
        {
          log.error("Unknown build target '$arg'")
          success = false
        }
        else
        {
          toRun.add(target)
        }
      }
    }

    // if no targets specified, then use the default
    if (toRun.isEmpty)
      toRun.add(defaultTarget)

    // return success flag
    return success
  }

  **
  ** Dump usage including all this script's published targets.
  **
  private Void usage()
  {
    log.printLine("usage: ")
    log.printLine("  build [options] <target>*")
    log.printLine("options:")
    log.printLine("  -? -help       print usage summary")
    log.printLine("  -v             verbose debug logging")
    log.printLine("targets:")
    def := defaultTarget
    targets.each |Target t, Int i|
    {
      n := t == def ? "${t.name}*" : "${t.name} "
      log.print("  ${n.justl(14)} $t.description")
      log.printLine
    }
  }

//////////////////////////////////////////////////////////////////////////
// Setup
//////////////////////////////////////////////////////////////////////////

  **
  ** The setup callback is invoked before creating or processing of
  ** any targets to ensure that the BuildScript is correctly initialized.
  ** If the script cannot be setup then report errors via the log and
  ** throw FatalBuildErr to terminate the script.
  **
  virtual Void setup()
  {
  }

  **
  ** Internal callback to validate setup
  **
  internal virtual Void validate()
  {
  }

  **
  ** Check that the specified field is non-null, if not
  ** then log an error and return false.
  **
  internal Bool validateReqField(Str field)
  {
    val := type.field(field).get(this)
    if (val != null) return true
    log.error("Required field not set: '$field' [$toStr]")
    return false
  }

  **
  ** Convert a Uri to a directory and verify it exists.
  **
  internal File? resolveDir(Uri uri, Bool nullOk := false)
  {
    return resolveUris([uri], nullOk, true)[0]
  }

  **
  ** Convert a Uri to a file and verify it exists.
  **
  internal File? resolveFile(Uri uri, Bool nullOk := false)
  {
    return resolveUris([uri], nullOk, false)[0]
  }

  **
  ** Convert a list of Uris to directories and verify they all exist.
  **
  internal File?[] resolveDirs(Uri[] uris, Bool nullOk := false)
  {
    return resolveUris(uris, nullOk, true)
  }

  **
  ** Convert a list of Uris to files and verify they all exist.
  **
  internal File?[] resolveFiles(Uri[] uris, Bool nullOk := false)
  {
    return resolveUris(uris, nullOk, false)
  }

  private File?[] resolveUris(Uri[] uris, Bool nullOk, Bool expectDir)
  {
    files := File?[,]
    if (uris == null) return files

    files.capacity = uris.size
    ok := true
    uris.each |Uri uri|
    {
      if (uri == null)
      {
        if (!nullOk) throw FatalBuildErr.make("Unexpected null Uri")
        files.add(null)
        return
      }

      file := scriptDir + uri
      if (!file.exists || file.isDir != expectDir )
      {
        ok = false
        if (expectDir)
          log.error("Invalid directory [$uri]")
        else
          log.error("Invalid file [$uri]")
      }
      files.add(file)
    }
    if (!ok) throw FatalBuildErr.make
    return files
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  **
  ** Log an error and return a FatalBuildErr instance
  **
  FatalBuildErr fatal(Str msg, Err? err := null)
  {
    log.error(msg, err)
    return FatalBuildErr.make
  }

//////////////////////////////////////////////////////////////////////////
// Main
//////////////////////////////////////////////////////////////////////////

  **
  ** Run the script with the specified arguments.
  ** Return 0 on success or -1 on failure.
  **
  Int main(Str[] args := Sys.args)
  {
    t1 := Duration.now
    success := false
    try
    {
      if (!parseArgs(args)) return -1
      toRun.each |Target t| { t.run }
      success = true
    }
    catch (FatalBuildErr err)
    {
      // error should have alredy been logged
    }
    catch (Err err)
    {
      log.error("Internal build error [$toStr]")
      err.trace
    }
    t2 := Duration.now

    if (success)
      echo("BUILD SUCCESS [${(t2-t1).toMillis}ms]!")
    else
      echo("BUILD FAILED [${(t2-t1).toMillis}ms]!")
    return success ? 0 : -1
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  ** Log used for error reporting and tracing
  BuildLog log

  ** Targets available on this script (see `makeTargets`)
  readonly Target[] targets

  ** Targets specified to run by command line
  Target[] toRun

  ** Are we running on a Window's box
  internal Bool isWindows

}