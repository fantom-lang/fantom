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
  /// FErrValEmit the special Err$Val inner class for an Err subclass.
  /// </summary>
  public class FErrValEmit : FClassEmit
  {

  //////////////////////////////////////////////////////////////////////////
  // Constructor
  //////////////////////////////////////////////////////////////////////////

    public FErrValEmit(Emitter emitter, Type parent, FType type)
      : base(emitter, parent, type)
    {
    }

  //////////////////////////////////////////////////////////////////////////
  // Overrides
  //////////////////////////////////////////////////////////////////////////

    public override void emit()
    {
      this.baseClassName = nname(type.m_base) + "/Val";
      this.className = nname(type.m_self) + "/Val";
      this.selfName  = className;

      emitter.emitClass(baseClassName, className, new string[0],
        PERWAPI.TypeAttr.NestedPublic | PERWAPI.TypeAttr.BeforeFieldInit);
      emitCtor();
    }

    private void emitCtor()
    {
      // no arg constructor
      ctor = emitter.findMethod(selfName, ".ctor", new string[0], "System.Void") as PERWAPI.MethodDef;
      ctor.SetMethAttributes(
        PERWAPI.MethAttr.Public |
        PERWAPI.MethAttr.HideBySig |
        PERWAPI.MethAttr.SpecialRTSpecialName);
      ctor.AddCallConv(PERWAPI.CallConv.Instance);

      PERWAPI.CILInstructions code = ctor.CreateCodeBuffer();
      code.Inst(PERWAPI.Op.ldarg_0);
      PERWAPI.Method baseCtor = emitter.findMethod(baseClassName, ".ctor", new string[0], "System.Void");
      baseCtor.AddCallConv(PERWAPI.CallConv.Instance); // if stub, make sure instance callconv
      code.MethInst(PERWAPI.MethodOp.call, baseCtor);
      code.Inst(PERWAPI.Op.ret);
    }

  }
}
