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

  Bool isPrimitive() { return pod === pod.bridge.primitives }
  override Bool isValue() { return false }

  override Bool isNullable() { return false }
  override once CType toNullable() { return NullableType(this) }

  override Bool isGeneric() { return false }
  override Bool isParameterized() { return false }
  override Bool isGenericParameter() { return false }

  override once CType toListOf() { return ListType(this) }

  override readonly Str:CSlot slots { get { load; return @slots } }

  override CSlot? slot(Str name) { return slots[name] }

//////////////////////////////////////////////////////////////////////////
// Load
//////////////////////////////////////////////////////////////////////////

  private Void load()
  {
    if (loaded) return
    slots := Str:CSlot[:]
    doLoad(slots)
    loadSlots(slots)
  }

  internal Void loadSlots(Str:CSlot slots)
  {
    this.slots = slots
    loaded = true
  }

  private native Void doLoad(Str:CSlot slots)

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