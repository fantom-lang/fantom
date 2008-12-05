//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   17 Nov 08  Brian Frank  Creation
//

using compiler

**
** JavaType is the implementation of CType for a Java class.
**
class JavaType : CType
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  **
  ** Construct with loaded Type.
  **
  new make(JavaPod pod, Str name)
  {
    this.pod    = pod
    this.name   = name
    this.qname  = pod.name + "::" + name
    this.base   = ns.objType
    this.mixins = CType[,]
  }

//////////////////////////////////////////////////////////////////////////
// CType
//////////////////////////////////////////////////////////////////////////

  override CNamespace ns() { return pod.ns }
  override readonly JavaPod pod
  override readonly Str name
  override readonly Str qname
  override Str signature() { return qname }

  override readonly CType? base { get { load; return @base } }
  override readonly CType[] mixins { get { load; return @mixins } }
  override readonly Int flags { get { load; return @flags } }

  override Bool isForeign() { return true }
  override Bool isSupported() { return arrayRank <= 1 } // multi-dimensional arrays unsupported

  Bool isPrimitive() { return pod === pod.bridge.primitives && arrayRank == 0 }
  override Bool isValue() { return false }

  override Bool isNullable() { return false }
  override once CType toNullable() { return NullableType(this) }

  override Bool isGeneric() { return false }
  override Bool isParameterized() { return false }
  override Bool isGenericParameter() { return false }

  override once CType toListOf() { return ListType(this) }

  override readonly Str:CSlot slots { get { load; return @slots } }

  override CSlot? slot(Str name) { return slots[name] }

  ** Handle the case where a field and method have the same
  ** name; in this case the field will always be first with
  ** a linked list to the overloaded methods
  override CMethod? method(Str name)
  {
    x := slots[name]
    if (x == null) return null
    if (x is JavaField) return ((JavaField)x).next
    return x
  }

  override CType inferredAs()
  {
    if (isPrimitive)
      return name == "float" ? ns.floatType : ns.intType

    return this
  }

//////////////////////////////////////////////////////////////////////////
// Fits
//////////////////////////////////////////////////////////////////////////

  override Bool fits(CType t)
  {
    if (CType.super.fits(t)) return true
    if (t is JavaType) return fitsJava(t)
    return fitsFan(t)
  }

  private Bool fitsJava(JavaType t)
  {
    // * => java.lang.Object
    if (t.qname == "[java]java.lang::Object") return !isPrimitive

    // array => array
    if (isArray && t.isArray) return arrayOf.fits(t.arrayOf)

    // doesn't fit
    return false
  }

  private Bool fitsFan(CType t)
  {
    // floats => Float; byte,short,char,int => Int
    if (isPrimitive) return name == "float" ? t.isFloat : t.isInt

    // arrays => List
    if (isArray && t is ListType) return arrayOf.fits(((ListType)t).v)

    // doesn't fit
    return false
  }

//////////////////////////////////////////////////////////////////////////
// Load
//////////////////////////////////////////////////////////////////////////

  private Void load()
  {
    if (loaded) return
    slots := Str:CSlot[:]
    if (!isPrimitive) doLoad(slots)
    this.slots = slots
    loaded = true
  }

  private native Void doLoad(Str:CSlot slots)

//////////////////////////////////////////////////////////////////////////
// Arrays
//////////////////////////////////////////////////////////////////////////

  **
  ** Is this a array type such as [java]foo.bar::[Baz
  **
  Bool isArray() { return arrayRank > 0 }

  **
  ** The rank of the array where 0 is not an array,
  ** 1 is one dimension, 2 is two dimensional, etc.
  **
  Int arrayRank := 0

  **
  ** If this an array, this is the component type.
  **
  JavaType? arrayOf

  **
  ** Get the type which is an array of this type.
  **
  once JavaType toArrayOf()
  {
    return JavaType(pod, "[" + name)
    {
      arrayRank = this.arrayRank + 1
      arrayOf = this
    }
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  **
  ** We use an implicit constructor called "<new>" on
  ** each type as the protocol for telling the Java runtime
  ** to perform a 'new' opcode for object allocation:
  **   CallNew Type.<new>  // allocate object
  **   args...             // arguments are pushed onto stack
  **   CallCtor <init>     // call to java constructor
  **
  once CMethod newMethod()
  {
    return JavaMethod
    {
      parent = this
      name = "<new>"
      flags = FConst.Ctor | FConst.Public
      returnType = this
      params = JavaParam[,]
    }
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private Bool loaded := false
}