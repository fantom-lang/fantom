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
    this.units = CompilationUnit[,]
    this.symbolDefs = Str:SymbolDef[:] { ordered = true }
  }

//////////////////////////////////////////////////////////////////////////
// CPod
//////////////////////////////////////////////////////////////////////////

  override Version version() { throw UnsupportedErr("PodDef.version") }

  override CType? resolveType(Str name, Bool checked)
  {
    t := typeDefs[name]
    if (t != null) return t
    if (checked) throw UnknownTypeErr("${this.name}::${name}")
    return null
  }

  override CSymbol? resolveSymbol(Str name, Bool checked)
  {
    s := symbolDefs[name]
    if (s != null) return s
    if (checked) throw UnknownSymbolErr("${this.name}::${name}")
    return null
  }

  override CType[] types()
  {
    return typeDefs.vals
  }

//////////////////////////////////////////////////////////////////////////
// Tree
//////////////////////////////////////////////////////////////////////////

  Void walk(Visitor v, VisitDepth depth)
  {
    if (unit == null) return
    v.enterUnit(unit)
    walkFacets(v, depth)
    symbolDefs.each |SymbolDef def| { def.walk(v, depth) }
    v.exitUnit(unit)
  }

  override Void print(AstWriter out)
  {
    out.nl
    out.w("======================================").nl
    out.w("pod $name").nl
    out.w("======================================").nl
    units.each |CompilationUnit unit| { unit.print(out) }
    out.nl
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  override readonly CNamespace ns   // compiler's namespace
  override readonly Str name        // simple pod name
  CompilationUnit? unit             // "pod.fan" unit
  CompilationUnit[] units           // Tokenize
  [Str:TypeDef]? typeDefs           // ScanForUsingsAndTypes
  Str:SymbolDef symbolDefs          // Parse of "symbols.fan"

}