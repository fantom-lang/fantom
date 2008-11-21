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
**   [java]::char
**   [java]::int
**   [java]::float
**
class JavaPrimitives : JavaPod
{

  new make(JavaBridge bridge)
    : super(bridge, "", null)
  {
    this.byteType  = JavaType(this, "byte")
    this.shortType = JavaType(this, "short")
    this.charType  = JavaType(this, "char")
    this.intType   = JavaType(this, "int")
    this.floatType = JavaType(this, "float")
    this.types = [intType, charType, byteType, shortType, floatType]
  }

  JavaType byteType
  JavaType shortType
  JavaType charType
  JavaType intType
  JavaType floatType

}