//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   5 Jun 06  Brian Frank  Creation
//

**
** PodDef models the pod being compiled.
**
class PodDef : DefNode, CPod
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  new make(CNamespace ns, Location location, Str name)
    : super(location)
  {
    this.ns = ns
    this.name = name
  }

//////////////////////////////////////////////////////////////////////////
// CPod
//////////////////////////////////////////////////////////////////////////

  override Version version() { return null }

  override CType resolveType(Str name, Bool checked)
  {
    t := typeDefs[name]
    if (t != null) return t
    if (checked) throw UnknownTypeErr.make("${this.name}::${name}")
    return null
  }

  override CType[] types()
  {
    return typeDefs.values
  }

//////////////////////////////////////////////////////////////////////////
// Debug
//////////////////////////////////////////////////////////////////////////

  override Void print(AstWriter out)
  {
    out.nl
    out.w("======================================").nl
    out.w("pod $name").nl
    out.w("======================================").nl
    units.each |CompilationUnit unit| { unit.print(out) }
    out.nl
  }

  override Str toStr()
  {
    return "pod $name"
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  override readonly CNamespace ns   // compiler's namespace
  override readonly Str name        // simple pod name
  CompilationUnit[] units           // Tokenize
  Str:TypeDef typeDefs              // ScanForUsingsAndTypes

}