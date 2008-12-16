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

//////////////////////////////////////////////////////////////////////////
// Field Reflection
//////////////////////////////////////////////////////////////////////////

  Void testFields()
  {
    t := Type.find("[java]java.lang::System")
    verifyField(t.field("out"), t, Type.find("[java]java.io::PrintStream"))

    t = Type.find("[java]java.io::File")
    verifyField(t.field("separator"), t, Str#)
    verifyField(t.field("separatorChar"), t, Type.find("[java]::char"))
  }

  Void verifyField(Field f, Type parent, Type of)
  {
    verifySame(f.parent, parent)
    verifySame(f.of, of)
    verify(f.of == of)
  }

//////////////////////////////////////////////////////////////////////////
// Method Reflection
//////////////////////////////////////////////////////////////////////////

  Void testMethods()
  {
    t := Type.find("[java]java.io::DataInput")

    // primitives with direct Fan mappings
    verifyMethod(t.method("readBoolean"), t, Bool#)
    verifyMethod(t.method("readLong"),    t, Int#)
    verifyMethod(t.method("readDouble"),  t, Float#)
    verifyMethod(t.method("readUTF"),     t, Str#)

    // FFI primitives
    verifyMethod(t.slot("readByte"),    t, Type.find("[java]::byte"))
    verifyMethod(t.method("readShort"), t, Type.find("[java]::short"))
    verifyMethod(t.method("readChar"),  t, Type.find("[java]::char"))
    verifyMethod(t.method("readInt"),   t, Type.find("[java]::int"))
    verifyMethod(t.method("readFloat"), t, Type.find("[java]::float"))
  }

  Void verifyMethod(Method m, Type parent, Type ret, Type[] params := Type[,])
  {
    verifySame(m.parent, parent)
    verifySame(m.returns, ret)
    verify(m.returns == ret)
    verifyEq(m.params.isRO, true)
    verifyEq(m.params.size, params.size)
    params.each |Type p, Int i| { verifySame(p, m.params[i].of) }
  }

//////////////////////////////////////////////////////////////////////////
// Dynamic Invoke
//////////////////////////////////////////////////////////////////////////

  Void testDynamicInvoke()
  {
    // basics
    now := DateTime.now
    date := Type.find("[java]java.util::Date").make
    verifyEq(date.type.method("getYear").callOn(date, [,]), now.year-1900)
    verifyEq(date.type.method("getYear").call1(date), now.year-1900)
    verifyEq(date.type.method("getYear").call([date]), now.year-1900)
    verifyEq(date->getYear, now.year-1900)
    verifyEq(date->toString, date.toStr)

    // static field primitive coercion
    it := Type.find("[java]fanx.test::InteropTest").make
    it->snumb = 'a'; verifyEq(it->snumb, 'a')
    it->snums = 'b'; verifyEq(it->snums, 'b')
    it->snumc = 'c'; verifyEq(it->snumc, 'c')
    it->snumi = 'd'; verifyEq(it->snumi, 'd')
    it->snuml = 'e'; verifyEq(it->snuml, 'e')
    it->snumf = 'f'.toFloat; verifyEq(it->snumf, 'f'.toFloat)
    it->snumd = 'g'.toFloat; verifyEq(it->snumd, 'g'.toFloat)

    // methods override fields
    verifyEq(it->numi, 1000)
    it->numi(-1234)
    verifyEq(it->numf, -1234f)
    verifyEq(it->num, -1234)

    // methods
    it->num = 100
    it->xnumb(100); verifyEq(it->xnumb(), 100)
    verifyEq(it->xnums(), 100)
    verifyEq(it->xnumc(), 100)
    verifyEq(it->xnumi(), 100)
    verifyEq(it->xnuml(), 100)
    verifyEq(it->xnumf(), 100.toFloat)
    verifyEq(it->xnumd(), 100.toFloat)

    // verify numi can be looked up as both field and method
    numiField := it.type.field("numi")
    numi := it.type.method("numi")
    verifySame(it.type.slot("numi"), numiField)
    si := it.type.method("si") // static test

    // numi as field
    verifyEq(numiField.get(it), 'i')
    numiField.set(it, 2008)
    verifyEq(numiField.get(it), 2008)

    // numi 4x overloaded - call
    verifyEq(numi.call([it, 8877]), null)
    verifyEq(numi.call([it]), 8877)
    verifyEq(numi.call([it, 6, 4]), 10)
    verifyEq(numi.call([it, "55"]), 55)
    verifyEq(si.call(["55", 6]), 61) // static

    // numi 4x overloaded - callX
    verifyEq(numi.call2(it, 8877), null)
    verifyEq(numi.call1(it), 8877)
    verifyEq(numi.call3(it, 6, 4), 10)
    verifyEq(numi.call2(it, "55"), 55)
    verifyEq(si.call2("55", 6), 61) // static

    // numi 4x overloaded - callOn
    verifyEq(numi.callOn(it, [8877]), null)
    verifyEq(numi.callOn(it, [,]), 8877)
    verifyEq(numi.callOn(it, [6, 4]), 10)
    verifyEq(numi.callOn(it, ["55"]), 55)
    verifyEq(si.callOn(null, ["55", 6]), 61) // static

    // numi 4x overloaded - trap
    it->num = -99
    verifyEq(it->numi, -99)
    verifyEq(it->numi(3, 4), 7)
    verifyEq(it->numi("999"), 999)
    verifyEq(it->si("2", 9), 11) // static

    // Obj[] arrays
    it->initArray
    Obj[] array := it->array1
    verifySame(array[0], it->a)
    verifySame(array[1], it->b)
    verifySame(array[2], it->c)
    array[2] = it->a
    it->array1(array)
    verifySame(array[2], it->a)
  }
}