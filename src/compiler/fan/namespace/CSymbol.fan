//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   4 Jun 06  Brian Frank  Creation
//

**
** CSymbol is a "compiler symbol".  Symbols loaded from existing
** pods are represented as FSymbol.  Symbols parsed in current pod
** from soruce are SymbolDef.
**
mixin CSymbol
{

  **
  ** Associated namespace
  **
  CNamespace ns() { pod.ns }

  **
  ** Parent pod which defines this symbol.
  **
  abstract CPod pod()

  **
  ** Simple name of the symbol such as "transient".
  **
  abstract Str name()

  **
  ** Qualified name such as "sys:transient".
  **
  abstract Str qname()

  **
  ** Bitmask flags (unused right now)
  **
  abstract Int flags()

  **
  ** Return qname
  **
  override final Str toStr() { qname }

  **
  ** Value type of symbol
  **
  abstract CType of()

}