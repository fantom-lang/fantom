//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   29 Aug 06  Brian Frank  Creation
//

**
** ReflectSymbol is the implementation of CSymbol for a symbol imported
** from a precompiled pod (as opposed to a SymbolDef within the
** compilation units being compiled).
**
class ReflectSymbol : CSymbol
{
  new make(ReflectPod pod, Symbol symbol)
  {
    this.pod = pod
    this.symbol = symbol
    this.of = pod.ns.importType(symbol.type)
  }

  override ReflectPod pod
  override Int flags()  { 0 }
  override Str name()  { symbol.name }
  override Str qname() { symbol.qname }
  override CType of

  const Symbol symbol
}

