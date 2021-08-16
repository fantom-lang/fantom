//
// Copyright (c) 2021, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   09 Aug 2021 Matthew Giannini Creation
//

**
** Models an ASN.1 'OBJECT IDENTIFIER' type.
**
final const class AsnOid : AsnObj
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  protected new make(AsnTag[] tags, Int[] val) : super(tags, val)
  {
    if (univTag != AsnTag.univOid) throw ArgErr("Invalid tags for OID: $tags")
  }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  ** Convenience to get the value as a list of its 'Int' identifiers.
  Int[] ids()
  {
    this.val
  }

//////////////////////////////////////////////////////////////////////////
// Oid
//////////////////////////////////////////////////////////////////////////

  ** Convenience to get a Str where the sub-identifiers are joined with a '.'
  **
  **   Asn.oid("1.2.3").oidStr == "1.2.3"
  Str oidStr()
  {
    ids.join(".")
  }

  ** Get a new Oid based on the specified range. This Oid
  ** is guaranteed to be in the universal tag class (i.e. - the
  ** tag is not preservered).
  **
  ** Throw IndexErr if the range is illegal.
  @Operator
  AsnOid getRange(Range range)
  {
    Asn.oid(ids[range])
  }

  // override AsnOid push(AsnTag tag)
  // {
  //   AsnOid([tag].addAll(this.tags), val)
  // }

//////////////////////////////////////////////////////////////////////////
// Obj
//////////////////////////////////////////////////////////////////////////

  ** Oid is ordered by comparing its sub-identifier parts numerically.
  override Int compare(Obj that)
  {
    thatOid := (AsnOid)that
    if (this.ids == thatOid.ids) return 0

    i := 0
    cmp := this.ids[i] <=> thatOid.ids[i]
    while (cmp == 0)
    {
      ++i
      if (i >= this.ids.size) return -1
      else if (i >= thatOid.ids.size) return 1
      cmp = this.ids[i] <=> thatOid.ids[i]
    }
    return cmp
  }

  override Str valStr() { oidStr }
}

