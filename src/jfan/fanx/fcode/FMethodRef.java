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
    // Fan constructor calls are static calls on factory
    // method; FFI constructor calls are emitted as:
    //   CallNew Type.<new>  // allocate object
    //   args...             // arguments are pushed onto stack
    //   CallCtor <init>     // call to java constructor
    if (name.equals("<new>"))
    {
      String jname = parent.jname();
      code.op2(NEW, code.emit().cls(jname));
      code.op(DUP);
    }
    else
    {
      doEmit(code, CallNew, INVOKESTATIC);
    }
  }

  public void emitCallCtor(CodeEmit code)
  {
    // constructor implementations (without object allow) are
    // implemented as static factory methods with "$" appended
    // FFI constructor calls are emitted as:
    //   CallNew Type.<new>  // allocate object
    //   args...             // arguments are pushed onto stack
    //   CallCtor <init>     // call to java constructor

    String parent = this.parent.jname();

    boolean javaCtor = name.equals("<init>");
    StringBuilder s = new StringBuilder();
    s.append(parent).append('.').append(name);
    if (javaCtor)
      s.append('(');
    else
      s.append('$').append('(').append('L').append(parent).append(';');
    for (int i=0; i<params.length; ++i) params[i].jsig(s);
    s.append(')').append('V');

    int method = code.emit().method(s.toString());
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

    doEmit(code, CallStatic, INVOKESTATIC);
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

    // normal call operation
    doEmit(code, CallVirtual, INVOKEVIRTUAL);
  }

  public void emitCallNonVirtual(CodeEmit code)
  {
    // invokespecial in Java is really queer - it can only
    // be used for calls in the declaring class (basically
    // for private methods or super call)
    doEmit(code, CallNonVirtual, INVOKESPECIAL);
  }

  public void emitCallMixinStatic(CodeEmit code)
  {
    doEmit(code, CallMixinStatic, INVOKESTATIC);
  }

  public void emitCallMixinVirtual(CodeEmit code)
  {
    int nargs = toInvokeInterfaceNumArgs();

    String sig = jcall(CallMixinVirtual).sig;
    int method = code.emit().interfaceRef(sig);
    code.op2(INVOKEINTERFACE, method);
    code.info.u1(nargs);
    code.info.u1(0);
  }

  public void emitCallMixinNonVirtual(CodeEmit code)
  {
    // call the mixin "$" implementation method
    // directly (but don't use cache)

    String parent = this.parent.jname();

    StringBuilder s = new StringBuilder();
    s.append(parent).append("$.").append(name).append('(');
    s.append('L').append(parent).append(';');
    for (int i=0; i<params.length; ++i) params[i].jsig(s);
    s.append(')');
    ret.jsig(s);

    int method = code.emit().method(s.toString());
    code.op2(INVOKESTATIC, method);
  }

  private void doEmit(CodeEmit code, int fanOp, int javaOp)
  {
    FMethodRef.JCall jcall = jcall(fanOp);
    int method = code.emit().method(jcall.sig);
    if (jcall.invokestatic) javaOp = INVOKESTATIC;
    code.op2(javaOp, method);
  }

//////////////////////////////////////////////////////////////////////////
// Fan-to-Java Mapping
//////////////////////////////////////////////////////////////////////////

  /**
   * Map a fcode method signature to a Java method emit signature.
   */
  public JCall jcall(int opcode)
  {
    JCall jcall = this.jcall;
    if (jcall == null || opcode == CallNonVirtual) // don't use cache on nonvirt (see below)
    {
      // if the type signature is java/lang then we route
      // to static methods on FanObj, FanFloat, etc
      String jname = parent.jname();
      String impl = parent.jimpl();
      boolean explicitSelf = false;
      if (jname != impl)
      {
        explicitSelf = opcode == CallVirtual;
      }
      else
      {
        // if no object method then ok to use cache
        if (jcall != null) return jcall;
      }

      StringBuilder s = new StringBuilder();
      s.append(impl);
      if (opcode == CallMixinStatic) s.append('$');
      s.append('.').append(name).append('(');
      if (explicitSelf) parent.jsig(s);
      for (int i=0; i<params.length; ++i) params[i].jsig(s);
      s.append(')');

      if (opcode == CallNew) parent.jsig(s); // factory
      else ret.jsig(s);

      jcall = new JCall();
      jcall.invokestatic = explicitSelf;
      jcall.sig = s.toString();

      // we don't cache nonvirtuals on Obj b/c of conflicting signatures:
      //  - CallVirtual:     Obj.toStr => static FanObj.toStr(Object)
      //  - CallNonVirtual:  Obj.toStr => FanObj.toStr()
      if (jname == impl || opcode != CallNonVirtual)
        this.jcall = jcall;
    }
    return jcall;
  }

  public static class JCall
  {
    public boolean invokestatic;
    public String sig;
  }

  /**
   * Get this MethodRef's number of arguments for an invokeinterface
   * operation taking into account wide parameters.
   */
  private int toInvokeInterfaceNumArgs()
  {
    if (this.iiNumArgs < 0)
    {
      int numArgs = 1;
      for (int i=0; i<params.length; ++i)
        numArgs += params[i].isWide() ? 2 : 1;
      this.iiNumArgs = numArgs;
    }
    return this.iiNumArgs;
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

  public final FTypeRef parent;
  public final String name;
  public final FTypeRef ret;
  public final FTypeRef[] params;
  private int iiNumArgs = -1;
  private JCall jcall;
}