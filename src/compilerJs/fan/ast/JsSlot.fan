//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Jul 09  Andy Frank  Creation
//

using compiler

**
** JsSlot
**
abstract class JsSlot : JsNode
{
  new make(JsCompilerSupport s, SlotDef def) : super(s)
  {
    this.parent     = qnameToJs(def.parentDef)
    this.name       = vnameToJs(def.name)
    this.flags      = def.flags
    this.isAbstract = def.isAbstract
    this.isStatic   = def.isStatic
    this.isNative   = def.isNative
  }

  Str parent      // qname of slot parent
  Str name        // slot name
  Int flags       // slot flags
  Bool isAbstract // is slot abstract
  Bool isStatic   // is slot static
  Bool isNative   // is slot native
}

**************************************************************************
** JsSlotRef
**************************************************************************

**
** JsSlotRef
**
class JsSlotRef : JsNode
{
  new make(JsCompilerSupport cs, CSlot s) : super(cs)
  {
    this.parent     = qnameToJs(s.parent)
    this.name       = vnameToJs(s.name)
    this.isAbstract = s.isAbstract
    this.isStatic   = s.isStatic
  }

  override Void write(JsWriter out)
  {
    out.w(name)
  }

  Str parent      // qname of slot parent
  Str name        // qname of type ref
  Bool isAbstract // is slot abstract
  Bool isStatic   // is slot static
}


