//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   14 May 09  Brian Frank  Creation
//

**
** Symbol models a qualified name/value pair.
**
final const class Symbol
{

//////////////////////////////////////////////////////////////////////////
// Lookup
//////////////////////////////////////////////////////////////////////////

  **
  ** Find a Symbol by it's qualified name "pod::name".  If the symbol
  ** doesn't exist and checked is false then return null, otherwise
  ** throw UnknownPodErr or UnknownFacetErr.
  **
  // TODO-FACET
  static Symbol? find(Str qname, Bool checked := true)

  **
  ** Private constructor.
  **
  private new make()

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  **
  ** Pod which declared this symbol.
  **
  Pod pod()

  **
  ** Qualified name of symbol is "{pod.name}::{name}".
  **
  Str qname()

  **
  ** Get the simple, unqualified name of the symbol.
  **
  Str name()

  **
  ** Get the value type of the symbol.
  **
  Type type()

  **
  ** Return if symbol is virtual which means it may be overridden
  ** in a fansym configuration file.
  **
  Bool isVirtual()

  **
  ** Get the default value of the symbol as originally declared.
  ** Use `val` to get the current value.
  **
  Obj? defVal()

  **
  ** Get the current value of the symbol.
  **
  Obj? val()

  **
  ** Hashcode is based on `qname`.
  **
  override Int hash()

  **
  ** Two symbols are equal if they have same `qname`.
  **
  override Bool equals(Obj? that)

  **
  ** Return "@qname".
  **
  override Str toStr()

//////////////////////////////////////////////////////////////////////////
// Documentation
//////////////////////////////////////////////////////////////////////////

  **
  ** Return the raw fandoc for this symbol or null if not available.
  ** If there is additional documentation meta-data available it is
  ** included an the start of the string as a series of "@name=value"
  ** lines.
  **
  Str? doc()

}