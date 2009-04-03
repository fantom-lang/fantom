//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   9 Jan 07  Andy Frank  Creation
//

using Fan.Sys;
using Fanx.Fcode;
using Fanx.Util;

namespace Fanx.Emit
{
  /// <summary>
  /// FErrEmit emits a normal Err class type, which requires a custom
  /// constructor and a special type$Val inner class.
  /// </summary>
  public class FErrEmit : FClassEmit
  {

  //////////////////////////////////////////////////////////////////////////
  // Constructor
  //////////////////////////////////////////////////////////////////////////

    public FErrEmit(Emitter emitter, Type parent, FType type)
      : base(emitter, parent, type)
    {
    }

  //////////////////////////////////////////////////////////////////////////
  // Overrides
  //////////////////////////////////////////////////////////////////////////

    protected override void emitInstanceInit(FMethod m)
    {
      hasInstanceInit = true;

      // make peer
      if (isNative)
        throw new System.Exception("No native support for Err subclasses");

      // stub ctor2
      PERWAPI.MethodDef ctor2 = emitter.findMethod(selfName, ".ctor",
        new string[] { "Fan.Sys.Err/Val" }, "System.Void") as PERWAPI.MethodDef;
      ctor2.SetMethAttributes(
        PERWAPI.MethAttr.Public |
        PERWAPI.MethAttr.HideBySig |
        PERWAPI.MethAttr.SpecialRTSpecialName);
      ctor2.AddCallConv(PERWAPI.CallConv.Instance);

      // no arg constructor -> calls this(Err/Val)
      PERWAPI.CILInstructions code = ctor.CreateCodeBuffer();
      code.Inst(PERWAPI.Op.ldarg_0);
      PERWAPI.Method valctor = emitter.findMethod(className+"/Val", ".ctor", new string[0], "System.Void");
      code.MethInst(PERWAPI.MethodOp.newobj, valctor);
      code.MethInst(PERWAPI.MethodOp.call, ctor2);
      code.Inst(PERWAPI.Op.ret);

      // arg constructor with Err$Val (and init implementation)
      code = ctor2.CreateCodeBuffer();
      code.Inst(PERWAPI.Op.ldarg_0);
      code.Inst(PERWAPI.Op.ldarg_1);
      PERWAPI.Method baseCtor = emitter.findMethod(baseClassName, ".ctor",
        new string[] { "Fan.Sys.Err/Val" }, "System.Void");
      baseCtor.AddCallConv(PERWAPI.CallConv.Instance); // if stub, make sure instance callconv
      code.MethInst(PERWAPI.MethodOp.call, baseCtor);
      if (m == null)
      {
        //code.maxLocals = 2;
        //code.maxStack  = 2;
        code.Inst(PERWAPI.Op.ret);
      }
      else
      {
        // e.code.maxLocals++;  // alloc room for Val extra argument
        new FCodeEmit(this, m, code).emit();
      }
    }

  }
}
