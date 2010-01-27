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
    initEnv
    try
    {
      setup
      validate
      targets = makeTargets.ro
    }
    catch (Err err)
    {
      log.err("Error initializing script [$scriptFile.osPath]")
      throw err
    }
  }

//////////////////////////////////////////////////////////////////////////
// Env
//////////////////////////////////////////////////////////////////////////

  ** Log used for error reporting and tracing
  BuildLog log := BuildLog()

  ** The source file of this script
  const File scriptFile := File(typeof->sourceFile.toStr.toUri)

  ** The directory containing the this script
  const File scriptDir := scriptFile.parent

  ** Home directory of development installation.  By default this
  ** value is initialized by `@buildDevHome`, otherwise 'Env.cur.homeDir'`
  ** is used.
  const File devHomeDir := resolveDevHomeDir

  ** {devHomeDir}/bin/
  const File binDir := devHomeDir + `bin/`

  ** {devHomeDir}/lib/
  const File libDir := devHomeDir + `lib/`

  ** {devHomeDir}/lib/fan
  const File libFanDir := devHomeDir + `lib/fan/`

  ** {devHomeDir}/lib/java
  const File libJavaDir := devHomeDir + `lib/java/`

  ** {devHomeDir}/lib/java/ext
  const File libJavaExtDir := devHomeDir + `lib/java/ext/`

  ** {devHomeDir}/lib/java/ext/{Env.cur.platform}
  File libJavaExtPlatformDir := libJavaExtDir + `$Env.cur.platform/`

  ** {devHomeDir}/lib/dotnet
  const File libDotnetDir := devHomeDir + `lib/dotnet/`

  ** Executable extension: ".exe" on Windows and "" on Unix.
  Str exeExt := ""

  ** Compute value for devHomeDir field
  private File resolveDevHomeDir()
  {
    try
    {
      if (@buildDevHome.val != null)
      {
        f := File(@buildDevHome.val)
        if (!f.exists || !f.isDir) throw Err()
        return f
      }
    }
    catch log.err("Invalid URI for @buildDevHome: ${@buildDevHome.val}")
    return Env.cur.homeDir
  }

  **
  ** Initialize the environment
  **
  internal virtual Void initEnv()
  {
    // are we running on a Window's box?
    isWindows = Env.cur.os == "win32"
    exeExt = isWindows ? ".exe" : ""

    // debug
    if (log.isDebug)
    {
      log.printLine("BuildScript Environment:")
      log.printLine("  @buildVersion:    ${@buildVersion.val}")
      log.printLine("  @buildDevHome:    ${@buildDevHome.val}")
      log.printLine("  @buildJdkHome:    ${@buildJdkHome.val}")
      log.printLine("  @buildDotnetHome: ${@buildDotnetHome.val}")
      log.printLine("  scriptFile:       $scriptFile")
      log.printLine("  scriptDir:        $scriptDir")
      log.printLine("  devHomeDir:       $devHomeDir")
      log.printLine("  binDir:           $binDir")
      log.printLine("  libDir:           $libDir")
      log.printLine("  libFanDir:        $libFanDir")
      log.printLine("  libJavaDir:       $libJavaDir")
      log.printLine("  libDotnetDir:     $libDotnetDir")
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
    return typeof->sourceFile.toStr
  }

//////////////////////////////////////////////////////////////////////////
// Targets
//////////////////////////////////////////////////////////////////////////

  **
  ** Return the default target to execute when this script is run.
  ** If this method is not overridden, then the default is to
  ** return the first target declared in the script itself.
  **
  virtual Target defaultTarget()
  {
    targets := makeTargets
    if (targets.isEmpty) throw Err("No targets declared")
    def := targets.find |Target t->Bool| { !t.name.startsWith("dump") }
    return def ?: targets.first
  }

  **
  ** Lookup a target by name.  If not found and checked is
  ** false return null, otherwise throw an exception.  This
  ** method cannot be called until after the script has completed
  ** its constructor.
  **
  Target? target(Str name, Bool checked := true)
  {
    if ((Obj?)targets == null) throw Err("script not setup yet")
    t := targets.find |Target t->Bool| { return t.name == name }
    if (t != null) return t
    if (checked) throw Err("Target not found '$name' in $scriptFile")
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
    typeof.methods.each |Method m|
    {
      description := m.facet(@target)
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

      targets.add(Target(this, m.name, description, toFunc(m)))
    }
    return targets
  }

  private Func toFunc(Method m) { return |->| { m.callOn(this, null) } }

//////////////////////////////////////////////////////////////////////////
// Debug Env Target
//////////////////////////////////////////////////////////////////////////

  @target="Dump env details to help build debugging"
  virtual Void dumpenv()
  {
    log.out.printLine("---------------")
    log.out.printLine("  scriptFile:   $scriptFile [$typeof.base]")
    log.out.printLine("  Env.homeDir:  $Env.cur.homeDir")
    log.out.printLine("  Env.workDir:  $Env.cur.workDir")
    log.out.printLine("  devHomeDir:   $devHomeDir")
    log.level = LogLevel.warn // suppress success message
  }

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
      log.err("No targets available for script")
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
          log.err("Unknown build target '$arg'")
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
      n := t.name == def.name ? "${t.name}*" : "${t.name} "
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
    val := typeof.field(field).get(this)
    if (val != null) return true
    log.err("Required field not set: '$field' [$toStr]")
    return false
  }

  **
  ** Convert a Uri to a directory and verify it exists.
  **
  internal File? resolveDir(Uri? uri, Bool nullOk := false)
  {
    return resolveUris([uri], nullOk, true)[0]
  }

  **
  ** Convert a Uri to a file and verify it exists.
  **
  internal File? resolveFile(Uri? uri, Bool nullOk := false)
  {
    return resolveUris([uri], nullOk, false)[0]
  }

  **
  ** Convert a list of Uris to directories and verify they all exist.
  **
  internal File?[] resolveDirs(Uri?[]? uris, Bool nullOk := false)
  {
    return resolveUris(uris, nullOk, true)
  }

  **
  ** Convert a list of Uris to files and verify they all exist.
  **
  internal File?[] resolveFiles(Uri?[]? uris, Bool nullOk := false)
  {
    return resolveUris(uris, nullOk, false)
  }

  private File?[] resolveUris(Uri?[]? uris, Bool nullOk, Bool expectDir)
  {
    files := File?[,]
    if (uris == null) return files

    files.capacity = uris.size
    ok := true
    uris.each |Uri? uri|
    {
      if (uri == null)
      {
        if (!nullOk) throw FatalBuildErr("Unexpected null Uri")
        files.add(null)
        return
      }

      file := scriptDir + uri
      if (!file.exists || file.isDir != expectDir )
      {
        ok = false
        if (expectDir)
          log.err("Invalid directory [$uri]")
        else
          log.err("Invalid file [$uri]")
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
    log.err(msg, err)
    return FatalBuildErr(msg, err)
  }

//////////////////////////////////////////////////////////////////////////
// Main
//////////////////////////////////////////////////////////////////////////

  **
  ** Run the script with the specified arguments.
  ** Return 0 on success or -1 on failure.
  **
  Int main(Str[] args := Env.cur.args)
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
      log.err("Internal build error [$toStr]")
      err.trace
    }
    t2 := Duration.now

    if (success)
    {
      if (log.level <= LogLevel.info)
        log.out.printLine("BUILD SUCCESS [${(t2-t1).toMillis}ms]!")
    }
    else
    {
      log.out.printLine("BUILD FAILED [${(t2-t1).toMillis}ms]!")
    }
    return success ? 0 : -1
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  ** Targets available on this script (see `makeTargets`)
  readonly Target[] targets := Target#.emptyList

  ** Targets specified to run by command line
  Target[]? toRun

  ** Are we running on a Window's box
  internal Bool isWindows

}