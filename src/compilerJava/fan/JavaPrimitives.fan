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
    ns := bridge.ns

    this.booleanType = JavaType(this, "boolean", ns.boolType.toNullable)
    this.byteType    = JavaType(this, "byte" ,   ns.intType.toNullable)
    this.shortType   = JavaType(this, "short",   ns.intType.toNullable)
    this.charType    = JavaType(this, "char",    ns.intType.toNullable)
    this.intType     = JavaType(this, "int",     ns.intType.toNullable)
    this.longType    = JavaType(this, "long",    ns.intType.toNullable)
    this.floatType   = JavaType(this, "float",   ns.floatType.toNullable)
    this.doubleType  = JavaType(this, "double",  ns.floatType.toNullable)
    this.types = [intType, charType, byteType, shortType, floatType, longType, doubleType, booleanType]
  }

  JavaType byteType
  JavaType shortType
  JavaType charType
  JavaType intType
  JavaType floatType
  JavaType booleanType  // just used for multi-dim arrays
  JavaType longType     // just used for multi-dim arrays
  JavaType doubleType   // just used for multi-dim arrays

}