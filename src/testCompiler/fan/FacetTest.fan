//
// Copyright (c) 2010, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   03 Feb 10  Brian Frank  Creation
//

**
** FacetTest
**
class FacetTest : CompilerTest
{

/////////////////////////////////////////////////////////////////////////
// Basics
//////////////////////////////////////////////////////////////////////////

  Void testBasics()
  {
    compile("facet class Foo {}")

    t := pod.types.first
    verifyEq(t.isFacet, true)
    verifyEq(t.isClass, true)
    verifyEq(t.isMixin, false)
    verifyEq(t.isConst, true)
    verifyEq(t.isFinal, true)
    verifyEq(t.isAbstract, false)
    verifyEq(t.base, Obj#)
    verifyEq(t.mixins, [Facet#])
  }

}