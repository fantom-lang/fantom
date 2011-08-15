//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   11 Aug 11  Brian Frank  Creation
//

using concurrent

**
** DocType models the documentation of a `sys::Type`.
**
const class DocType
{

  ** Constructor
  internal new make(|This| f) { f(this) }

  ** Representation of this type definition as a reference
  const DocTypeRef ref

  ** Pod name which defines this type
  Str pod() { ref.pod }

  ** Simple name of the type such as "Str".
  Str name() { ref.name }

  ** Qualified name formatted as "pod::name".
  Str qname() { ref.qname }

  ** Source code location of this type definition
  const DocLoc loc

  ** Flags mask - see `DocFlags`
  const Int flags

  ** Fandoc documentation string
  const DocFandoc doc

  ** Facets defined on this type
  const DocFacet[] facets

  ** The direct super class of this type (null for Obj)
  const DocTypeRef? base

  ** Mixins directly implemented by this type
  const DocTypeRef[] mixins

  ** Slots defined by this type
  const DocSlot[] slots

  ** Get slot by name.  If not found return null or raise UknownSlotErr
  DocSlot? slot(Str name, Bool checked := true)
  {
    map := slotMapRef.val as Str:DocSlot
    if (map == null)
    {
      map = Str:DocSlot[:]
      slots.each |slot| { map[slot.name] = slot }
      slotMapRef.val = map.toImmutable
    }
    slot := map[name]
    if (slot != null) return slot
    if (checked) throw UnknownSlotErr("${qname}::${name}")
    return null
  }
  private const AtomicRef slotMapRef := AtomicRef(null)

  ** Summary is the first sentence of `doc`
  Str summary() { DocUtil.firstSentence(doc.text) }

  ** return qname
  override Str toStr() { qname }

  internal Void dump(OutStream out)
  {
    out.printLine("#### $qname #####")
    out.printLine("ref    = $ref")
    out.printLine("pod    = $pod")
    out.printLine("name   = $name")
    out.printLine("flags  = " + DocFlags.toNames(flags))
    out.printLine("doc    = $doc.text.toCode")
    out.printLine("base   = $base")
    out.printLine("mixins = $mixins")
    facets.each |facet| { out.printLine(facet) }
    slots.each |slot| { slot.dump(out) }
    out.printLine.flush
  }

}