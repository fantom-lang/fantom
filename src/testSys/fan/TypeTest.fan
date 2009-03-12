//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 Mar 06  Brian Frank  Creation
//

**
** TypeTest
**
@testSysByStr=["alpha", "beta"]
@testSysByType=[SerB#, MxB#]
class TypeTest : Test
{

//////////////////////////////////////////////////////////////////////////
// Find
//////////////////////////////////////////////////////////////////////////

  Void testIdentity()
  {
    verifyEq(this.type.isImmutable, true)
    verifySame(this.type.toImmutable, this.type)
    verifyEq(this.type.toStr, "testSys::TypeTest")
    verifyEq(this.type.toLocale, "testSys::TypeTest")
  }

//////////////////////////////////////////////////////////////////////////
// Find
//////////////////////////////////////////////////////////////////////////

  Void testFind()
  {
    verifySame(Type.find("sys::Int"), Int#)
    verifySame(Type.find("sys::Str[]"), Str[]#)
    verifySame(Type.find("sys::notHereFoo", false), null)
    verifyErr(UnknownTypeErr#) |,| { Type.find("sys::notHereFoo") }
    verifyErr(UnknownPodErr#) |,| { Type.find("notHereFoo::Duh") }
    verifyErr(ArgErr#) |,| { Type.find("sys") }
    verifyErr(ArgErr#) |,| { Type.find("sys::") }
    verifyErr(ArgErr#) |,| { Type.find("::sys") }
    verifyErr(ArgErr#) |,| { Type.find("[]") }
  }

//////////////////////////////////////////////////////////////////////////
// Value Types
//////////////////////////////////////////////////////////////////////////

  Void testValueTypes()
  {
    verifyEq(Bool#.isValue,     true)
    verifyEq(Bool?#.isValue,    true)
    verifyEq(Int#.isValue,      true)
    verifyEq(Int?#.isValue,     true)
    verifyEq(Float#.isValue,    true)
    verifyEq(Float?#.isValue,   true)

    verifyEq(Obj#.isValue,      false)
    verifyEq(Obj?#.isValue,     false)
    verifyEq(Num#.isValue,      false)
    verifyEq(Num?#.isValue,     false)
    verifyEq(Decimal#.isValue,  false)
    verifyEq(Decimal?#.isValue, false)
    verifyEq(Str#.isValue,      false)
    verifyEq(Str?#.isValue,     false)
  }

//////////////////////////////////////////////////////////////////////////
// TypeDb
//////////////////////////////////////////////////////////////////////////

  Void testFindByFacet()
  {
    verifyErr(Err#) |,| { Type.findByFacet("testSysKeyFoo", "") }

    x := Type.findByFacet("testSysByStr", "zeta")
    verifyEq(x.size, 0)
    verifyEq(x.isRO, true)

    x = Type.findByFacet("testSysByStr", "alpha")
    verifyEq(x.size, 2)
    verifyEq(x.isRO, true)
    verify(x.contains(TypeTest#))
    verify(x.contains(FacetsTest#))

    x = Type.findByFacet("testSysByStr", "beta")
    verifyEq(x, [TypeTest#])

    x = Type.findByFacet("testSysByType", Str#)
    verifyEq(x.size, 0)
    verifyEq(x.isRO, true)

    x = Type.findByFacet("testSysByType", SerA#)
    verifyEq(x, [FacetsTest#])

    x = Type.findByFacet("testSysByType", SerB#)
    verifyEq(x, [TypeTest#])

    x = Type.findByFacet("testSysByType", SerB#, false)
    verifyEq(x, [TypeTest#])

    x = Type.findByFacet("testSysByType", SerB#, true)
    verifyEq(x.isRO, true)
    verifyEq(x, [TypeTest#, FacetsTest#])

    verifyEq(Type.findByFacet("testSysByType", MxB#), [TypeTest#])
    verifyEq(Type.findByFacet("testSysByType", MxAB#), Type[,])
    verifyEq(Type.findByFacet("testSysByType", MxAB#, true), [TypeTest#])
    verifyEq(Type.findByFacet("testSysByType", MxClsAB#, true), [TypeTest#])
  }

//////////////////////////////////////////////////////////////////////////
// Flags
//////////////////////////////////////////////////////////////////////////

  Void testFlags()
  {
    // isAbstract
    verifyEq(Test#.isAbstract, true)
    verifyEq(type.isAbstract, false)

    // isClass
    verifyEq(type.isClass, true)
    verifyEq(EnumAbc#.isClass, false)
    verifyEq(MxA#.isClass, false)

    // isEnum
    verifyEq(type.isEnum, false)
    verifyEq(EnumAbc#.isEnum, true)
    verifyEq(MxA#.isEnum, false)

    // isFinal
    verifyEq(Bool#.isFinal, true)
    verifyEq(Test#.isFinal, false)

    // isInternal
    verifyEq(type.isInternal, false)
    verifyEq(EnumAbc#.isInternal, true)

    // isMixin
    verifyEq(type.isMixin, false)
    verifyEq(EnumAbc#.isMixin, false)
    verifyEq(MxA#.isMixin, true)

    // isPublic
    verifyEq(type.isPublic, true)
    verifyEq(EnumAbc#.isPublic, false)

    // isSynthetic
    // test below in testSynthetic()
  }

//////////////////////////////////////////////////////////////////////////
// Mixins
//////////////////////////////////////////////////////////////////////////

  Void testMixins()
  {
    verifyEq(Obj#.mixins, Type[,])
    verifyEq(Obj#.mixins.isRO, true)

    verifyEq(MxClsAB#.mixins, [MxA#, MxB#])
    verifyEq(MxClsAB#.mixins.isRO, true)
  }

//////////////////////////////////////////////////////////////////////////
// Inheritance
//////////////////////////////////////////////////////////////////////////

  Void testInheritance()
  {
    verifyEq(Obj#.inheritance, [Obj#])
    verifyEq(Num#.inheritance, [Num#, Obj#])
    verifyEq(Int#.inheritance, [Int#, Num#, Obj#])

    // test Void which is a special case
    verifyEq(Void#.inheritance, [Void#])

    // mixin types tested in MixinTest.testType
  }

//////////////////////////////////////////////////////////////////////////
// Fits
//////////////////////////////////////////////////////////////////////////

  Void testFits()
  {
    verify(Float#.fits(Float#))
    verify(Float#.fits(Num#))
    verify(Float#.fits(Obj#))
    verifyFalse(Float#.fits(Str#))
    verifyFalse(Obj#.fits(Float#))

    // void doesn't fit anything
    verifyFalse(Void#.fits(Obj#))
    verifyFalse(Obj#.fits(Void#))
  }

//////////////////////////////////////////////////////////////////////////
// Generics
//////////////////////////////////////////////////////////////////////////

  Void testIsGeneric()
  {
    verifyEq(Obj#.isGeneric,    false)
    verifyEq(Str#.isGeneric,    false)
    verifyEq(Str[]#.isGeneric,  false)
    verifyEq(Method#.isGeneric, false)
    verifyEq(List#.isGeneric,   true)
    verifyEq(Map#.isGeneric,    true)
    verifyEq(Func#.isGeneric,   true)
  }

  Void testParams()
  {
    verifyEq(Str#.params, Str:Type[:])
    verifyEq(Str#.params.isRO, true)

    verifyEq(Str[]#.params, ["V":Str#, "L":Str[]#])
    verifyEq(Str[]#.params.isRO, true)

    verifyEq(Int:Slot[]#.params, ["K":Int#, "V":Slot[]#, "M":Int:Slot[]#])
    verifyEq(Int:Slot[]#.params.isRO, true)

    verifyEq(|Int a, Float b->Bool|#.params, ["A":Int#, "B":Float#, "R":Bool#])
    verifyEq(|Int a, Float b->Bool|#.params.isRO, true)
  }

  Void testParameterization()
  {
    verifyEq(List#.parameterize(["V":Bool#]), Bool[]#)
    verifyEq(List#.parameterize(["V":Bool[]#]), Bool[][]#)
    verifyErr(ArgErr#) |,| { List#.parameterize(["X":Bool[]#]) }

    verifyEq(Map#.parameterize(["K":Str#, "V":Slot#]), Str:Slot#)
    verifyEq(Map#.parameterize(["K":Str#, "V":Int[]#]), Str:Int[]#)
    verifyErr(ArgErr#) |,| { Map#.parameterize(["V":Bool[]#]) }
    verifyErr(ArgErr#) |,| { Map#.parameterize(["K":Bool[]#]) }

    verifyEq(Func#.parameterize(["R":Void#]), |,|#)
    verifyEq(Func#.parameterize(["A":Str#, "R":Int#]), |Str a->Int|#)
    verifyEq(Func#.parameterize(["A":Str#, "B":Bool#, "C":Int#, "R":Float#]),
      |Str a, Bool b, Int c->Float|#)
    verifyErr(ArgErr#) |,| { Func#.parameterize(["A":Bool[]#]) }

    verifyErr(UnsupportedErr#) |,| { Str#.parameterize(["X":Void#]) }
    verifyErr(UnsupportedErr#) |,| { Str[]#.parameterize(["X":Void#]) }
  }

  Void testToListOf()
  {
    verifyEq(Str#.toListOf, Str[]#)
    verifyEq(Str[]#.toListOf, Str[][]#)
    verifyEq(Str[][]#.toListOf, Str[][][]#)
    verifyEq(Str:Buf#.toListOf, [Str:Buf][]#)
  }

  Void testEmptyList()
  {
    s :=  Str#.emptyList
    verifyEq(s, Str[,])
    verifyEq(s.isImmutable, true)
    verifyEq(s.type.signature, "sys::Str[]")
    verifySame(s, Str#.emptyList)
    verifyErr(ReadonlyErr#) |,| { s.add("foo") }

    sl :=  Str[]#.emptyList
    verifyEq(sl, Str[][,])
    verifyEq(sl.isImmutable, true)
    verifyEq(sl.type.signature, "sys::Str[][]")
    verifySame(sl, Str[]#.emptyList)
    verifyNotSame(sl, s)
    verifyErr(ReadonlyErr#) |,| { sl.add(Str[,]) }
  }

//////////////////////////////////////////////////////////////////////////
// Reflection
//////////////////////////////////////////////////////////////////////////

  Void testMake()
  {
    verify(File#.make([`foo`]) is File)
    verifyEq(File#.make([`foo`])->uri, `foo`)
    //verifyErr(Err#) |,| { Bool.type.make }
  }

//////////////////////////////////////////////////////////////////////////
// Synthetic
//////////////////////////////////////////////////////////////////////////

  Void testSynthetic()
  {
    type.pod.types.each |Type t|
    {
      verifyEq(t.isSynthetic, t.name.index("\$") != null, t.toStr)
      verifySlotsSynthetic(t)
    }
  }

  Void verifySlotsSynthetic(Type t)
  {
    t.slots.each |Slot slot|
    {
      if (slot.parent.isSynthetic || slot.name.index("\$") != null)
        verify(slot.isSynthetic, slot.toStr)
    }
  }

//////////////////////////////////////////////////////////////////////////
// Generic Parameters
//////////////////////////////////////////////////////////////////////////

  Void testGenericParameters()
  {
    // TODO - what do we really want for these guys?
    v := List#get.returns
    verifyEq(v.name, "V")
    verifyEq(v.qname, "sys::V")
    verifySame(v.pod, Obj#.pod)
    verifySame(v.base, Obj#)
    verifyEq(v.mixins, Type[,])
    verifyEq(v.mixins.ro, Type[,])
  }

}