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
 * We use FMethodRef to encapsulate how Fantom method call opcodes are
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
    this.parent  = parent;
    this.name    = name;
    this.ret     = ret;
    this.params  = params;
    this.special = toSpecial();
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
    if (special != null) { special.emit(this, code); return; }

    // Fantom constructor calls are static calls on factory method:
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
    if (special != null) { special.emit(this, code); return; }

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
    if (special != null) { special.emit(this, code); return; }

    if (jsig == null)
    {
      StringBuilder s = new StringBuilder();
      String jname = parent.jname();
      String jimpl = parent.jimpl();
      String jslot = parent.jslot(name);
      s.append(jimpl).append('.').append(jslot).append('(');
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
    if (special != null) { special.emit(this, code); return; }

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
// Specials
//////////////////////////////////////////////////////////////////////////

  /**
   * Attempt to map the method reference to a Special function
   * which emits custom bytecode for the method call.
   */
  private Special toSpecial()
  {
    if (name.equals("<new>")) return newSpecial;
    if (name.equals("<class>")) return classLiteralSpecial;
    if (parent.isBool())  return boolSpecials.get(name);
    if (parent.isInt())   return intSpecials.get(name);
    if (parent.isFloat()) return floatSpecials.get(name);
    if (parent.isPrimitiveArray()) return arraySpecials.get(name);
    return null;
  }

  /**
   * Special function which emits the method directly to custom bytecode
   */
  static abstract class Special
  {
    abstract void emit(FMethodRef m, CodeEmit code);
  }

  /**
   * SpecialOp maps directly to a single no arg opcode.
   */
  static class SpecialOp extends Special
  {
    SpecialOp(int op) { this.op = op; }
    void emit(FMethodRef m, CodeEmit code) { code.op(op); }
    private final int op;
  }

  /**
   * SpecialOp2 maps directly to two no arg opcodes.
   */
  static class SpecialOp2 extends Special
  {
    SpecialOp2(int op1, int op2) { this.op1 = op1; this.op2 = op2; }
    void emit(FMethodRef m, CodeEmit code) { code.op(op1); code.op(op2); }
    private final int op1, op2;
  }

  /**
   * SpecialOp4 maps directly to four no arg opcodes.
   */
  static class SpecialOp4 extends Special
  {
    SpecialOp4(int op1, int op2, int op3, int op4) { this.op1 = op1; this.op2 = op2; this.op3 = op3; this.op4 = op4; }
    void emit(FMethodRef m, CodeEmit code) { code.op(op1); code.op(op2); code.op(op3); code.op(op4); }
    private final int op1, op2, op3, op4;
  }

//////////////////////////////////////////////////////////////////////////
// Special Statics on Type
//////////////////////////////////////////////////////////////////////////

  /**
   * The special static call Foo.<new> is used to call the NEW
   * opcode.  FFI constructor calls are emitted as:
   *   CallNew Type.<new>  // allocate object
   *   args...             // arguments are pushed onto stack
   *   CallCtor <init>     // call to java constructor
   */
  static Special newSpecial = new Special()
  {
    public void emit(FMethodRef m, CodeEmit code)
    {
      code.op2(NEW, code.emit().cls(m.parent.jname()));
      code.op(DUP);
    }
  };

  /**
   * The special static call Foo.<class> is used to push a
   * class literal similiar to Java's Foo.class.
   */
  static Special classLiteralSpecial = new Special()
  {
    public void emit(FMethodRef m, CodeEmit code)
    {
      code.op2(LDC_W, code.emit().cls(m.parent.jname()));
    }
  };

//////////////////////////////////////////////////////////////////////////
// Bool Specials
//////////////////////////////////////////////////////////////////////////

  static HashMap<String,Special> boolSpecials = new HashMap<>();
  static
  {
    boolSpecials.put("and", new SpecialOp(IAND));
    boolSpecials.put("or",  new SpecialOp(IOR));
    boolSpecials.put("xor", new SpecialOp(IXOR));
  }

//////////////////////////////////////////////////////////////////////////
// Int Specials
//////////////////////////////////////////////////////////////////////////

  static HashMap<String,Special> intSpecials = new HashMap<>();
  static
  {
    intSpecials.put("negate",     new SpecialOp(LNEG));
    intSpecials.put("plus",       new SpecialOp(LADD));
    intSpecials.put("plusFloat",  new SpecialOp4(DUP2_X2, POP2, L2D, DADD));
    intSpecials.put("minus",      new SpecialOp(LSUB));
    intSpecials.put("mult",       new SpecialOp(LMUL));
    intSpecials.put("multFloat",  new SpecialOp4(DUP2_X2, POP2, L2D, DMUL));
    intSpecials.put("div",        new SpecialOp(LDIV));
    intSpecials.put("mod",        new SpecialOp(LREM));
    intSpecials.put("and",        new SpecialOp(LAND));
    intSpecials.put("or",         new SpecialOp(LOR));
    intSpecials.put("xor",        new SpecialOp(LXOR));
    intSpecials.put("shiftl",     new SpecialOp2(L2I, LSHL));
    intSpecials.put("shiftr",     new SpecialOp2(L2I, LUSHR));
    intSpecials.put("shifta",     new SpecialOp2(L2I, LSHR));
  }

//////////////////////////////////////////////////////////////////////////
// Float Specials
//////////////////////////////////////////////////////////////////////////

  static HashMap<String,Special> floatSpecials = new HashMap<>();
  static
  {
    floatSpecials.put("plus",     new SpecialOp(DADD));
    floatSpecials.put("plusInt",  new SpecialOp2(L2D, DADD));
    floatSpecials.put("minus",    new SpecialOp(DSUB));
    floatSpecials.put("minusInt", new SpecialOp2(L2D, DSUB));
    floatSpecials.put("mult",     new SpecialOp(DMUL));
    floatSpecials.put("multInt",  new SpecialOp2(L2D, DMUL));
    floatSpecials.put("div",      new SpecialOp(DDIV));
    floatSpecials.put("divInt",   new SpecialOp2(L2D, DDIV));
    floatSpecials.put("mod",      new SpecialOp(DREM));
    floatSpecials.put("modInt",   new SpecialOp2(L2D, DREM));
    floatSpecials.put("negate",   new SpecialOp(DNEG));
  }

//////////////////////////////////////////////////////////////////////////
// Array Specials
//////////////////////////////////////////////////////////////////////////

  static Special arraySize = new SpecialOp(ARRAYLENGTH);

  static Special arrayMake = new Special()
  {
    public void emit(FMethodRef m, CodeEmit code)
    {
      switch (m.parent.arrayOfStackType())
      {
        case FTypeRef.BOOL:   code.op1(NEWARRAY, 4); break;
        case FTypeRef.CHAR:   code.op1(NEWARRAY, 5); break;
        case FTypeRef.FLOAT:  code.op1(NEWARRAY, 6); break;
        case FTypeRef.DOUBLE: code.op1(NEWARRAY, 7); break;
        case FTypeRef.BYTE:   code.op1(NEWARRAY, 8); break;
        case FTypeRef.SHORT:  code.op1(NEWARRAY, 9); break;
        case FTypeRef.INT:    code.op1(NEWARRAY, 10); break;
        case FTypeRef.LONG:   code.op1(NEWARRAY, 11); break;
        default: throw new IllegalStateException(""+m.parent);
      }
    }
  };

  static Special arrayGet = new Special()
  {
    public void emit(FMethodRef m, CodeEmit code)
    {
      switch (m.parent.arrayOfStackType())
      {
        case FTypeRef.BOOL:   code.op(BALOAD); break;
        case FTypeRef.BYTE:   code.op(BALOAD); break;
        case FTypeRef.SHORT:  code.op(SALOAD); break;
        case FTypeRef.CHAR:   code.op(CALOAD); break;
        case FTypeRef.INT:    code.op(IALOAD); break;
        case FTypeRef.LONG:   code.op(LALOAD); break;
        case FTypeRef.FLOAT:  code.op(FALOAD); break;
        case FTypeRef.DOUBLE: code.op(DALOAD); break;
        default: throw new IllegalStateException(""+m.parent);
      }
    }
  };

  static Special arraySet = new Special()
  {
    public void emit(FMethodRef m, CodeEmit code)
    {
      switch (m.parent.arrayOfStackType())
      {
        case FTypeRef.BOOL:   code.op(BASTORE); break;
        case FTypeRef.BYTE:   code.op(BASTORE); break;
        case FTypeRef.SHORT:  code.op(SASTORE); break;
        case FTypeRef.CHAR:   code.op(CASTORE); break;
        case FTypeRef.INT:    code.op(IASTORE); break;
        case FTypeRef.LONG:   code.op(LASTORE); break;
        case FTypeRef.FLOAT:  code.op(FASTORE); break;
        case FTypeRef.DOUBLE: code.op(DASTORE); break;
        default: throw new IllegalStateException(""+m.parent);
      }
    }
  };

  static HashMap<String,Special> arraySpecials = new HashMap<>();
  static
  {
    arraySpecials.put("size", arraySize);
    arraySpecials.put("make", arrayMake);
    arraySpecials.put("get",  arrayGet);
    arraySpecials.put("set",  arraySet);
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
  private Special special;
}

