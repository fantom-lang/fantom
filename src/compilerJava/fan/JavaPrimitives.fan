//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   17 Nov 08  Brian Frank  Creation
//

using compiler

**
** JavaPrimitives is the pod namespace used to represent primitives:
**   [java]::byte
**   [java]::short
**   [java]::int
**   [java]::float
**
class JavaPrimitives : JavaPod
{

  new make(JavaBridge bridge)
    : super(bridge, "", null)
  {
    this.byteType  = defineByte
    this.shortType = defineShort
    this.intType   = defineInt
    this.floatType = defineFloat
    this.types = [intType, byteType, shortType, floatType]
  }

  JavaType defineByte()
  {
    t := JavaType(this, "byte")
    t.loadSlots(
    [
      "b2l": b2l = convert(t, "b2l", t, ns.intType),
      "l2b": l2b = convert(t, "l2b", ns.intType, t)
    ])
    return t
  }

  JavaType defineShort()
  {
    t := JavaType(this, "short")
    t.loadSlots(
    [
      "s2l": s2l = convert(t, "s2l", t, ns.intType),
      "l2s": l2s = convert(t, "l2s", ns.intType, t)
    ])
    return t
  }

  JavaType defineInt()
  {
    t := JavaType(this, "int")
    t.loadSlots(
    [
      "i2l": i2l = convert(t, "i2l", t, ns.intType),
      "l2i": l2i = convert(t, "l2i", ns.intType, t)
    ])
    return t
  }

  JavaType defineFloat()
  {
    t := JavaType(this, "float")
    t.loadSlots(
    [
      "f2d": f2d = convert(t, "f2d", t, ns.floatType),
      "d2f": d2f = convert(t, "d2f", ns.floatType, t)
    ])
    return t
  }

  JavaMethod convert(JavaType t, Str n, CType from, CType to)
  {
    return JavaMethod
    {
      parent = t
      name   = n
      flags  = FConst.Public | FConst.Static
      returnType = to
      params = [JavaParam { name="arg"; paramType=from }]
    }
  }


  JavaType byteType
  JavaType shortType
  JavaType intType
  JavaType floatType

  JavaMethod b2l;
  JavaMethod l2b;
  JavaMethod s2l;
  JavaMethod l2s;
  JavaMethod i2l;
  JavaMethod l2i;
  JavaMethod f2d;
  JavaMethod d2f;
}