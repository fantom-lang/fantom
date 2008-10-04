//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   25 Mar 06  Brian Frank  Creation
//
package fanx.emit;

import java.util.*;
import fan.sys.*;
import fan.sys.List;
import fanx.fcode.*;
import fanx.util.*;

/**
 * FMethodEmit is used to emit Java bytecode methods from fcode methods.
 * It encapsulates lot of nitty details like when to include an implicit
 * self paramater, etc.
 */
public class FMethodEmit
  implements EmitConst
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  /**
   * Constructor
   */
  public FMethodEmit(FTypeEmit emit, FMethod method)
  {
    this.emit     = emit;
    this.method   = method;
    this.code     = method.code;
    this.name     = FanUtil.toJavaMethodName(method.name);
    this.jflags   = FTypeEmit.jflags(method.flags);
    this.paramLen = method.paramCount;
    this.isStatic = (method.flags & FConst.Static) != 0;
    this.isCtor   = (method.flags & FConst.Ctor) != 0;
    this.isNative = (method.flags & FConst.Native) != 0;
    this.ret      = emit.jname(method.inheritedRet); // we don't actually use Java covariance
    this.isVoid   = ret.equals("fan/sys/Void");
    this.selfName = emit.selfName;
  }

  /**
   * Constructor
   */
  public FMethodEmit(FTypeEmit emit)
  {
    this.emit = emit;
  }

//////////////////////////////////////////////////////////////////////////
// Emit
//////////////////////////////////////////////////////////////////////////

  /**
   * Emit a standard instance/static class method.
   */
  public void emitStandard()
  {
    // emit method
    MethodEmit main = doEmit();

    // emit param default wrappers
    emitWrappers(main);
  }

  /**
   * Emit a constructor - constructors get created as a static
   * factory methods, so that that CallNew can just push args
   * and invoke them
   *   fan:
   *     class Foo { new make(Int a) { ... } }
   *   java:
   *     static Foo make(Int a) { return make$(new Foo(), a) }
   *     static Foo make$(Foo self, Int a) { ... return self }
   *
   * We call the first method "make" the "factory" and the
   * second method "make$" the "body".  CallNew opcodes are
   * routed to the ctor factory, and CallCtor opcodes are routed
   * to the ctor body.
   */
  public void emitCtor()
  {
    String ctorName = this.name;

    // both factory and body are static from Java's perspective
    this.jflags |= STATIC;
    this.isStatic = true;

    // first emit the body with implicit self
    this.name   = ctorName + "$";
    this.self   = true;
    this.isVoid = true;
    MethodEmit body = doEmit();

    // emit body default parameter wrappers
    emitWrappers(body);

    // then emit the factory
    this.name   = ctorName;
    this.self   = false;
    this.isVoid = false;
    this.ret    = selfName;
    this.code   = null;
    MethodEmit factory = doEmit();
    CodeEmit code = factory.emitCode();
    code.maxLocals = method.paramCount;
    code.maxStack  = 2 + method.paramCount;
    code.op2(NEW, emit.cls(selfName));
    code.op(DUP);
    code.op2(INVOKESPECIAL, emit.method(selfName+ ".<init>()V"));
    code.op(DUP);
    pushArgs(code, method.paramCount);
    code.op2(INVOKESTATIC, body.ref());
    code.op(ARETURN);

    // emit factory default parameter wrappers
    emitWrappers(factory);
  }

  /**
   * Emit a native method
   */
  public void emitNative()
  {
    // emit an empty method
    this.code = null;
    MethodEmit main = doEmit();

    // emit code which calls the peer
    CodeEmit code = main.emitCode();
    if (isStatic)
    {
      int peerMethod = emit.method(selfName + "Peer." + name + sig);
      code.maxLocals = paramLen;
      code.maxStack  = Math.max(paramLen, 1);
      pushArgs(code, paramLen);
      code.op2(INVOKESTATIC, peerMethod);
    }
    else
    {
      // generate peer's signature with self
      this.self = true;
      String sig = signature();
      this.self = false;

      int peerMethod = emit.method(selfName + "Peer." + name + sig);
      code.maxLocals = paramLen+2;
      code.maxStack  = paramLen+2;
      code.op(ALOAD_0);
      code.op2(GETFIELD, emit.peerField.ref());
      pushArgs(code, paramLen+1);
      code.op2(INVOKEVIRTUAL, peerMethod);
    }
    code.op(isVoid ? RETURN : ARETURN);

    // emit default parameter wrappers
    emitWrappers(main);
  }


  /**
   * Emit the method as a mixin interface
   */
  public void emitMixinInterface()
  {
    // we only emit instance methods in the interface
    if (isStatic || isCtor) return;

    // set abstract flag and clear code
    this.jflags |= ABSTRACT;
    this.code = null;

    // emit main
    doEmit();

    // emit a signature for each overload based on param defaults
    for (int i=0; i<method.paramCount; ++i)
    {
      if (method.vars[i].def != null)
      {
        paramLen = i;
        doEmit();
      }
    }
  }

  /**
   * Emit the method as a mixin body class which ends with $.
   */
  public void emitMixinBody()
  {
    // skip abstract methods without code
    if (method.code == null) return;

    // instance methods have an implicit self
    if (!isStatic) this.self = true;

    // bodies are always static
    this.jflags |= STATIC;

    // emit main body
    MethodEmit main = doEmit();

    // emit param default wrappers
    emitWrappers(main);
  }

  /**
   * Emit a mixin router from a class to the mixin body methods.
   */
  public void emitMixinRouter(Method m)
  {
    String parent  = "fan/" + m.parent().pod().name().val + "/" + m.parent().name().val;
    String name    = FanUtil.toJavaMethodName(m.name().val);
    int jflags     = emit.jflags(m.flags());
    List params    = m.params();
    int paramCount = params.sz();

    // find first param with default value
    int firstDefault = paramCount;
    for (int i=0; i<paramCount; ++i)
      if (((Param)params.get(i)).hasDefault().val)
        { firstDefault = i; break; }

    // generate routers
    for (int i=firstDefault; i<=paramCount; ++i)
    {
      String mySig = signature(m, null, i);
      String implSig = signature(m, parent, i);
      boolean isVoid = mySig.endsWith("V");

      MethodEmit me = emit.emitMethod(name, mySig, jflags);
      CodeEmit code = me.emitCode();
      code.maxLocals = 1+i;
      code.maxStack = 1+i;
      pushArgs(code, 1+i); // push this + params
      code.op2(INVOKESTATIC, emit.method(parent + "$." + name + implSig));
      code.op(isVoid ? RETURN : ARETURN);
    }
  }

//////////////////////////////////////////////////////////////////////////
// Param Default Wrappers
//////////////////////////////////////////////////////////////////////////

  /**
   * Emit wrappers.
   */
  private void emitWrappers(MethodEmit main)
  {
    // change flags so that defaults aren't abstract
    int oldFlags = this.jflags;
    this.jflags = jflags & ~ABSTRACT;

    // handle generating default param wrappers
    for (int i=0; i<method.paramCount; ++i)
      if (method.vars[i].def != null)
        emitWrapper(main, i);
    this.paramLen = method.paramCount;

    this.jflags = oldFlags;
  }

  /**
   * Emit wrapper.
   */
  private void emitWrapper(MethodEmit main, int paramLen)
  {
    // use explicit param count, and clear code
    this.paramLen = paramLen;
    this.code     = null;
    int numArgs   = isStatic && !self ? paramLen : paramLen+1;

    // emit code
    CodeEmit code  = doEmit().emitCode();

    // push arguments passed thru
    pushArgs(code, numArgs);

    // emit default arguments
    int maxLocals = method.maxLocals();
    int maxStack  = 16; // TODO - add additional default expr stack height
    for (int i=paramLen; i<method.paramCount; ++i)
    {
      FCodeEmit e = new FCodeEmit(emit, method.vars[i].def, code);
      e.emit();
      maxStack = Math.max(maxStack, 2+i+8);
    }
    code.maxLocals = maxLocals;
    code.maxStack  = maxStack;

    // call master implementation
    code.op2((main.flags & STATIC) != 0 ? INVOKESTATIC : INVOKEVIRTUAL, main.ref());

    // return
    code.op(isVoid ? RETURN : ARETURN);
  }

//////////////////////////////////////////////////////////////////////////
// Emit
//////////////////////////////////////////////////////////////////////////

  /**
   * This is the method that all the public emitX methods
   * route to once everything is setup correctly.
   */
  protected MethodEmit doEmit()
  {
    this.sig = signature();
    this.me = emit.emitMethod(name, sig, jflags);
    if (code != null)
    {
      new FCodeEmit(emit, method, me.emitCode()).emit();
    }
    return this.me;
  }

//////////////////////////////////////////////////////////////////////////
// Signature Utils
//////////////////////////////////////////////////////////////////////////

  /**
   * Generate the java method signature base on our current setup.
   */
  private String signature()
  {
    StringBuilder sig = new StringBuilder();

    // params (with optional implicit self)
    sig.append('(');
    if (self) sig.append('L').append(selfName).append(';');
    for (int i=0; i<paramLen; ++i)
    {
      FMethodVar param = method.vars[i];
      sig.append('L').append(emit.jname(param.type)).append(';');
    }
    sig.append(')');

    // return
    if (isVoid)
      sig.append('V');
    else
      sig.append('L').append(ret).append(';');

    return sig.toString();
  }

  /**
   * Generate a method signature from a reflection sys::Method.
   */
  private String signature(Method m, String self, int paramLen)
  {
    StringBuilder sig = new StringBuilder();

    // params
    sig.append('(');
    if (self != null) sig.append('L').append(self).append(';');
    for (int i=0; i<paramLen; ++i)
    {
      Param param = (Param)m.params().get(i);
      toSig(sig, param.of());
    }
    sig.append(')');

    // return
    if (m.returns() == Sys.VoidType)
      sig.append('V');
    else
      toSig(sig, m.inheritedReturns());

    return sig.toString();
  }

  /**
   * Append specified type to the signature string.
   */
  private static void toSig(StringBuilder s, Type t)
  {
    s.append('L').append(FanUtil.toJavaTypeSig(t)).append(';');
  }

//////////////////////////////////////////////////////////////////////////
// Code Utils
//////////////////////////////////////////////////////////////////////////

  /**
   * Push the specified number of arguments onto the stack.
   */
  private static void pushArgs(CodeEmit code, int count)
  {
    switch (count)
    {
      case 0:
        return;
      case 1:
        code.op(ALOAD_0);
        return;
      case 2:
        code.op(ALOAD_0);
        code.op(ALOAD_1);
        return;
      case 3:
        code.op(ALOAD_0);
        code.op(ALOAD_1);
        code.op(ALOAD_2);
        return;
      case 4:
        code.op(ALOAD_0);
        code.op(ALOAD_1);
        code.op(ALOAD_2);
        code.op(ALOAD_3);
        return;
      default:
        code.op(ALOAD_0);
        code.op(ALOAD_1);
        code.op(ALOAD_2);
        code.op(ALOAD_3);
        for (int i=4; i<count; ++i)
          code.op1(ALOAD, i);
        return;
    }
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  FTypeEmit emit;    // parent type class emitter
  FMethod method;    // fan method info
  FBuf code;         // code to emit
  String name;       // method name
  int jflags;        // java flags
  boolean isStatic;  // are we emitting a static method
  boolean isCtor;    // are we emitting a constructor
  boolean isNative;  // are we emitting a native method
  boolean isVoid;    // is return void
  String ret;        // java return sig
  boolean self;      // add implicit self as first parameter
  String selfName;   // class name for self if self is true
  int paramLen;      // number of parameters to use
  String sig;        // last java signature emitted
  MethodEmit me;     // last java method emitted


}