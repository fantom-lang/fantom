//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   13 Jan 09  Brian Frank  Creation
//

**
** Abstract base class for tests.
**
abstract class ObixTest : Test
{

  **
  ** Verify two object trees are identical.
  **
  Void verifyObj(ObixObj a, ObixObj b)
  {
    // identity
    verifyEq(a.elemName, b.elemName)
    verifyEq(a.name, b.name)
    verifyEq(a.href, b.href)

    // contracts
    verifyEq(a.contract, b.contract)
    verifyEq(a.of, b.of)
    verifyEq(a.in, b.in)
    verifyEq(a.out, b.out)

    // value
    verifyEq(a.val, b.val)
    verifyEq(a.isNull, b.isNull)

    // facets
    verifyEq(a.displayName, b.displayName)
    verifyEq(a.display, b.display)
    verifyEq(a.icon, b.icon)
    verifyEq(a.min, b.min)
    verifyEq(a.max, b.max)
    verifyEq(a.precision, b.precision)
    verifyEq(a.range, b.range)
    verifyEq(a.precision, b.precision)
    verifyEq(a.status, b.status)
    verifyEq(a.tz, b.tz)
    verifyEq(a.unit, b.unit)
    verifyEq(a.writable, b.writable)

    // children
    verifyEq(a.size, b.size)
    alist := a.list
    blist := b.list
    alist.each |ObixObj ak, Int i|
    {
      bk := blist[i]
      verifySame(ak.parent, a)
      verifySame(bk.parent, b)
      verifyObj(ak, bk)
    }
    verifySame(a.first, alist.first)
    verifySame(a.last,  alist.last)
  }

  **
  ** Verify children by reference.
  **
  Void verifyChildren(ObixObj p, ObixObj[] kids)
  {
    verifyEq(p.size, kids.size)
    verifyEq(p.list, kids)
    verifyEq(p.list.isRO, true)
    acc := ObixObj[,]
    p.each { acc.add(it) }
    verifyEq(acc, kids)
    kids.each |ObixObj kid|
    {
      verifySame(kid.parent, p)
      if (kid.name != null) verifySame(p[kid.name], kid)
    }
    verifyEq(p.get("badone", false), null)
    verifyErr(NameErr#) { p.get("badone") }
    verifyErr(NameErr#) { p.get("badone", true) }
  }

}