//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//  28 Mar 24  Brian Frank  Creation
//

**
** CNode represents a compile node as base type for CType and CSlot
**
mixin CNode
{
  **
  ** Associated namespace for this type representation
  **
  abstract CNamespace ns()

  **
  ** Fandoc API docs if available
  **
  abstract CDoc? doc()

  **
  ** Get the facet keyed by given type, or null if not defined.
  **
  abstract CFacet? facet(Str qname)

  **
  ** Return if the given facet is defined.
  **
  Bool hasFacet(Str qname) { facet(qname) != null }

  **
  ** Return if type has NoDoc facet
  **
  Bool isNoDoc() { hasFacet("sys::NoDoc") }
}

**************************************************************************
** CDoc
**************************************************************************

**
** CDoc models the fandoc for a definition node
**
mixin CDoc
{
  **
  ** Constructor for raw string
  **
  static new fromStr(Str? s) { s == null ? null : MDoc(s) }

  **
  ** Raw fandoc text string
  **
  abstract Str text()
}

**************************************************************************
** MDoc
**************************************************************************

**
** Simple default implementation that wraps raw fandoc string
**
internal const class MDoc : CDoc
{
   new make(Str text) { this.text = text }
   const override Str text
}

