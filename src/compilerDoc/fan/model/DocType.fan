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
  internal new make(DocAttrs attrs, DocTypeRef ref, DocSlot[] slots)
  {
    this.ref    = ref
    this.loc    = attrs.loc
    this.flags  = attrs.flags
    this.facets = attrs.facets
    this.doc    = attrs.doc
    this.base   = attrs.base
    this.mixins = attrs.mixins
    this.slots  = slots
    this.isErr  = base.find {it.qname=="sys::Err"} != null
  }

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

  ** Facets defined on this type
  const DocFacet[] facets

  ** Fandoc documentation string
  const DocFandoc doc

  ** Base class inheritance chain where direct subclass is first
  ** and 'sys::Obj' is last.  If this type is a mixin or this is
  ** 'sys::Obj' itself then this is an empty list.
  const DocTypeRef[] base

  ** Mixins directly implemented by this type
  const DocTypeRef[] mixins

  ** Slots defined by this type
  const DocSlot[] slots

  ** Is this a subclass of 'sys::Err'
  const Bool isErr

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

  ** Is an enum type
  Bool isEnum() { DocFlags.isEnum(flags) }

  ** Is an mixin type
  Bool isMixin() { DocFlags.isMixin(flags) }

  ** Is an facet type
  Bool isFacet() { DocFlags.isFacet(flags) }

}