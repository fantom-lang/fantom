//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   26 Dec 05  Brian Frank  Creation
//    5 Jun 06  Brian Frank  Ported from Java to Fan
//

**
** ResolveDepends resolves each dependency to a CPod and
** checks the version.  We also set CNamespace.depends in
** this step.
**
class ResolveDepends : CompilerStep
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  **
  ** Constructor takes the associated Compiler
  **
  new make(Compiler compiler)
    : super(compiler)
  {
    loc = compiler.input.inputLoc
  }

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  **
  ** Run the step
  **
  override Void run()
  {
    log.debug("ResolveDepends")

    // if the input has no dependencies, then
    // assume a dependency on sys
    input := compiler.input
    isSys := input.podName == "sys"
    if (input.depends.isEmpty && !isSys)
      compiler.input.depends.add(Depend.fromStr("sys 0+"))

    // we initialize the CNamespace.depends map
    // as we process each dependency
    ns.depends = Str:Depend[:]

    // process each dependency
    input.depends.each |Depend depend|
    {
      ns.depends[depend.name] = depend
      resolveDepend(depend)
    }

    // check that everything has a dependency on sys
    if (!ns.depends.containsKey("sys") && !isSys)
      err("All pods must have a dependency on 'sys'", loc)

    bombIfErr
  }

  **
  ** Resolve the dependency via reflection using
  ** the pods the compiler is running against.
  **
  private Void resolveDepend(Depend depend)
  {
    CPod? pod := null
    try
    {
      pod = ns.resolvePod(depend.name, loc)
    }
    catch (CompilerErr e)
    {
      err("Cannot resolve depend: pod '$depend.name' not found", loc)
      return
    }

    if (!depend.match(pod.version))
    {
      err("Cannot resolve depend: '$pod.name $pod.version' != '$depend'", loc)
      return
    }
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  Location loc

}