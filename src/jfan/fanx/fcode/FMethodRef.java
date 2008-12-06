//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   26 Dec 05  Brian Frank  Creation
//   06 Dec 07  Brian Frank  Rename from FTuple
//
package fanx.fcode;

import java.io.*;
import java.util.*;
import fanx.emit.*;

/**
 * FMethodRef is used to reference methods for a call operation.
 * We use FMethodRef to encapsulate how Fan method call opcodes are
 * emitted to Java bytecode.
 */
public class FMethodRef
  implements EmitConst, FConst
{

//////////////////////////////////////////////////////////////////////////
// Constructors
//////////////////////////////////////////////////////////////////////////

  /**
   * Construct from read.
   */
  private FMethodRef(FTypeRef parent, String name, FTypeRef ret, FTypeRef[] params)
  {
    this.parent = parent;
    this.name   = name;
    this.ret    = ret;
    this.params = params;
  }

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  /**
   * Return qname.
   */
  public String toString()
  {
    return parent + "." + name + "()";
  }

//////////////////////////////////////////////////////////////////////////
// Emit
//////////////////////////////////////////////////////////////////////////

  public void emitCallNew(CodeEmit code)
  {
    // FFI constructor calls are emitted as:
    //   CallNew Type.<new>  // allocate object
    //   args...             // arguments are pushed onto stack
    //   CallCtor <init>     // call to java constructor
    if (name.equals("<new>"))
    {
      code.op2(NEW, code.emit().cls(parent.jname()));
      code.op(DUP);
      return;
    }

    // Fan constructor calls are static calls on factory method:
    //   static Foo make(...) {}
    if (jsig == null)
    {
      StringBuilder s = new StringBuilder();
      s.append(parent.jname()).append('.').append(name).append('(');
      for (int i=0; i<params.length; ++i) params[i].jsig(s);
      s.append(')');
      parent.jsig(s);
      jsig = s.toString();
    }

    int method = code.emit().method(jsig);
    code.op2(INVOKESTATIC, method);
  }

  public void emitCallCtor(CodeEmit code)
  {
    // constructor implementations (without object allocation) are
    // implemented as static factory methods with "$" appended:
    //   static make$(Foo self, ...) {}
    // however if the name is <init> this is a FFI constructor
    // call which is emitted as:
    //   CallNew Type.<new>  // allocate object
    //   args...             // arguments are pushed onto stack
    //   CallCtor <init>     // call to java constructor
    boolean javaCtor = name.equals("<init>");
    if (jsigAlt == null)
    {
      StringBuilder s = new StringBuilder();
      s.append(parent.jname()).append('.').append(name);
      if (javaCtor)
        s.append('(');
      else
        s.append("$(L").append(parent.jname()).append(';');
      for (int i=0; i<params.length; ++i) params[i].jsig(s);
      s.append(')').append('V');
      jsigAlt = s.toString();
    }

    int method = code.emit().method(jsigAlt);
    if (javaCtor)
      code.op2(INVOKESPECIAL, method);
    else
      code.op2(INVOKESTATIC, method);
  }

  public void emitCallStatic(CodeEmit code)
  {
    // check for calls which optimize to a single opcode
    if (parent.isPrimitiveArray())
    {
      if (name.equals("make")) { code.op1(NEWARRAY, newArrayType(parent.arrayOfStackType())); return; }
    }

    if (jsig == null)
    {
      StringBuilder s = new StringBuilder();
      s.append(parent.jimpl()).append('.').append(name).append('(');
      for (int i=0; i<params.length; ++i) params[i].jsig(s);
      s.append(')');
      ret.jsig(s);
      jsig = s.toString();
    }

    int method = code.emit().method(jsig);
    code.op2(INVOKESTATIC, method);
  }

  public void emitCallVirtual(CodeEmit code)
  {
    // check for calls which optimize to a single opcode
    if (parent.isPrimitiveArray())
    {
      if (name.equals("size")) { code.op(ARRAYLENGTH); return; }
      if (name.equals("get"))  { code.op(loadArrayOp(parent.arrayOfStackType())); return; }
      if (name.equals("set"))  { code.op(storeArrayOp(parent.arrayOfStackType())); return; }
    }

    if (jsig == null)
    {
      StringBuilder s = new StringBuilder();
      String jname = parent.jname();
      String jimpl = parent.jimpl();
      s.append(jimpl).append('.').append(name).append('(');
      if (jname != jimpl)
      {
        // if the implementation class is different than the representation
        // class then we route to static such as FanFloat.abs(double self)
        mask |= INVOKE_VIRT_AS_STATIC;
        parent.jsig(s);
      }
      for (int i=0; i<params.length; ++i) params[i].jsig(s);
      s.append(')');
      ret.jsig(s);
      jsig = s.toString();
    }

    int method = code.emit().method(jsig);
    if ((mask & INVOKE_VIRT_AS_STATIC) != 0)
      code.op2(INVOKESTATIC, method);
    else
      code.op2(INVOKEVIRTUAL, method);
  }

  public void emitCallNonVirtual(CodeEmit code)
  {
    // nonvirtuals Obj use jsigAlt because we don't
    // route to static helpers like we do for call virtual
    //  - CallVirtual:     Obj.toStr => static FanObj.toStr(Object)
    //  - CallNonVirtual:  Obj.toStr => FanObj.toStr()
    if (jsigAlt == null)
    {
      StringBuilder s = new StringBuilder();
      String jname = parent.jname();
      String jimpl = parent.jimpl();
      s.append(jimpl).append('.').append(name).append('(');
      for (int i=0; i<params.length; ++i) params[i].jsig(s);
      s.append(')');
      ret.jsig(s);
      jsigAlt = s.toString();
    }

    int method = code.emit().method(jsigAlt);
    code.op2(INVOKESPECIAL, method);
  }

  public void emitCallMixinStatic(CodeEmit code)
  {
    if (jsig == null)
    {
      StringBuilder s = new StringBuilder();
      s.append(parent.jimpl()).append("$.").append(name).append('(');
      for (int i=0; i<params.length; ++i) params[i].jsig(s);
      s.append(')');
      ret.jsig(s);
      jsig = s.toString();
    }

    int method = code.emit().method(jsig);
    code.op2(INVOKESTATIC, method);
  }

  public void emitCallMixinVirtual(CodeEmit code)
  {
    // when we lazily create jsig we also compute the
    // number of arguments taking wide parameters into account
    if (jsig == null)
    {
      StringBuilder s = new StringBuilder();
      s.append(parent.jname()).append('.').append(name).append('(');
      int numArgs = 1;
      for (int i=0; i<params.length; ++i)
      {
        params[i].jsig(s);
        numArgs += params[i].isWide() ? 2 : 1;
      }
      s.append(')');
      ret.jsig(s);
      jsig = s.toString();
      iiNumArgs = numArgs;
    }

    int method = code.emit().interfaceRef(jsig);
    code.op2(INVOKEINTERFACE, method);
    code.info.u1(iiNumArgs );
    code.info.u1(0);
  }

  public void emitCallMixinNonVirtual(CodeEmit code)
  {
    // call the mixin "$" implementation method directly
    if (jsigAlt == null)
    {
      StringBuilder s = new StringBuilder();
      s.append(parent.jname()).append("$.").append(name).append('(');
      parent.jsig(s);
      for (int i=0; i<params.length; ++i) params[i].jsig(s);
      s.append(')');
      ret.jsig(s);
      jsigAlt = s.toString();
    }

    int method = code.emit().method(jsigAlt);
    code.op2(INVOKESTATIC, method);
  }

//////////////////////////////////////////////////////////////////////////
// Arrays
//////////////////////////////////////////////////////////////////////////

  static int newArrayType(int stackType)
  {
    switch (stackType)
    {
      case FTypeRef.BOOL:   return 4;
      case FTypeRef.CHAR:   return 5;
      case FTypeRef.FLOAT:  return 6;
      case FTypeRef.DOUBLE: return 7;
      case FTypeRef.BYTE:   return 8;
      case FTypeRef.SHORT:  return 9;
      case FTypeRef.INT:    return 10;
      case FTypeRef.LONG:   return 11;
      default: throw new IllegalStateException(""+stackType);
    }
  }

  static int loadArrayOp(int stackType)
  {
    switch (stackType)
    {
      case FTypeRef.BOOL:   return BALOAD;
      case FTypeRef.BYTE:   return BALOAD;
      case FTypeRef.SHORT:  return SALOAD;
      case FTypeRef.CHAR:   return CALOAD;
      case FTypeRef.INT:    return IALOAD;
      case FTypeRef.LONG:   return LALOAD;
      case FTypeRef.FLOAT:  return FALOAD;
      case FTypeRef.DOUBLE: return DALOAD;
      default: throw new IllegalStateException(""+stackType);
    }
  }

  static int storeArrayOp(int stackType)
  {
    switch (stackType)
    {
      case FTypeRef.BOOL:   return BASTORE;
      case FTypeRef.BYTE:   return BASTORE;
      case FTypeRef.SHORT:  return SASTORE;
      case FTypeRef.CHAR:   return CASTORE;
      case FTypeRef.INT:    return IASTORE;
      case FTypeRef.LONG:   return LASTORE;
      case FTypeRef.FLOAT:  return FASTORE;
      case FTypeRef.DOUBLE: return DASTORE;
      default: throw new IllegalStateException(""+stackType);
    }
  }

//////////////////////////////////////////////////////////////////////////
// IO
//////////////////////////////////////////////////////////////////////////

  /**
   * Parse from fcode constant pool format:
   *   methodRef
   *   {
   *     u2 parent  (typeRefs.def)
   *     u2 name    (names.def)
   *     u2 retType (typeRefs.def)
   *     u1 paramCount
   *     u2[paramCount] params (typeRefs.def)
   *   }
   */
  public static FMethodRef read(FStore.Input in) throws IOException
  {
    FPod fpod = in.fpod;
    FTypeRef parent = fpod.typeRef(in.u2());
    String name = fpod.name(in.u2());
    FTypeRef ret = fpod.typeRef(in.u2());
    int numParams = in.u1();
    FTypeRef[] params = noParams;
    if (numParams > 0)
    {
      params = new FTypeRef[numParams];
      for (int i=0; i<numParams; ++i) params[i] = fpod.typeRef(in.u2());
    }
    return new FMethodRef(parent, name, ret, params);
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  static final FTypeRef[] noParams = new FTypeRef[0];

  static final int INVOKE_VIRT_AS_STATIC = 0x0001;

  public final FTypeRef parent;
  public final String name;
  public final FTypeRef ret;
  public final FTypeRef[] params;
  private String jsig;         // cache for standard Java signature
  private String jsigAlt;      // alternate cache for ctors and non-virtuals signature
  private int mask;            // cache for mask - lazy init when jsig is initialized
  private int iiNumArgs = -1;  // invoke interface - lazy init when jsig is initialized
}