//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   17 Apr 06  Brian Frank  Creation
//

**
** FieldTest
**
class FieldTest : Test
{

//////////////////////////////////////////////////////////////////////////
// Inside Instance Accessors
//////////////////////////////////////////////////////////////////////////

  Void testInsideInstanceAccessors()
  {
    // inside class - raw field get
    verifyEq(*count, 0); verifyEq(getCounter, 0); verifyEq(setCounter, 0);

    // inside class - raw field set
    *count = 3
    verifyEq(*count, 3); verifyEq(getCounter, 0); verifyEq(setCounter, 0);

    // inside class - getter
    verifyEq(count, 3); verifyEq(getCounter, 1); verifyEq(setCounter, 0);
    verifyEq(count, 3); verifyEq(getCounter, 2); verifyEq(setCounter, 0);

    // inside class - setter
    count = 5
    verifyEq(*count, 5); verifyEq(getCounter, 2); verifyEq(setCounter, 1);
    count = 7
    verifyEq(*count, 7); verifyEq(getCounter, 2); verifyEq(setCounter, 2);
  }

  Int count := 0
  {
    get { getCounter++; return *count }
    set { setCounter++; *count = val }
  }
  Int getCounter := 0
  Int setCounter := 0

//////////////////////////////////////////////////////////////////////////
// Outside Instance Accessors
//////////////////////////////////////////////////////////////////////////

  Void testOutsideInstanceAccessors()
  {
    // outside class - getter
    verifyEq(OutsideAccessor.getCount(this), 0);
      verifyEq(getCounter, 1); verifyEq(setCounter, 0);
    verifyEq(OutsideAccessor.getCount(this), 0);
      verifyEq(getCounter, 2); verifyEq(setCounter, 0);

    // outside class - setter
    OutsideAccessor.setCount(this, 5)
      verifyEq(*count, 5); verifyEq(getCounter, 2); verifyEq(setCounter, 1);
    OutsideAccessor.setCount(this, 7)
      verifyEq(*count, 7); verifyEq(getCounter, 2); verifyEq(setCounter, 2);

    // outside class - setter with leave for return
    verifyEq(OutsideAccessor.setCountLeave(this, 9), 9)
      verifyEq(*count, 9); verifyEq(getCounter, 2); verifyEq(setCounter, 3);
  }

//////////////////////////////////////////////////////////////////////////
// Val Field
//////////////////////////////////////////////////////////////////////////

  Void testValField()
  {
    // verify auto-generated val setter works correctly
    verifyEq(*val, "val")
    verifyEq(val, "val");

    *val = "changed"
    verifyEq(*val, "changed")
    verifyEq(val, "changed")

    val = "again"
    verifyEq(*val, "again")
    verifyEq(val, "again")
  }

  Str val := "val"

//////////////////////////////////////////////////////////////////////////
// Closures Inside Accessor
//////////////////////////////////////////////////////////////////////////

  Void testClosureInsideAccessor()
  {
    verifyEq(closureInsideAccessorCount, 0)
    verifyEq(closureInsideAccessor, "abc")
    verifyEq(closureInsideAccessorCount, 3)
  }

  Str closureInsideAccessor := "abc"
  {
    get
    {
      closureInsideAccessorCount = 0;
      *closureInsideAccessor.each |Int ch| { closureInsideAccessorCount++ }
      return *closureInsideAccessor
    }
  }
  Int closureInsideAccessorCount

//////////////////////////////////////////////////////////////////////////
// Field Defaults
//////////////////////////////////////////////////////////////////////////

  Void testDefaults()
  {
    verifyEq(b1, false)
    verifyEq(b2, null)
    verifyEq(i1, 0)
    verifyEq(i2, null)
    verifyEq(f1, 0f)
    verifyEq(f2, null)
    verifyEq(s1InCtor, null)
    verifyEq(s2, null)
  }

  Bool b1;  Bool? b2
  Int i1;   Int? i2
  Float f1; Float? f2
  Str s1;   Str? s2
  Str? s1InCtor;

  new make() { s1InCtor = s1; s1 = "" }

//////////////////////////////////////////////////////////////////////////
// Reflect Signatures
//////////////////////////////////////////////////////////////////////////

  Void testReflectSignatures()
  {
    // instance field
    verify(type.slot("count").isField)
    verifyEq(type.field("count").name, "count")
    verifyEq(type.field("count").of, Int#)

    // instance getter
    verify(type.field("count")->getter != null)
    verifyEq(type.field("count")->getter->name, "count")
    verifyEq(type.field("count")->getter->returns, Int#)
    verifyEq(type.field("count")->getter->params->size, 0)

    // instance setter
    verify(type.field("count")->setter != null)
    verifyEq(type.field("count")->setter->name, "count")
    verifyEq(type.field("count")->setter->returns, Void#)
    verifyEq(type.field("count")->setter->params->size, 1)
    verifyEq(type.field("count")->setter->params->get(0)->of, Int#)
  }

//////////////////////////////////////////////////////////////////////////
// ReflectionInstance
//////////////////////////////////////////////////////////////////////////

  Void testReflectionInstance()
  {
    Field f := type.field("count");

    // reflect - getter
    verifyEq(f.get(this), 0);
      verifyEq(getCounter, 1); verifyEq(setCounter, 0);
    verifyEq(f[this], 0);
      verifyEq(getCounter, 2); verifyEq(setCounter, 0);
    verifyEq(f->getter->call(this), 0);
      verifyEq(getCounter, 3); verifyEq(setCounter, 0);
    verifyEq(f->getter->callList([this]), 0);
      verifyEq(getCounter, 4); verifyEq(setCounter, 0);

    // reflect - setter
    f[this] = 5
      verifyEq(*count, 5); verifyEq(getCounter, 4); verifyEq(setCounter, 1);
    f.set(this, 7)
      verifyEq(*count, 7); verifyEq(getCounter, 4); verifyEq(setCounter, 2);
    f->setter->call(this, 9)
      verifyEq(*count, 9); verifyEq(getCounter, 4); verifyEq(setCounter, 3);
    f->setter->callList([this, -1])
      verifyEq(*count, -1); verifyEq(getCounter, 4); verifyEq(setCounter, 4);
  }

//////////////////////////////////////////////////////////////////////////
// Reflection Const
//////////////////////////////////////////////////////////////////////////

  Void testReflectionConst()
  {
    verifyEq(this->constX, 4)
    verifyEq(this->constY, [0,1,2])
    verifyEq(this->constY->isImmutable, true)
    verifyEq(type.field("constX").get(this), 4)
    verifyEq(type.field("constY").get, [0,1,2])

    verifyErr(ReadonlyErr#) { this.type.field("constX").set(this, 5) }
    verifyErr(ReadonlyErr#) { this.type.field("constY").set(null, [9, 8, 7]) }

    verifyErr(ReadonlyErr#) { this->constX = 5 }
    verifyErr(ReadonlyErr#) { this->constY = [9, 8, 7] }
  }

  const Int constX := 4
  const static Int[] constY := [0, 1, 2]

//////////////////////////////////////////////////////////////////////////
// Flags
//////////////////////////////////////////////////////////////////////////

  Void testFlags()
  {
    // all public
    verifyEq(type.field("flagsAllPublic").isPublic, true)
    verifyEq(type.field("flagsAllPublic")->getter->isPublic, true)
    verifyEq(type.field("flagsAllPublic")->setter->isPublic, true)

    // all internal
    verifyEq(type.field("flagsAllInternal").isInternal, true)
    verifyEq(type.field("flagsAllInternal")->getter->isInternal, true)
    verifyEq(type.field("flagsAllInternal")->setter->isInternal, true)

    // all protected
    verifyEq(type.field("flagsAllProtected").isProtected, true)
    verifyEq(type.field("flagsAllProtected")->getter->isProtected, true)
    verifyEq(type.field("flagsAllProtected")->setter->isProtected, true)

    // all private
    verifyEq(type.field("flagsAllPrivate").isPrivate, true)
    verifyEq(type.field("flagsAllPrivate")->getter->isPrivate, true)
    verifyEq(type.field("flagsAllPrivate")->setter->isPrivate, true)

    // public w/ private set
    verifyEq(type.field("flagsPublicPrivateSet").isPublic, true)
    verifyEq(type.field("flagsPublicPrivateSet")->getter->isPublic, true)
    verifyEq(type.field("flagsPublicPrivateSet")->setter->isPrivate, true)

    // protected w/ private set
    verifyEq(type.field("flagsProtectedInternalSet").isProtected, true)
    verifyEq(type.field("flagsProtectedInternalSet")->getter->isProtected, true)
    verifyEq(type.field("flagsProtectedInternalSet")->setter->isInternal, true)

    // readonly public
    verifyEq(type.field("flagsReadonlyPublic").isPublic, true)
    verifyEq(type.field("flagsReadonlyPublic")->getter->isPublic, true)
    verifyEq(type.field("flagsReadonlyPublic")->setter->isPrivate, true)

    // readonly protected
    verifyEq(type.field("flagsReadonlyProtected").isProtected, true)
    verifyEq(type.field("flagsReadonlyProtected")->getter->isProtected, true)
    verifyEq(type.field("flagsReadonlyProtected")->setter->isPrivate, true)

    // readonly internal
    verifyEq(type.field("flagsReadonlyInternal").isInternal, true)
    verifyEq(type.field("flagsReadonlyInternal")->getter->isInternal, true)
    verifyEq(type.field("flagsReadonlyInternal")->setter->isPrivate, true)
  }

  Int flagsAllPublic
  internal Int flagsAllInternal
  protected Int flagsAllProtected
  private Int flagsAllPrivate

  Int flagsPublicPrivateSet { private set }
  protected Int flagsProtectedInternalSet { get; internal set; }

  readonly public Int flagsReadonlyPublic
  protected readonly Int flagsReadonlyProtected
  readonly internal Int flagsReadonlyInternal

//////////////////////////////////////////////////////////////////////////
// makeSetFunc
//////////////////////////////////////////////////////////////////////////

  Void testMakeSetFunc()
  {
    // simple
    s := SerSimple(0, 0)
    f := Field.makeSetFunc([SerSimple#a: 6, SerSimple#b: 7])
    f(s)
    verifyEq(s.a, 6)
    verifyEq(s.b, 7)

    // const
    f = Field.makeSetFunc([ConstMakeSetTest#x: 9, ConstMakeSetTest#y: null, ConstMakeSetTest#z: [0, 1, 2].toImmutable])
    ConstMakeSetTest c := ConstMakeSetTest#.make([f])
    verifyEq(c.x, 9)
    verifyEq(c.y, null)
    verifyEq(c.z, [0, 1, 2])

    verifyErr(ReadonlyErr#) { f(c) }
    verifyErr(ReadonlyErr#) { ConstMakeSetTest#.make([Field.makeSetFunc([ConstMakeSetTest#z: this])]) }
  }

}

//////////////////////////////////////////////////////////////////////////
// OutsideAccessor
//////////////////////////////////////////////////////////////////////////

class OutsideAccessor
{
  static Int getCount(FieldTest test) { return test.count }
  static Void setCount(FieldTest test, Int c) { test.count = c }
  static Int setCountLeave(FieldTest test, Int c) { return test.count = c }
}

//////////////////////////////////////////////////////////////////////////
// OutsideAccessor
//////////////////////////////////////////////////////////////////////////

const class ConstMakeSetTest
{
  new make(|This|? f) { f?.call(this) }
  const Int x
  const Str? y := "foo"
  const Obj? z
}

