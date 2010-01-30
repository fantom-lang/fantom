//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   3 Nov 06  Brian Frank  Creation
//

**
** BuildGroup is the base class for build scripts which compose
** a set of children build scripts into a single group.  The
** target's of a BuildGroup are the union of the target
** names available in the children scripts.
**
abstract class BuildGroup : BuildScript
{

//////////////////////////////////////////////////////////////////////////
// Meta-Data
//////////////////////////////////////////////////////////////////////////

  **
  ** Required list of Uris relative to this scriptDir of
  ** Fantom build script files to group together.
  **
  Uri[] childrenScripts := Uri[,]

//////////////////////////////////////////////////////////////////////////
// Setup
//////////////////////////////////////////////////////////////////////////

  **
  ** Validate subclass constructor setup required meta-data.
  **
  internal override Void validate()
  {
    // validate required fields
    ok := true
    ok = ok.and(validateReqField("childrenScripts"))
    if (!ok) throw FatalBuildErr.make

    // compile script Uris into BuildScript instances
    children = BuildScript[,]
    resolveFiles(childrenScripts).each |File f|
    {
      log.debug("CompileScript [$f]")
      s := (BuildScript)FanScript(this, f).compile.types.first.make
      s.log = log
      children.add(s)
    }
  }

//////////////////////////////////////////////////////////////////////////
// Targets
//////////////////////////////////////////////////////////////////////////

  **
  ** Assume the default target is "compile".
  **
  override Target defaultTarget()
  {
    return target("compile")
  }

  **
  ** BuildGroup publishes the union by name
  ** of it's children script targets.
  **
  override Target[] makeTargets()
  {
    // get union of names in my children scripts
    Str[]? names := null
    children.each |BuildScript child|
    {
      // get all the target names in this subscript
      Str[] n := child.targets.map |Target t->Str| { t.name }

      // get union of names
      if (names == null)
        names = n
      else
        names = names.union(n)
    }

    // add my own targets, which trump children targets in toTarget
    myTargets := super.makeTargets
    myTargets.each |Target t| { if (!names.contains(t.name)) names.add(t.name) }

    // now create a Target for each name
    return names.map |Str name->Target| { toTarget(name, myTargets) }
  }

  **
  ** Make a target which will run the specified target
  ** name on all my children scripts.
  **
  private Target toTarget(Str name, Target[] myTargets)
  {
    // my explicit targets trump children targets
    myTarget := myTargets.find |Target t->Bool| { return t.name == name }
    if (myTarget != null) return myTarget

    // make a target which runs on the children scripts
    return Target(this, name, "run '$name' on all children") |->| { runOnChildren(name) }
  }

  **
  ** Run the specified target name on each of the
  ** children scripts that support the specified name.
  **
  virtual Void runOnChildren(Str targetName)
  {
    children.each |BuildScript child, Int i|
    {
      target := child.target(targetName, false)
      if (target != null) target.run
    }
  }

  **
  ** Run the specified target name on each of the children
  ** scripts that support the specified name.  Unlike runOnChildren
  ** this method actually spawns a new process to run the child
  ** script.
  **
  virtual Void spawnOnChildren(Str targetName)
  {
    fanExe := (binDir + "fan$exeExt".toUri).osPath
    children.each |BuildScript child, Int i|
    {
      target := child.target(targetName)
      if (target != null)
      {
        Exec(this, [fanExe, child.scriptFile.osPath, targetName]).run
      }
    }
  }

//////////////////////////////////////////////////////////////////////////
// Debug Env Target
//////////////////////////////////////////////////////////////////////////

  @target="Dump env details to help build debugging"
  override Void dumpEnv()
  {
    super.dumpEnv
    runOnChildren("dumpEnv")
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  ** Compiled children scripts
  BuildScript[]? children

}