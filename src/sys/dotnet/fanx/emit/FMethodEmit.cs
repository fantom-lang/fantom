//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   5 Oct 06  Andy Frank  Creation
//

using System.Collections;
using System.Reflection;
using Fan.Sys;
using Fanx.Fcode;
using Fanx.Util;

namespace Fanx.Emit
{
  /// <summary>
  /// FMethodEmit is used to emit IL methods from fcode methods. It
  /// encapsulates lot of nitty details like when to include an implicit
  /// self paramater, etc.
  /// </summary>
  public class FMethodEmit
  {

  //////////////////////////////////////////////////////////////////////////
  // Constructor
  //////////////////////////////////////////////////////////////////////////

    /// <summary>
    /// Constructor.
    /// </summary>
    public FMethodEmit(FTypeEmit emit, FMethod method)
    {
      this.emitter    = emit.emitter;
      this.emit       = emit;
      this.method     = method;
      this.code       = method.m_code;
      this.name       = FanUtil.toDotnetMethodName(method.m_name);
      this.paramLen   = method.m_paramCount;
      this.isStatic   = (method.m_flags & FConst.Static) != 0;
      this.isInternal = false; //(method.m_flags & FConst.Internal) != 0;
      this.isPrivate  = (method.m_flags & FConst.Private) != 0;
      this.isAbstract = (method.m_flags & FConst.Abstract) != 0;
      this.isVirtual  = (method.m_flags & FConst.Virtual) != 0;
      this.isOverride = (method.m_flags & FConst.Override) != 0;
      this.isCtor     = (method.m_flags & FConst.Ctor) != 0;
      this.isNative   = (method.m_flags & FConst.Native) != 0;
      this.isHide     = false; // only used for make/make_
      this.ret        = emit.pod.typeRef(method.m_inheritedRet);
      this.selfName   = emit.selfName;
    }

    /// <summary>
    /// Constructor.
    /// </summary>
    public FMethodEmit(FTypeEmit emit)
    {
      this.emitter = emit.emitter;
      this.emit = emit;
    }

  //////////////////////////////////////////////////////////////////////////
  // Emit
  //////////////////////////////////////////////////////////////////////////

    /// <summary>
    /// Emit a standard instance/static class method.
    /// </summary>
    public void emitStandard()
    {
      // emit method
      doEmit();

      // emit param default wrappers
      emitWrappers();
    }

    /// <summary>
    /// Emit a constructor - constructors get created as a static
    /// factory methods, so that that CallNew can just push args
    /// and invoke them
    ///
    ///   fan:
    ///     class Foo { new make(Long a) { ... } }
    ///   .net:
    ///     static Foo make(Long a) { return make_(new Foo(), a) }
    ///     static Foo make_(Foo self, Long a) { ... return self }
    ///
    /// We call the first method "make" the "factory" and the
    /// second method "make_" the "body".  CallNew opcodes are
    /// routed to the ctor factory, and CallCtor opcodes are routed
    /// to the ctor body.
    /// </summary>
    public void emitCtor()
    {
      string ctorName = this.name;

      // both factory and body are static from CLR's perspective
      this.isStatic = true;
      this.isHide   = true;

      // first emit the body with implicit self
      this.name   = ctorName + "_";
      this.self   = true;
      doEmit();
      PERWAPI.MethodDef make = emitter.methodDef;

      // emit body default parameter wrappers
      emitWrappers();

      // then emit the factory
      this.name = ctorName;
      this.self = false;
      this.ret  = emit.pod.typeRef(emit.type.m_self);
      this.code = null;

      PERWAPI.CILInstructions code = doEmit();
      PERWAPI.Method ctor = emitter.findMethod(selfName, ".ctor", new string[0], "System.Void");
      code.MethInst(PERWAPI.MethodOp.newobj, ctor);
      code.Inst(PERWAPI.Op.dup);
      pushArgs(code, false, method.m_paramCount);
      code.MethInst(PERWAPI.MethodOp.call, make);
      code.Inst(PERWAPI.Op.ret);

      // emit factory default parameter wrappers
      emitWrappers();
    }

    /// <summary>
    /// Emit a native method
    /// <summary>
    public void emitNative()
    {
      // emit an empty method
      this.code = null;

      // emit code which calls the peer
      PERWAPI.CILInstructions code = doEmit();
      if (!emitter.stub)
      {
        if (isStatic)
        {
          string[] parTypes = new string[paramLen];
          for (int i=0; i<paramLen; i++)
            parTypes[i] = emit.nname(method.m_vars[i].type);

          PERWAPI.Method peerMeth = emitter.findMethod(selfName + "Peer", name, parTypes, ret.nname());
          pushArgs(code, false, paramLen);
          code.MethInst(PERWAPI.MethodOp.call, peerMeth);
        }
        else
        {
          string[] parTypes = new string[paramLen+1];
          parTypes[0] = selfName;
          for (int i=0; i<paramLen; i++)
            parTypes[i+1] = emit.nname(method.m_vars[i].type);

          PERWAPI.Method peerMeth = emitter.findMethod(selfName + "Peer", name, parTypes, ret.nname());
          peerMeth.AddCallConv(PERWAPI.CallConv.Instance);
          code.Inst(PERWAPI.Op.ldarg_0);
          code.FieldInst(PERWAPI.FieldOp.ldfld, emit.peerField);
          pushArgs(code, true, paramLen);
          code.MethInst(PERWAPI.MethodOp.call, peerMeth);
        }
      }
      code.Inst(PERWAPI.Op.ret);

      // emit default parameter wrappers
      emitWrappers();
    }

    /// <summary>
    /// Emit the method as a mixin interface
    /// </summary>
    public void emitMixinInterface()
    {
      // we only emit instance methods in the interface
      if (isStatic || isCtor) return;

      // set abstract flag and clear code
      code = null;

      // force public
      isInternal = false;
      isPrivate  = false;

      // force abstract virtual
      isAbstract = true;
      isVirtual = true;

      // emit main
      doEmit();

      // emit a signature for each overload based on param defaults
      for (int i=0; i<method.m_paramCount; i++)
      {
        if (method.m_vars[i].def != null)
        {
          paramLen = i;
          doEmit();
        }
      }
    }

    /// <summary>
    /// Emit the method as a mixin body class which ends with _.
    /// <summary>
    public void emitMixinBody()
    {
      // skip abstract methods without code
      if (method.m_code == null) return;

      // instance methods have an implicit self
      if (!isStatic)
      {
        this.self = true;
        this.selfName = selfName.Substring(0, selfName.Length-1); // lose _
      }

      // bodies are always static and never virtual
      isStatic = true;
      isVirtual = false;
      isOverride = false;

      // emit main body
      //MethodEmit main = DoEmit();
      doEmit();

      // emit param default wrappers
      emitWrappers();
    }

    /// <summary>
    /// Emit a mixin router from a class to the mixin body methods.
    /// </summary>
    public void emitMixinRouter(Method m)
    {
      string parent  = FanUtil.toDotnetTypeName(m.parent());
      string name    = FanUtil.toDotnetMethodName(m.name());
      string ret     = FanUtil.toDotnetTypeName(m.inheritedReturns());
      string[] parTypes = new string[] { parent };
      List pars      = m.@params();
      int paramCount = pars.sz();

      // find first param with default value
      int firstDefault = paramCount;
      for (int i=0; i<paramCount; i++)
        if (((Param)pars.get(i)).hasDefault())
          { firstDefault = i; break; }

      // generate routers
      for (int i=firstDefault; i<=paramCount; i++)
      {
        string[] myParams = new string[i];
        string[] myParamNames = new string[i];
        string[] implParams = new string[i+1];
        implParams[0] = parent;

        for (int j=0; j<i; j++)
        {
          Param param = (Param)m.@params().get(j);
          Type pt = param.type();
          string s = FanUtil.toDotnetTypeName(pt);
          myParams[j] = s;
          myParamNames[j] = param.name();
          implParams[j+1] = s;
        }

        // CLR requires public virtual
        PERWAPI.MethAttr attr = PERWAPI.MethAttr.Public | PERWAPI.MethAttr.Virtual;

        PERWAPI.CILInstructions code = emitter.emitMethod(name, ret, myParamNames, myParams,
          attr, new string[0], new string[0]);
        code.Inst(PERWAPI.Op.ldarg_0); // push this
        for (int p=0; p<i; p++)
        {
          // push args
          Param param = (Param)m.@params().get(p);
          FCodeEmit.loadVar(code, FanUtil.toDotnetStackType(param.type()), p+1);
        }
        PERWAPI.Method meth = emitter.findMethod(parent + "_", name, implParams, ret);
        code.MethInst(PERWAPI.MethodOp.call, meth);
        code.Inst(PERWAPI.Op.ret);
      }
    }

    /// <summary>
    /// The CLR requires all methods implemented by an interface
    /// to be marked as virtual.  However, Fantom (and Java) allow
    /// this:
    ///
    ///   mixin Mixin
    ///   {
    ///     abstract Long foo()
    ///   }
    ///
    ///   class Base
    ///   {
    ///     Long foo() { return 5 }
    ///   }
    ///
    ///   class Child : Base, Mixin
    ///   {
    ///     // don't need to implement foo() since Base defined it
    ///   }
    ///
    /// So to work correctly in the CLR we need to trap this case
    /// and emit a virtual router method on child to satisfy the
    /// interface requirement:
    ///
    ///   class Child : Base, Mixin
    ///   {
    ///     public virtual Long foo() { return base.foo(); }
    ///   }
    ///
    ///   TODO - optimize the intra-pod case
    ///
    /// </summary>
    public void emitInterfaceRouter(Type implType, Method m)
    {
      string impl = FanUtil.toDotnetTypeName(implType);
      string name = m.name();
      string ret  = FanUtil.toDotnetTypeName(m.inheritedReturns());
      List pars   = m.@params();
      int paramCount = pars.sz();

      // find first param with default value
      int firstDefault = paramCount;
      for (int i=0; i<paramCount; i++)
        if (((Param)pars.get(i)).hasDefault())
          { firstDefault = i; break; }

      // generate routers
      for (int i=firstDefault; i<=paramCount; i++)
      {
        string[] myParams = new string[i];
        string[] myParamNames = new string[i];

        for (int j=0; j<i; j++)
        {
          Param param = (Param)m.@params().get(j);
          Type pt = param.type();
          string s = FanUtil.toDotnetTypeName(pt);
          myParams[j] = s;
          myParamNames[j] = param.name();
        }

        // CLR requires public virtual
        PERWAPI.MethAttr attr = PERWAPI.MethAttr.Public | PERWAPI.MethAttr.Virtual;

        PERWAPI.CILInstructions code = emitter.emitMethod(name, ret, myParamNames, myParams,
          attr, new string[0], new string[0]);
        code.Inst(PERWAPI.Op.ldarg_0); // push this
        for (int p=0; p<i; p++)
        {
          // push args
          Param param = (Param)m.@params().get(p);
          FCodeEmit.loadVar(code, FanUtil.toDotnetStackType(param.type()), p+1);
        }
        PERWAPI.Method meth = emitter.findMethod(impl, name, myParams, ret);
        code.MethInst(PERWAPI.MethodOp.call, meth);
        code.Inst(PERWAPI.Op.ret);
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // Param Default Wrappers
  //////////////////////////////////////////////////////////////////////////

    /// <summary>
    /// Emit wrappers.
    /// </summary>
    private void emitWrappers()
    {
      // change flags so that defaults aren't abstract
      bool oldAbstract = this.isAbstract;
      this.isAbstract = false;

      PERWAPI.MethodDef main = emitter.methodDef;

      // handle generating default param wrappers
      for (int i=0; i<method.m_paramCount; i++)
        if (method.m_vars[i].def != null)
          emitWrapper(main, i);
      this.paramLen = method.m_paramCount;

      this.isAbstract = oldAbstract;
    }

    /// <summary>
    /// Emit wrapper.
    /// </summary>
    private void emitWrapper(PERWAPI.MethodDef main, int paramLen)
    {
      // use explicit param count, and clear code
      this.paramLen = paramLen;
      this.code     = null;
      int numArgs   = isStatic && !self ? paramLen : paramLen+1;

      // TODO - this code probably isn't quite right, since it looks
      // like we generate local variables even when they might not be
      // used.  Doesn't hurt anything, but is probably more efficient
      // if we could determine that from the fcode.

      // define our locals
      int numLocals = method.m_paramCount - paramLen;
      string[] localNames = new string[numLocals];
      string[] localTypes = new string[numLocals];
      for (int i=paramLen; i<method.m_paramCount; i++)
      {
        localNames[i-paramLen] = method.m_vars[i].name;
        localTypes[i-paramLen] = emit.nname(method.m_vars[i].type);
      }

      // emit code
      PERWAPI.CILInstructions code = doEmit(localNames, localTypes);

      // push arguments passed thru
      pushArgs(code, !(isStatic && !self), paramLen);

      // emit default arguments
      FCodeEmit.Reg[] regs = FCodeEmit.initRegs(emit.pod, isStatic, method.m_vars);
      int maxLocals = method.maxLocals();
      int maxStack  = 16; // TODO - add additional default expr stack height
      for (int i=paramLen; i<method.m_paramCount; i++)
      {
        FCodeEmit ce = new FCodeEmit(emit, method.m_vars[i].def, code, regs, emit.pod.typeRef(method.m_ret));
        ce.paramCount = numArgs;
        ce.vars = method.m_vars;
        ce.isStatic = isStatic;
// TODO - is this correct?
ce.emit(false);  // don't emit debug s cope for wrappers
        maxStack = System.Math.Max(maxStack, 2+i+8);
      }
      // TODO
      //code.maxLocals = maxLocals;
      //code.maxStack  = maxStack;

      // call master implementation
      if (isStatic)
        code.MethInst(PERWAPI.MethodOp.call, main);
      else
        code.MethInst(PERWAPI.MethodOp.callvirt, main);

      // return
      code.Inst(PERWAPI.Op.ret);
    }

  //////////////////////////////////////////////////////////////////////////
  // Emit
  //////////////////////////////////////////////////////////////////////////

    /// <summary>
    /// This is the method that all the public emitX methods
    /// route to once everything is setup correctly.
    /// </summary>
    protected PERWAPI.CILInstructions doEmit()
    {
      return doEmit(null, null);
    }

    private PERWAPI.CILInstructions doEmit(string[] localNames, string[] localTypes)
    {
      int paramCount = paramLen;
      if (self) paramCount++;

      string[] parNames = new string[paramCount];
      string[] parTypes = new string[paramCount];
      for (int i=0; i<paramCount; i++)
      {
        int z = i;
        if (self) z--;

        if (self && i == 0)
        {
          parNames[0] = "self";
          parTypes[0] = selfName;
        }
        else
        {
          parNames[i] = method.m_vars[z].name;
          parTypes[i] = emit.nname(method.m_vars[z].type);
        }
      }

      if (localNames == null)
      {
        localNames = new string[method.m_localCount];
        localTypes = new string[method.m_localCount];
        for (int i=0; i<method.m_localCount; i++)
        {
          int z = i + paramCount;
          if (self) z--;

          localNames[i] = method.m_vars[z].name;
          localTypes[i] = emit.nname(method.m_vars[z].type);
        }
      }

      /*
      PERWAPI.MethAttr attr;
      if (isPrivate) attr = PERWAPI.MethAttr.Public; //PERWAPI.MethAttr.Private;
      else if (isInternal) attr = PERWAPI.MethAttr.Assembly;
      else attr = PERWAPI.MethAttr.Public;
      */
      PERWAPI.MethAttr attr = isInternal
        ? PERWAPI.MethAttr.Assembly
        : PERWAPI.MethAttr.Public;

      if (isStatic)   attr |= PERWAPI.MethAttr.Static;
      if (isAbstract) attr |= PERWAPI.MethAttr.Abstract;
      if (isVirtual)  attr |= PERWAPI.MethAttr.Virtual;
      if (isOverride) attr |= PERWAPI.MethAttr.Virtual;
      if (isHide)     attr |= PERWAPI.MethAttr.HideBySig;

      PERWAPI.CILInstructions code = emitter.emitMethod(name, ret.nname(), parNames, parTypes, attr,
        localNames, localTypes);
      if (this.code != null) new FCodeEmit(emit, method, code).emit();

      return code;
    }

  //////////////////////////////////////////////////////////////////////////
  // Code Utils
  //////////////////////////////////////////////////////////////////////////

    /// <summary>
    /// Push the specified number of arguments onto the stack.
    /// </summary>
    private void pushArgs(PERWAPI.CILInstructions code, bool self, int count)
    {
      if (self) code.Inst(PERWAPI.Op.ldarg_0);
      for (int i=0; i<count; i++)
      {
        FTypeRef var = emit.pod.typeRef(method.m_vars[i].type);
        FCodeEmit.loadVar(code, var.stackType, self ? i+1 : i);
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    internal Emitter emitter;  // the emitter for the current assembly
    internal FTypeEmit emit;   // parent type class emitter
    internal FMethod method;   // fan method info
    internal FBuf code;        // code to emit
    internal string name;      // method name
    internal bool isStatic;    // are we emitting a static method
    internal bool isInternal;  // are we emitting a internal method
    internal bool isPrivate;   // are we emitting a private method
    internal bool isAbstract;  // are we emitting an abstract method
    internal bool isVirtual;   // are we emitting a virtual method
    internal bool isOverride;  // are we emitting an overridden method
    internal bool isCtor;      // are we emitting a constructor
    internal bool isNative;    // are we emitting a native method
    internal bool isHide;      // do we need to hide a base method
    internal FTypeRef ret;     // java return sig
    internal bool self;        // add implicit self as first parameter
    internal string selfName;  // class name for self if self is true
    internal int paramLen;     // number of parameters to use

  }
}