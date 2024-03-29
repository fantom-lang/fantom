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

