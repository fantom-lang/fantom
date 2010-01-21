//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   4 Oct 06  Andy Frank  Creation
//

using System.Collections;
using Fan.Sys;
using Fanx.Fcode;

namespace Fanx.Emit
{
  /// <summary>
  /// FClassEmit emits a normal class type.
  /// </summary>
  public class FClassEmit : FTypeEmit
  {

  //////////////////////////////////////////////////////////////////////////
  // Constructor
  //////////////////////////////////////////////////////////////////////////

    public FClassEmit(Emitter emitter, Type parent, FType type)
      : base(emitter, parent, type) {}

  //////////////////////////////////////////////////////////////////////////
  // Overrides
  //////////////////////////////////////////////////////////////////////////

    protected override string @base()
    {
      // if the base is a generic instance, then this must be a closure
      // method type (since we can't subclass List or Map).  We subclass
      // from one of the canned Func.Indirect inner classes.
      FTypeRef refer = pod.typeRef(type.m_base);
      if (refer.isGenericInstance())
      {
        this.funcType = (FuncType)Type.find(refer.signature, true);
        int paramCount = funcType.m_params.Length;
        if (paramCount  > Func.MaxIndirectParams)
          return "Fan.Sys.Func/IndirectX";
        else
          return "Fan.Sys.Func/Indirect" + paramCount;
      }
      else
      {
        string baset = nname(type.m_base);
        if (baset == "System.Object") return "Fan.Sys.FanObj";
        if (baset == "Fan.Sys.Type") return "Fan.Sys.ClassType";
        return baset;
      }
    }

    protected override void emitType()
    {
      PERWAPI.TypeAttr classAttr = PERWAPI.TypeAttr.Public;
      if (isAbstract) classAttr |= PERWAPI.TypeAttr.Abstract;

      emitter.emitClass(baseClassName, className, interfaces, classAttr);

      // generate private static Type $Type; set in clinit
      typeField = emitter.classDef.AddField(
        PERWAPI.FieldAttr.Public | PERWAPI.FieldAttr.Static,
        "$type", emitter.findType("Fan.Sys.Type"));

      // generate type() instance method
      PERWAPI.MethodDef m = emitter.classDef.AddMethod(
        PERWAPI.MethAttr.Public | PERWAPI.MethAttr.Virtual, PERWAPI.ImplAttr.IL,
        "typeof", emitter.findType("Fan.Sys.Type"), new PERWAPI.Param[0]);
      m.AddCallConv(PERWAPI.CallConv.Instance);
      emitter.addToMethodMap(className, "typeof", new string[0], m);

      PERWAPI.CILInstructions code = m.CreateCodeBuffer();
      code.FieldInst(PERWAPI.FieldOp.ldsfld, typeField);
      code.Inst(PERWAPI.Op.ret);

      // generate peer field if native
      if (isNative)
      {
        peerField = emitter.classDef.AddField(PERWAPI.FieldAttr.Public,
          "m_peer", emitter.findType(className + "Peer"));
      }

      // Create ctor emit objects first so we can reference them

      // .ctor
      ctor = emitter.findMethod(selfName, ".ctor", new string[0], "System.Void") as PERWAPI.MethodDef;
      ctor.SetMethAttributes(
        PERWAPI.MethAttr.Public |
        PERWAPI.MethAttr.HideBySig |
        PERWAPI.MethAttr.SpecialRTSpecialName);
      ctor.AddCallConv(PERWAPI.CallConv.Instance);

      // .cctor
      cctor = emitter.findMethod(selfName, ".cctor", new string[0], "System.Void") as PERWAPI.MethodDef;
      cctor.SetMethAttributes(
        PERWAPI.MethAttr.Private |
        PERWAPI.MethAttr.Static |
        PERWAPI.MethAttr.HideBySig |
        PERWAPI.MethAttr.SpecialRTSpecialName);
    }

  }
}