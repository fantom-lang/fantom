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
const class DocType : Doc
{

  ** Constructor
  internal new make(DocPod pod, DocAttrs attrs, DocTypeRef ref, DocSlot[] list, Str:DocSlot slotMap)
  {
    this.pod     = pod
    this.ref     = ref
    this.loc     = attrs.loc
    this.flags   = attrs.flags
    this.facets  = attrs.facets
    this.doc     = attrs.doc
    this.base    = attrs.base
    this.mixins  = attrs.mixins
    this.slotMap = slotMap
    this.isErr   = base.find {it.qname=="sys::Err"} != null
    this.isNoDoc = hasFacet("sys::NoDoc")


    // filter out slots which shouldn't be documented,
    // but leave them in the map for lookup
    list = list.exclude |s|
    {
      s.isNoDoc ||
      DocFlags.isInternal(s.flags) ||
      DocFlags.isPrivate(s.flags)  ||
      DocFlags.isSynthetic(s.flags)
    }
    this.declared = list
    this.slots = list.sort|a, b| { a.name <=> b.name }
  }

  ** Pod which defines this type
  const DocPod pod

  ** Representation of this type definition as a reference
  const DocTypeRef ref

  ** Simple name of the type such as "Str".
  Str name() { ref.name }

  ** Qualified name formatted as "pod::name".
  Str qname() { ref.qname }

  ** The space for this doc is `pod`
  override DocSpace space() { pod }

  ** The document name under space is `name`
  override Str docName() { name }

  ** Title of the document is the qualified name
  override Str title() { qname }

  ** Default renderer is `DocTypeRenderer`
  override Type renderer() { DocTypeRenderer# }

  ** Return true
  override Bool isCode() { true}

  ** Return true if annotated as NoDoc
  const Bool isNoDoc

  ** Source code location of this type definition
  const DocLoc loc

  ** Flags mask - see `DocFlags`
  const Int flags

  ** Facets defined on this type
  const DocFacet[] facets

  ** Return given facet
  DocFacet? facet(Str qname, Bool checked := true)
  {
    f := facets.find |f| { f.type.qname == qname }
    if (f != null) return f
    if (checked) throw Err("Missing facet @$qname on $this.qname")
    return null
  }

  ** Return if given facet is defined on type
  Bool hasFacet(Str qname) { facets.any |f| { f.type.qname == qname } }

  ** Fandoc documentation string
  const DocFandoc doc

  ** Base class inheritance chain where direct subclass is first
  ** and 'sys::Obj' is last.  If this type is a mixin or this is
  ** 'sys::Obj' itself then this is an empty list.
  const DocTypeRef[] base

  ** Mixins directly implemented by this type
  const DocTypeRef[] mixins

  ** Is this a subclass of 'sys::Err'
  const Bool isErr

  ** List of the public, documented slots in this type (sorted).
  const DocSlot[] slots

  ** List of the public, documented slots in this type (in declared order).
  @NoDoc const DocSlot[] declared

  ** Get slot by name.  If not found return null or raise UknownSlotErr
  DocSlot? slot(Str name, Bool checked := true)
  {
    slot := slotMap[name]
    if (slot != null) return slot
    if (checked) throw UnknownSlotErr("${qname}::${name}")
    return null
  }
  private const Str:DocSlot slotMap

  ** return qname
  override Str toStr() { qname }

  ** Is an enum type
  Bool isEnum() { DocFlags.isEnum(flags) }

  ** Is an mixin type
  Bool isMixin() { DocFlags.isMixin(flags) }

  ** Is an facet type
  Bool isFacet() { DocFlags.isFacet(flags) }

//////////////////////////////////////////////////////////////////////////
// onCrawl
//////////////////////////////////////////////////////////////////////////

  ** Index the type summary and all slot docs
  override Void onCrawl(DocCrawler crawler)
  {
    typeSummary := crawlTypeSummary
    crawler.addKeyword(name,  qname, typeSummary, null)
    crawler.addKeyword(qname, qname, typeSummary, null)
    crawler.addFandoc(doc)

    slots.each |slot|
    {
      slotSummary := crawlSlotSummary(slot)
      scopedName := "${this.name}.${slot.name}"
      crawler.addKeyword(slot.name,  slot.qname, slotSummary, slot.name)
      crawler.addKeyword(slot.qname, slot.qname, slotSummary, slot.name)
      crawler.addKeyword(scopedName, slot.qname, slotSummary, slot.name)
      crawler.addFandoc(slot.doc)
    }
  }

  private DocFandoc crawlTypeSummary()
  {
    s := doc.firstSentenceStrBuf
    // s.add("\n  ")
    // if (isMixin) s.add("mixin ")
    // else s.add(" class ")
    // s.add(name)
    return DocFandoc(loc, s.toStr)
  }

  private DocFandoc crawlSlotSummary(DocSlot slot)
  {
    s := StrBuf().add("> '")
    if (slot is DocField)
    {
      f := (DocField)slot
      s.add(f.type.dis).add(" ").add(slot.name)
    }
    else
    {
      m := (DocMethod)slot
      s.add(m.returns.dis).add(" ").add(slot.name)
      s.add("(")
      m.params.each |p, i|
      {
        if (i > 0) s.add(", ")
        s.add(p.type.dis).add(" ").add(p.name)
      }
      s.add(")")
    }
    s.add("'\n\n").add(doc.firstSentenceStrBuf)
    return DocFandoc(loc, s.toStr)
  }

}