//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//    2 Dec 05  Brian Frank  Creation (originally InitShimSlots)
//   23 Sep 06  Brian Frank  Ported from Java to Fan
//

**
** CheckInheritance is used to check invalid extends or mixins.
**
class CheckInheritance : CompilerStep
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  new make(Compiler compiler)
    : super(compiler)
  {
  }

//////////////////////////////////////////////////////////////////////////
// Run
//////////////////////////////////////////////////////////////////////////

  override Void run()
  {
    log.debug("CheckInheritance")
    walk(types, VisitDepth.typeDef)
    bombIfErr
  }

  override Void visitTypeDef(TypeDef t)
  {
    // check out of order base vs mixins first
    if (!checkOutOfOrder(t)) return

    // check extends
    checkExtends(t, t.base)

    // check each mixin
    t.mixins.each |CType m| { checkMixin(t, m) }
  }

//////////////////////////////////////////////////////////////////////////
// Checks
//////////////////////////////////////////////////////////////////////////

  private Bool checkOutOfOrder(TypeDef t)
  {
    if (!t.baseSpecified)
    {
      cls := t.mixins.find |CType x->Bool| { return !x.isMixin }
      if (cls != null)
      {
        err("Invalid inheritance order, ensure class '$cls' comes first before mixins", t.location)
        return false
      }
    }
    return true
  }

  private Void checkExtends(TypeDef t, CType base)
  {
    // base is null only for sys::Obj
    if (base == null && t.qname == "sys::Obj")
      return

    // ensure mixin doesn't extend class
    if (t.isMixin && t.baseSpecified)
      err("Mixin '$t.name' cannot extend class '$base'", t.location)

    // ensure enum doesn't extend class
    if (t.isEnum && t.baseSpecified)
      err("Enum '$t.name' cannot extend class '$base'", t.location)

    // check extends a mixin
    if (base.isMixin)
      err("Class '$t.name' cannot extend mixin '$base'", t.location)

    // check extends parameterized type
    if (base.isParameterized)
      err("Class '$t.name' cannot extend parameterized type '$base'", t.location)

    // check extends final
    if (base.isFinal)
      err("Class '$t.name' cannot extend final class '$base'", t.location)

    // check extends internal scoped outside my pod
    if (base.isInternal && t.pod != base.pod)
      err("Class '$t.name' cannot access internal scoped class '$base'", t.location)
  }

  private Void checkMixin(TypeDef t, CType m)
  {
    // check mixins a class
    if (!m.isMixin)
    {
      if (t.isMixin)
        err("Mixin '$t.name' cannot extend class '$m'", t.location)
      else
        err("Class '$t.name' cannot mixin class '$m'", t.location)
    }

    // check extends internal scoped outside my pod
    if (m.isInternal && t.pod != m.pod)
      err("Type '$t.name' cannot access internal scoped mixin '$m'", t.location)
  }

}