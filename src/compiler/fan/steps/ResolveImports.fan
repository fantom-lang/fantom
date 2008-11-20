//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   26 Dec 05  Brian Frank  Creation
//    5 Jun 06  Brian Frank  Ported from Java to Fan
//

**
** ResolveImports maps every Using node in each CompilationUnit to a pod
** and ensures that it exists and that no imports are duplicated.  Then we
** create a map for all the types which are imported into the CompilationUnit
** so that the Parser can quickly distinguish between a type identifier and
** other identifiers.  The results of this step populate Using.resolvedXXX and
** CompilationUnit.importedTypes.
**
class ResolveImports : CompilerStep
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
    resolved[compiler.pod.name] = compiler.pod
  }

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  **
  ** Run the step
  **
  override Void run()
  {
    log.debug("ResolveImports")

    // process each unit for Import.pod
    units.each |CompilationUnit unit|
    {
      resolveImports(unit)
    }
    bombIfErr

    // process each unit for CompilationUnit.importedTypes
    units.each |CompilationUnit unit|
    {
      resolveImportedTypes(unit)
    }
    bombIfErr
  }

  **
  ** Resolve all the imports in the specified unit
  ** and ensure there are no duplicates.
  **
  private Void resolveImports(CompilationUnit unit)
  {
    // map to keep track of duplicate imports
    // within this compilation unit
    dups := Str:Using[:]

    // process each import statement (remember the
    // first one is an implicit import of sys)
    unit.usings.each |Using u|
    {
      podName := u.podName

      // check that this podName was in the compiler's
      // input dependencies
      checkUsingPod(this, podName, u.location)

      // don't allow a using my own pod
      if (u.typeName == null && u.podName == compiler.pod.name)
        err("Using '$u.podName' is on pod being compiled", u.location)

      // check for duplicate imports
      key := podName
      if (u.typeName != null) key += "::$u.typeName"
      if (dups.containsKey(key))
      {
        err("Duplicate using '$key'", u.location)
        return
      }
      dups[key] = u

      // if already resolved, then just use it
      u.resolvedPod = resolved[podName]

      // resolve the import and cache in resolved map
      if (u.resolvedPod == null)
      {
        try
        {
          pod := ns.resolvePod(podName, u.location)
          resolved[podName] = u.resolvedPod = pod
        }
        catch (CompilerErr e)
        {
          errReport(e)
          return
        }
      }

      // if type specified, then resolve type
      if (u.typeName != null)
      {
        u.resolvedType = u.resolvedPod.resolveType(u.typeName, false)
        if (u.resolvedType== null)
        {
          err("Type not found in pod '$podName::$u.typeName'", u.location)
          return
        }
      }
    }
  }

  **
  ** Create a unified map of type names to CType[] for all the
  ** imports in the specified unit (this includes types within
  ** the pod being compilied itself).  For example if foo::Thing
  ** and bar::Thing are imported, then importedTypes would contain
  **   "Thing" : [foo::Thing, bar::Thing]
  **
  private Void resolveImportedTypes(CompilationUnit unit)
  {
    // name -> CType[]
    types := Str:CType[][:]

    // add types for my own pod
    addAll(types, compiler.pod.types)

    // add pod level imports first
    unit.usings.each |Using u|
    {
      if (u.typeName == null)
        addAll(types, u.resolvedPod.types)
    }

    // add type specific imports last (these
    // override any pod level imports)
    unit.usings.each |Using u|
    {
      if (u.typeName != null)
      {
        if (u.asName == null)
        {
          types[u.typeName] = [u.resolvedType]
        }
        else
        {
          remove(types, u.resolvedType)
          types[u.asName] = [u.resolvedType]
        }
      }
    }

    /*
    // dump
    echo("--- types for $unit")
    ids := types.keys.sort
    ids.each |Str id| { echo("$id = ${types[id]}") }
    */

    // save away on unit
    unit.importedTypes = types
  }

  private Void addAll(Str:CType[] types, CType[] toAdd)
  {
    toAdd.each |CType t|
    {
      list := types[t.name]
      if (list == null) types[t.name] = list = CType[,]
      list.add(t)
    }
  }

  private Void remove(Str:CType[] types, CType t)
  {
    list := types[t.name]
    if (list != null)
    {
      for (i:=0; i<list.size; ++i)
        if (list[i].qname == t.qname) { list.removeAt(i); break }
    }
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  **
  ** Resolve a fully qualified type name into its CType representation.
  ** This may be a TypeDef within the compilation units or could be
  ** an imported type.  If the type name cannot be resolved then we
  ** log an error and return null.
  **
  static CType? resolveQualified(CompilerSupport cs, Str podName, Str typeName, Location location)
  {
    // first check pod being compiled
    if (podName == cs.compiler.pod.name)
    {
      t := cs.compiler.pod.resolveType(typeName, false)
      if (t == null)
      {
        cs.err("Type '$typeName' not found within pod being compiled", location)
        return null
      }
      return t
    }

    // otherwise we need to try to resolve pod
    CPod? pod := null
    try
    {
      pod = cs.ns.resolvePod(podName, location)
    }
    catch (CompilerErr e)
    {
      cs.errReport(e)
      return null
    }

    // check that we have a dependency on the pod
    checkUsingPod(cs, podName, location)

    // now try to lookup type
    t := pod.resolveType(typeName, false)
    if (t == null)
    {
      cs.err("Type '$typeName' not found in pod '$podName'", location);
      return null
    }

    return t
  }

  **
  ** Check that a pod name is in the dependency list.
  **
  static Void checkUsingPod(CompilerSupport cs, Str podName, Location loc)
  {
    if (!cs.ns.depends.containsKey(podName) &&
        cs.compiler.pod.name != podName &&
        !cs.compiler.input.isScript)
    {
      cs.err("Using '$podName' which is not a declared dependency for '$cs.compiler.pod.name'", loc)
    }
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  Str:CPod resolved := Str:CPod[:]  // reuse CPods across units

}