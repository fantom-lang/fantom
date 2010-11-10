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
  new make(JavaPod pod, Str name, CType? primitiveNullable := null)
  {
    this.pod    = pod
    this.name   = name
    this.qname  = pod.name + "::" + name
    this.base   = ns.objType
    this.mixins = CType[,]
    this.primitiveNullable = primitiveNullable
  }

//////////////////////////////////////////////////////////////////////////
// CType
//////////////////////////////////////////////////////////////////////////

  override CNamespace ns() { pod.ns }
  override readonly JavaPod pod
  override readonly Str name
  override readonly Str qname
  override Str signature() { qname }

  override CFacet? facet(Str qname) { null }

  override CType? base { get { load; return &base } }
  override CType[] mixins { get { load; return &mixins } }
  override Int flags { get { load; return &flags } }

  override Bool isForeign() { true }
  override Bool isSupported() { arrayRank <= 1 } // multi-dimensional arrays unsupported

  override Bool isVal() { pod is JavaPrimitives }

  override Bool isNullable() { false }
  override once CType toNullable() { primitiveNullable ?: NullableType(this) }
  private CType? primitiveNullable

  override Bool isGeneric() { false }
  override Bool isParameterized() { false }
  override Bool isGenericParameter() { false }

  override once CType toListOf() { ListType(this) }

  override readonly Str:CSlot slots { get { load; return &slots } }

  override once COperators operators() { COperators(this) }

  override CSlot? slot(Str name) { slots[name] }

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

    if (isArray && !arrayOf.isPrimitive && !arrayOf.isArray)
      return inferredArrayOf.toListOf

    return this
  }

//////////////////////////////////////////////////////////////////////////
// Fits
//////////////////////////////////////////////////////////////////////////

  override Bool fits(CType t)
  {
    if (CType.super.fits(t)) return true
    t = t.toNonNullable
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
    if (isPrimitive)
    {
      flags = FConst.Public
    }
    else
    {
      // map Java members to slots using Java reflection
      pod.bridge.loadType(this, slots)

      // merge in sys::Obj slots
      ns.objType.slots.each |CSlot s|
      {
        if (s.isCtor) return
        if (slots[name] == null) slots[s.name] = s
      }
    }
    this.slots = slots
    loaded = true
  }

//////////////////////////////////////////////////////////////////////////
// Primitives
//////////////////////////////////////////////////////////////////////////

  Bool isPrimitive()
  {
    return pod === pod.bridge.primitives && arrayRank == 0
  }

  Bool isPrimitiveIntLike()
  {
    primitives := pod.bridge.primitives
    return this === primitives.intType ||
           this === primitives.charType ||
           this === primitives.shortType ||
           this === primitives.byteType
  }

  Bool isPrimitiveFloat()
  {
    primitives := pod.bridge.primitives
    return this === primitives.floatType
  }

//////////////////////////////////////////////////////////////////////////
// Arrays
//////////////////////////////////////////////////////////////////////////

  **
  ** Return if this is an interop array like
  ** 'fanx.interop.IntArray' which models 'int[]'.
  **
  Bool isInteropArray()
  {
    return pod.isInterop && name.endsWith("Array")
  }

  **
  ** Is this a array type such as '[java]foo.bar::[Baz'
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
  ** The arrayOf field always stores a JavaType so that we
  ** can correctly resolve the FFI qname.  This means that
  ** that an array of java.lang.Object will have an arrayOf
  ** value of [java]java.lang::Object.  This method correctly
  ** maps the arrayOf map to its canonical Fantom type.
  **
  CType? inferredArrayOf()
  {
    if (arrayOf == null) return null
    CType x := JavaReflect.objectClassToDirectFanType(ns, arrayOf.toJavaClassName) ?: arrayOf
    return x.toNullable
  }

  **
  ** Get the type which is an array of this type.
  **
  once JavaType toArrayOf()
  {
    return JavaType(pod, "[" + name)
    {
      it.arrayRank = this.arrayRank + 1
      it.arrayOf = this
    }
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  **
  ** Get this type's Java class name:
  **   [java]java.lang::Class  => java.lang.Class
  **   [java]java.lang::[Class => [Ljava.lang.Class;
  **
  once Str toJavaClassName()
  {
    s := StrBuf()
    if (isArray)
    {
      rank := arrayRank
      rank.times { s.addChar('[') }
      s.addChar('L')
      s.add(pod.packageName).addChar('.')
      s.add(name[rank .. -rank])
      s.addChar(';')
    }
    else
    {
      s.add(pod.packageName).addChar('.').add(name)
    }
    return s.toStr
  }

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
      it.parent = this
      it.name = "<new>"
      it.flags = FConst.Ctor + FConst.Public
      it.returnType = this
      it.params = JavaParam[,]
    }
  }

  **
  ** We use an implicit method called "<class>" on
  ** each type as the protocol for telling the Java runtime
  ** to load a class literal
  **
  static CMethod classLiteral(JavaBridge bridge, CType base)
  {
    return JavaMethod
    {
      it.parent = base
      it.name = "<class>"
      it.flags = FConst.Public + FConst.Static
      it.returnType = bridge.classType
      it.params = JavaParam[,]
    }
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private Bool loaded := false
}