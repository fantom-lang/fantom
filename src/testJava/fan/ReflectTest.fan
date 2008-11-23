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

}