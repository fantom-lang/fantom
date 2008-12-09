//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   23 Nov 08  Brian Frank  Creation
//

using compiler

**
** ReflectTest
**
class ReflectTest : JavaTest
{

//////////////////////////////////////////////////////////////////////////
// Reflection
//////////////////////////////////////////////////////////////////////////

  Void testLiterals()
  {
    compile(
     "using [java] java.util

      class Foo
      {
        Type date()  { return Date# }
        Type jint()  { return Type.find(\"[java]::int\") }
        Type array() { return Type.find(\"[java]java.util::[Date\") }
        Type list()  { return Type.find(\"[java]java.util::Date[]\") }
        Type map()   { return Type.find(\"[[java]java.util::Date:[java]java.util::ArrayLsit]\") }
      }")

    obj := pod.types.first.make

    Type date := obj->date
    verifyEq(date.pod,   null)
    verifyEq(date.name,  "Date")
    verifyEq(date.qname, "[java]java.util::Date")
    verifyEq(date.signature, "[java]java.util::Date")

    Type jint := obj->jint
    verifyEq(jint.pod,   null)
    verifyEq(jint.name,  "int")
    verifyEq(jint.qname, "[java]::int")
    verifyEq(jint.signature, "[java]::int")

    Type array := obj->array
    verifyEq(array.pod,   null)
    verifyEq(array.name,  "[Date")
    verifyEq(array.qname, "[java]java.util::[Date")
    verifyEq(array.signature, "[java]java.util::[Date")

    Type list := obj->list
    verifyEq(list.pod,   Pod.find("sys"))
    verifyEq(list.name,  "List")
    verifyEq(list.qname, "sys::List")
    verifyEq(list.signature, "[java]java.util::Date[]")
    verifyEq(list.params["V"].qname, "[java]java.util::Date")

    Type map := obj->map
    verifyEq(map.pod,   Pod.find("sys"))
    verifyEq(map.name,  "Map")
    verifyEq(map.qname, "sys::Map")
    verifyEq(map.signature, "[[java]java.util::Date:[java]java.util::ArrayLsit]")
    verifyEq(map.params["K"].qname, "[java]java.util::Date")
    verifyEq(map.params["V"].qname, "[java]java.util::ArrayLsit")
  }

//////////////////////////////////////////////////////////////////////////
// JavaType: java.util.Date
//////////////////////////////////////////////////////////////////////////

  Void testDate()
  {
    t := Type.find("[java]java.util::Date")
    verifySame(Type.find("[java]java.util::Date"), t)

    // naming
    verifyEq(t.name, "Date")
    verifyEq(t.qname, "[java]java.util::Date")
    verifyEq(t.signature, "[java]java.util::Date")
    verifyEq(t.toStr, t.signature)

    // flags
    verifyEq(t.isPublic, true)
    verifyEq(t.isInternal, false)
    verifyEq(t.isAbstract, false)
    verifyEq(t.isFinal, false)
    verifyEq(t.isMixin, false)
    verifyEq(t.isEnum, false)
    verifyEq(t.isConst, false)

    // inheritance
    verifyEq(t.base, Obj#)
    verifyEq(t.mixins.isRO, true)
    verifyEq(t.inheritance.isRO, true)
    verifyEq(t.mixins.rw.sort,
      Type[Type.find("[java]java.io::Serializable"),
       Type.find("[java]java.lang::Cloneable"),
       Type.find("[java]java.lang::Comparable"),
      ].sort)
    verifyEq(t.inheritance.rw.sort, Type[t, Obj#].addAll(t.mixins).sort)
    verifyEq(t.fits(Obj#), true)
    verifyEq(t.fits(t), true)
    verifyEq(t.fits(Type.find("[java]java.lang::Cloneable")), true)
    verifyEq(t.fits(Str#), false)

    // nullable
    verifyEq(t.toNullable.signature, "[java]java.util::Date?")
    verifyEq(t.toNullable.isNullable, true)
    verifySame(t.toNullable, t.toNullable)
    verifySame(t.toNullable.toNonNullable, t)
  }

//////////////////////////////////////////////////////////////////////////
// JavaType: java.lang.Runnable
//////////////////////////////////////////////////////////////////////////

  Void testRunnable()
  {
    t := Type.find("[java]java.lang::Runnable")
    verifySame(Type.find("[java]java.lang::Runnable"), t)

    // naming
    verifyEq(t.name, "Runnable")
    verifyEq(t.toStr, "[java]java.lang::Runnable")

    // flags
    verifyEq(t.isPublic, true)
    verifyEq(t.isInternal, false)
    verifyEq(t.isAbstract, true)
    verifyEq(t.isFinal, false)
    verifyEq(t.isMixin, true)
    verifyEq(t.isEnum, false)
    verifyEq(t.isConst, false)

    // inheritance
    verifyEq(t.base, Obj#)
    verifyEq(t.mixins.isRO, true)
    verifyEq(t.inheritance.isRO, true)
    verifyEq(t.mixins, Type[,])
    verifyEq(t.inheritance, Type[t, Obj#])
  }

}