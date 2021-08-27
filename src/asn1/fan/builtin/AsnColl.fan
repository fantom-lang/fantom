//
// Copyright (c) 2021, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   09 Aug 2021 Matthew Giannini Creation
//

**
** Base class for ASN.1 collection types.
**
abstract const class AsnColl : AsnObj
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  protected new make(AsnTag[] tags, Obj val) : super(tags, toItems(val))
  {
  }

  @NoDoc static AsnItem[] toItems(Obj val)
  {
    items := AsnItem[,]
    if (val is Map)
    {
      m := (Str:AsnObj)val
      m.each |v, k| { items.add(AsnItem(v, k)) }
    }
    else
    {
      arr := (List)val
      if (arr.of.fits(AsnItem#)) items = val
      else arr.each { items.add(AsnItem(it)) }
    }
    return items
  }

  ** Get a [collection builder]`AsnCollBuilder`
  static AsnCollBuilder builder() { AsnCollBuilder() }

//////////////////////////////////////////////////////////////////////////
// AsnColl
//////////////////////////////////////////////////////////////////////////

  ** Is this a 'SEQUENCE'
  Bool isSeq() { univTag == AsnTag.univSeq }

  ** Is this a 'SET'
  Bool isSet() { univTag == AsnTag.univSet }

  ** Get the raw `AsnObj` values in the collection
  AsnObj[] vals() { items.map { it.val } }

  @NoDoc AsnItem[] items() { val }

  ** Get the number of items in the collection
  Int size() { items.size }

  ** Is the collection empty
  Bool isEmpty() { items.isEmpty }

  ** Get an item value from the collection.
  **  - If key is a `sys::Str` then get the named item.
  **  - If key is an `sys::Int`, then get the item at that zero-based index.
  AsnObj? get(Obj key)
  {
    if (key is Int) return items.getSafe(key)?.val
    else if (key is Str) return items.find { it.name == name }?.val
    throw ArgErr("invalid key type: ${key.typeof}")
  }

//////////////////////////////////////////////////////////////////////////
// AsnObj
//////////////////////////////////////////////////////////////////////////

  protected override Str valStr()
  {
    buf := StrBuf().add("{\n")
    indent := 2
    items.each |AsnItem item|
    {
      buf.add("".padl(indent))
      if (item.name != null) buf.add("${item.name}: ")
      if (item.val is AsnColl)
      {
        collStr := item.val.toStr
        collStr.splitLines.each |line, i|
        {
          if (i==0) buf.add(line)
          else buf.add("".padl(indent)).add(line)
          buf.add("\n")
        }
      }
      else buf.add(item.val.toStr).add("\n")
    }
    buf.add("}")
    return buf.toStr
  }
}

**************************************************************************
** AsnItem
**************************************************************************

** An item in an ASN.1 collection. An item has a value, and an optional name
** associated with that value. When comparing items, only the values are
** compared; the name is ignored.
final const class AsnItem
{
  new make(AsnObj val, Str? name := null)
  {
    this.name = name
    this.val = val
  }

  const Str? name
  const AsnObj val

  override Int hash() { val.hash }
  override Bool equals(Obj? obj)
  {
    if (obj == null) return false
    that := obj as AsnItem
    if (that == null) return false
    // name is *not* considered for equality purposes
    return this.val == that.val
  }
}

**************************************************************************
** AsnSeq
**************************************************************************

**
** Models an ASN.1 'SEQUENCE'
**
const class AsnSeq : AsnColl
{
  protected new makeUniv(Obj val) : this.make([AsnTag.univSeq], val)
  {
  }
  protected new make(AsnTag[] tags, Obj val) : super(tags, toItems(val))
  {
    if (univTag != AsnTag.univSeq) throw ArgErr("Not a sequence: $tags")
  }
}

**************************************************************************
** AsnSet
**************************************************************************

**
** Models an ASN.1 'SET'
**
const class AsnSet : AsnColl
{
  protected new makeUniv(Obj val) : this.make([AsnTag.univSet], val)
  {
    if (univTag != AsnTag.univSet) throw ArgErr("Not a set: $tags")
  }
  protected new make(AsnTag[] tags, Obj val) : super(tags, toItems(val))
  {
  }
}

**************************************************************************
** AsnCollBuilder
**************************************************************************

**
** `AsnColl` builder.
**
class AsnCollBuilder
{
  new make() { }

  private AsnItem[] items := [,]

  ** Convenience to add an `AsnItem` with the given value and name
  This add(AsnObj val, Str? name := null) { item(AsnItem(val, name)) }

  ** Add an `AsnItem` to the collection
  This item(AsnItem item)
  {
    items.add(item)
    return this
  }

  ** Build an ASN.1 sequence
  AsnColl toSeq(AsnTag? tag := null) { Asn.tag(tag).seq(items) }

  ** Build an ASN.1 set
  AsnColl toSet(AsnTag? tag := null) { Asn.tag(tag).set(items) }
}
