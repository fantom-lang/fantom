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
    verifyEq(a.name, b.name)
    verifyEq(a.href, b.href)
    verifyEq(a.contracts, b.contracts)

    // value
    verifyEq(a.val, b.val)
    verifyEq(a.isNull, b.isNull)

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
    p.each(&acc.add)
    verifyEq(acc, kids)
    kids.each |ObixObj kid|
    {
      verifySame(kid.parent, p)
      if (kid.name != null) verifySame(p[kid.name], kid)
    }
    verifyEq(p["badone"], null)
  }

}