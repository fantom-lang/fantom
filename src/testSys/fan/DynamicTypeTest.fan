//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 Mar 06  Brian Frank  Creation
//

**
** DynamicTypeTest
**
class DynamicTypeTest : Test
{

//////////////////////////////////////////////////////////////////////////
// Make Dynamic
//////////////////////////////////////////////////////////////////////////

  Void testMakeDynamic()
  {
    f0 := Str:Obj[:]

    f1 := ["b":true, "i":77, "sep":Month.sep, "complex":FacetsA { i=2; f=3f; s="gunslinger" }]

    fm := ["b":true, "i":77, "sep":Month.sep, "complex":FacetsA { i=2; f=3f; s="gunslinger" }]

    // ctor extends Dyno (no facets)
    verifyDynamic(Type.makeDynamic([Dyno#]),
      Dyno#, Type[,],
      Type#, "dynamic", f0)

    // ctor extends Dyno (with facets)
    verifyDynamic(Type.makeDynamic([Dyno#], f1),
      Dyno#, Type[,],
      Type#, "dynamic", f1)

    // ctor extends Dyno2 (facets)
    verifyDynamic(Type.makeDynamic([Dyno2#], f0),
      Dyno2#, Type[,],
      Type#, "dynamic", f0)

    // subclass extends Dyno (no facets)
    verifyDynamic(TestType.make0,
      Dyno#, Type[,],
      TestType#, "TestType", f0)

    // subclass extends Dyno2 (with mutated facets)
    t := TestType.make1(fm)
    fm["complex"]->i = 44
    fm["complex"]->s = "jake"
    fm.remove("sep")
    verifyDynamic(t,
      Dyno2#, Type[,],
      TestType#,   "TestType", f1)

    // check invalid args to makeDynamic
    verifyErr(ArgErr#) |,| { Type.makeDynamic(null) }
    verifyErr(ArgErr#) |,| { Type.makeDynamic(Type[,]) }
    verifyErr(ArgErr#) |,| { Type.makeDynamic(Type[TestType.make0]) }
    verifyErr(ArgErr#) |,| { Type.makeDynamic(Type[Obj#]) }
    verifyErr(ArgErr#) |,| { Type.makeDynamic(Type[Str#]) }
    verifyErr(ArgErr#) |,| { Type.makeDynamic(Type[Thread#]) }
    verifyErr(ArgErr#) |,| { Type.makeDynamic([MxA#]) }
    verifyErr(ArgErr#) |,| { Type.makeDynamic([Dyno#, StrBuf#]) }
    verifyErr(ArgErr#) |,| { Type.makeDynamic([Dyno#, InStream#]) }
  }

  Void verifyDynamic(Type t, Type base, Type[] mixins, Type tt, Str str, Str:Obj f)
  {
    // identity
    verifyEq(t.isDynamic, true)
    verifySame(t.type, tt)
    verifyEq(t.toStr, str)
    verifyEq(t.pod, null)
    verifyEq(t.name, "dynamic")
    verifyEq(t.qname, "dynamic")
    verifyEq(t.signature, "dynamic")
    verifyEq(t.isImmutable, false)
    verifyErr(NotImmutableErr#) |,| { t.toImmutable }

    // inheritance
    verifySame(t.base, base)
    verify(t.mixins.isRO)
    verifyEq(t.mixins, mixins)
    verify(t.inheritance.isRO)
    verify(t.inheritance.contains(t))
    verify(t.inheritance.contains(base))
    verify(t.inheritance.containsAll(base.inheritance))
    verify(t.inheritance.containsAll(mixins))
    verifyEq(t.fits(Obj#), true)
    verifyEq(t.fits(t), true)
    verifyEq(t.fits(TestType#), false)

    // slots
    t.inheritance.each |Type i|
    {
      verify(t.slots.containsAll(t.slots))
      verify(t.fields.containsAll(t.fields))
      verify(t.methods.containsAll(t.methods))
    }

    // facets
    verify(t.facets.isRO())
    verifyEq(t.facets, f)

    // obj make
    obj := t.make
    verifyEq(obj is Dyno, true)
    verifySame(obj as Dyno, obj)
    verifySame(obj.type, t)
  }

//////////////////////////////////////////////////////////////////////////
// Dynamic Fields
//////////////////////////////////////////////////////////////////////////

  Void testDynamicFields()
  {
    // verify frozen fields
    t := Type.makeDynamic([Dyno#])
    verifyEq(t.fields.size, 3)
    verifyEq(t.slot("x", false), null)
    verifyEq(t.field("x", false), null)

    // verify new unmounted field
    x := TestField.make("x", Duration#)
    verifyEq(x.parent, null)
    verifyEq(x.name, "x")
    verifyEq(x.qname, "x")
    verifyEq(x.of, Duration#)

    // verify mounted field
    t.add(x)
    verifyEq(x.parent, t)
    verifyEq(x.name, "x")
    verifyEq(x.qname, "x")
    verifyEq(x.of, Duration#)
    verifyEq(t.slots.isRO, true)
    verifyEq(t.fields.isRO, true)
    verifyEq(t.fields.size, 4)
    verifySame(t.slots[-1], x)
    verifySame(t.fields[3], x)
    verifySame(t.slot("x"), x)
    verifySame(t.field("x"), x)
    verifyErr(Err#) |,| { t.add(x) }

    // verify get/set
    obj := t.make
    verifySame(obj.type, t)
    verifyEq(x.get(obj), null)
    verifyEq(obj->x, null)
    x.set(obj, 8ms)
    verifyEq(x.get(obj), 8ms)
    verifyEq(obj->x, 8ms)
    obj->x = -77min
    verifyEq(x.get(obj), -77min)
    verifyEq(obj->x, -77min)

    // remove field
    t.remove(x)
    verifyEq(x.parent, null)
    verifyEq(x.name, "x")
    verifyEq(x.qname, "x")
    verifyEq(x.of, Duration#)
    verifyEq(t.fields.size, 3)
    verifyEq(t.slot("x", false), null)
    verifyEq(t.field("x", false), null)
    verifyErr(UnknownSlotErr#) |,| { echo(obj->x) }

    // verify errs
    verifyErr(NullErr#) |,| { TestField.make(null, Int#) }
    verifyErr(NullErr#) |,| { TestField.make("foo", null) }
    verifyErr(Err#) |,| { t.add(Str#.slot("trim")) }
  }

//////////////////////////////////////////////////////////////////////////
// Dynamic Methods
//////////////////////////////////////////////////////////////////////////

  Void testDynamicMethods()
  {
    t := Type.makeDynamic([Dyno#])
    Dyno obj := t.make

    // verify new unmounted method
    func := |Dyno d, Int x->Int| { return d.i - x }
    facets := ["foo":[1, 2, 3]]
    x := Method.make("x", func, facets)
    facets["foo"]->remove(2)
    verifyEq(x.parent, null)
    verifyEq(x.name, "x")
    verifyEq(x.qname, "x")
    verifyEq(x.returns, Int#)
    verifyEq(x.params.size, 2) // how far to make an instance method?
    verifyEq(x.params[0].of, Dyno#)
    verifyEq(x.params[1].of, Int#)
    verifyEq(x.facet("foo"), [1, 2, 3])
    verifyEq(x.facets, Str:Obj["foo":[1, 2, 3]])

    // verify mounted method
    t.add(x)
    verifyEq(x.parent, t)
    verifyEq(x.name, "x")
    verifyEq(x.qname, "x")
    verifyEq(x.returns, Int#)
    verifyEq(x.params.size, 2)
    verifyEq(t.slots.isRO, true)
    verifyEq(t.methods.isRO, true)
    verifyEq(t.methods.size, Obj#.methods.size + 2)
    verifySame(t.slots[-1], x)
    verifySame(t.methods[-1], x)
    verifySame(t.slot("x"), x)
    verifySame(t.method("x"), x)
    verifyErr(Err#) |,| { t.add(x) }

    // add method sub-classes
    t.add(TestMethod.make1("y", |Dyno d->Int| { return d.i * 2 }))
    t.add(TestMethod.make2("z", |Dyno d->Int| { return d.i * 3 }, facets))

    // verify invoke
    verifyEq(obj.add(2), 5)
    verifyEq(obj->x(2), 1)
    verifyEq(obj->y, 6)
    verifyEq(obj->z, 9)

    // remove method
    t.remove(x)
    verifyEq(x.parent, null)
    verifyEq(x.name, "x")
    verifyEq(x.qname, "x")
    verifyEq(x.returns, Int#)
    verifyEq(t.slot("x", false), null)
    verifyEq(t.field("x", false), null)
    verifyErr(UnknownSlotErr#) |,| { echo(obj->x) }
  }

}

**************************************************************************
** TestField
**************************************************************************

const class TestField : Field
{
  new make(Str name, Type of) : super(name, of) {}
  new makef(Str name, Type of, Str:Obj f) : super.make(name, of, f) {}

  override Obj get(Obj instance)
  {
    return ((Dyno)instance).vals[name]
  }

  override Void set(Obj instance, Obj val)
  {
    ((Dyno)instance).vals[name] = val
  }
}

**************************************************************************
** TestMethod
**************************************************************************

const class TestMethod : Method
{
  new make1(Str name, Func f) : super.make(name, f) {}
  new make2(Str name, Func f, Str:Obj x) : super.make(name, f, x) {}
}

**************************************************************************
** TestType
**************************************************************************

class TestType : Type
{
  new make0() : super.makeDynamic([Dyno#]) {}
  new make1(Str:Obj f) : super.makeDynamic([Dyno2#], f) {}

  override Str toStr() { return "TestType" }
}

class Dyno
{
  Int add(Int x) { return i + x }
  Int i := 3
  Str s := "hello"
  Str:Obj vals := Str:Obj[:]
}

class Dyno2 : Dyno
{
  Int sub(Int x) { return i - x }
  Bool z := true
}


