//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   2 Jul 07  Andy Frank  Creation
//

using System.IO;
using System.Reflection;
using Fan.Sys;
using Fanx.Fcode;
using Fanx.Util;

namespace Fanx.Emit
{
  /// <summary>
  /// FDynamicEmit emits a subclass of a normal class which stores
  /// it's type per instance rather than in a static field.
  /// </summary>
  public class FDynamicEmit : Emitter
  {

  //////////////////////////////////////////////////////////////////////////
  // Factory
  //////////////////////////////////////////////////////////////////////////

    public static System.Type emitAndLoad(Type baset)
    {
      FDynamicEmit e = new FDynamicEmit(baset);
      Assembly assembly = e.emitAssembly();
      return assembly.GetType(e.className);
    }

  //////////////////////////////////////////////////////////////////////////
  // Constructor
  //////////////////////////////////////////////////////////////////////////

    public FDynamicEmit(Type baset)
    {
      this.m_base = baset;
    }

  //////////////////////////////////////////////////////////////////////////
  // Methods
  //////////////////////////////////////////////////////////////////////////

    public Assembly emitAssembly()
    {
      this.assemblyName = nextAssemblyName();
      this.emitter = new Emitter(assemblyName);
      this.baseClassName = NameUtil.toNetTypeName(m_base.pod().name(), m_base.name());
      this.className = baseClassName + "_Dynamic";

      emitter.emitClass(baseClassName, className, new string[0], PERWAPI.TypeAttr.Public);
      emitType();
      emitCtor();

      byte[] buf = emitter.commit();
      return (buf == null) ? Assembly.LoadFile(emitter.fileName) : Assembly.Load(buf);
    }

    private void emitType()
    {
      // generate public static Type $dtype; set in <init>
      emitter.emitField("_dtype", "Fan.Sys.Type", PERWAPI.FieldAttr.Public);
      dtypeField = emitter.findField(className, "_dtype", "Fan.Sys.Type");

      // generate type() instance method
      PERWAPI.CILInstructions code = emitter.emitMethod(
        "type",
        "Fan.Sys.Type",
        new string[0], //paramNames
        new string[0], //paramTypes
        PERWAPI.MethAttr.Public | PERWAPI.MethAttr.Virtual,
        new string[0],  // localNames
        new string[0]); // localTypes
      code.Inst(PERWAPI.Op.ldarg_0);
      code.FieldInst(PERWAPI.FieldOp.ldfld, dtypeField);
      code.Inst(PERWAPI.Op.ret);
      emitter.methodDef.AddCallConv(PERWAPI.CallConv.Instance);
    }

    private void emitCtor()
    {
      // no arg constructor
      PERWAPI.CILInstructions code = emitter.emitMethod(
        ".ctor",
        "System.Void",
        new string[] { "type" },         //paramNames
        new string[] { "Fan.Sys.Type" }, //paramTypes
        PERWAPI.MethAttr.Public | PERWAPI.MethAttr.HideBySig | PERWAPI.MethAttr.SpecialRTSpecialName,
        new string[0],  // localNames
        new string[0]); // localTypes

      code.Inst(PERWAPI.Op.ldarg_0);
      PERWAPI.Method meth = emitter.findMethod(baseClassName, ".ctor", new string[0], "System.Void");
      meth.AddCallConv(PERWAPI.CallConv.Instance);
      code.MethInst(PERWAPI.MethodOp.call, meth);

      code.Inst(PERWAPI.Op.ldarg_0);
      code.Inst(PERWAPI.Op.ldarg_1);
      code.FieldInst(PERWAPI.FieldOp.stfld, dtypeField);

      code.Inst(PERWAPI.Op.ldarg_0);
      meth = emitter.findMethod(baseClassName, "make_", new string[] { baseClassName }, "System.Void");
      code.MethInst(PERWAPI.MethodOp.call, meth);

      code.Inst(PERWAPI.Op.ret);
      emitter.methodDef.AddCallConv(PERWAPI.CallConv.Instance);
    }

    private static int assemblyCount = 0;
    private static string nextAssemblyName()
    {
      return "dynamic" + assemblyCount++;
    }

    string assemblyName;
    string baseClassName;
    string className;
    Emitter emitter;
    Type m_base;
    PERWAPI.Field dtypeField;

  }
}