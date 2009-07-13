//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   4 Nov 06  Brian Frank  Creation
//

**
** Target models a build target which may be executed independently
** within a build script.  Targets are the top level unit for organizing
** build scripts - each script publishes its available targets via
** `BuildScript.targets`.
**
class Target
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  **
  ** Construct a target to run under the specified build script.
  ** The name is the key used to invoke this target from the command
  ** line. Description is used for usage summary.  Func is invoked
  ** when this target is executed.
  **
  new make(BuildScript script, Str name, Str description, Func func)
  {
    this.script      = script
    this.name        = name
    this.description = description
    this.func        = func
  }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  **
  ** Return the parent build script associated with this task.
  **
  readonly BuildScript script

  **
  ** Name is the key used to invoke this target from the command line.
  **
  readonly Str name

  **
  ** Description is used for usage summary.
  **
  readonly Str description

  **
  ** Function to invoke when this target is executed.
  **
  readonly Func func

  **
  ** Return name.
  **
  override Str toStr() { return name }

//////////////////////////////////////////////////////////////////////////
// Run
//////////////////////////////////////////////////////////////////////////

  **
  ** Run this target by invoking the target's method.  If the target
  ** fails to run then it should report errors via the log and throw
  ** FatalBuildErr.
  **
  virtual Void run()
  {
    try
    {
      func.call
    }
    catch (FatalBuildErr err)
    {
      throw err
    }
    catch (Err err)
    {
      script.log.error("Target '$name' failed [$script.toStr]")
      err.trace
      throw FatalBuildErr(null, err)
    }
  }

}