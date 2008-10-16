//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Oct 06  Andy Frank  Creation
//

using System;
using System.Collections;
using System.Text;
using PERWAPI;
using Fanx.Fcode;
using Fanx.Util;

namespace Fanx.Emit
{
  /// <summary>
  /// FCodeEmit translates FCode fcode to IL bytecode.
  /// </summary>
  public class FCodeEmit
  {

  //////////////////////////////////////////////////////////////////////////
  // Constructor
  //////////////////////////////////////////////////////////////////////////

    public FCodeEmit(FTypeEmit parent, FMethod fmethod, CILInstructions code)
     : this(parent, fmethod.m_code, code)
    {
      this.fmethod = fmethod;
      //code.maxLocals  = Math.max(fmethod.maxLocals(), 4); // TODO - total hack
      this.paramCount = fmethod.m_paramCount;
      if ((fmethod.m_flags & FConst.Static) == 0) paramCount++;
    }

    public FCodeEmit(FTypeEmit parent, FBuf fcode, CILInstructions code)
    {
      this.pod        = parent.pod;
      this.emitter    = parent.emitter;
      this.parent     = parent;
      this.buf        = fcode.m_buf;
      this.len        = fcode.m_len;
      //this.emit       = code.emit;
      this.code       = code;
      this.podClass   = NameUtil.toNetTypeName(pod.m_podName, "$Pod");
      this.jumps      = new Jumps(code);
    }

  //////////////////////////////////////////////////////////////////////////
  // Overrides
  //////////////////////////////////////////////////////////////////////////

    /// <summary>
    /// Translate fcode to IL.
    /// </summary>

// TODO - this is all fucked up - need to back and fix
// so that this is not an atomic operation - need to be
// able to tack on additional IL after its 'closed' -
// correct scoping falls out of that fix as well I think.

    public void emit() { emit(true); }
    public void emit(bool debug)
    {
      if (debug) code.OpenScope();
      makeLineNumbers();
      makeErrTable();
      emitInstructions();
      if (debug) code.CloseScope();
    }

    /// <summary>
    /// Map fcode instructions to IL instructions.
    /// </summary>
    private void emitInstructions()
    {
      while (pos < len)
      {
        startPos = pos;
        int opcode = consumeOp();
        switch (opcode)
        {
          case FConst.Nop:                 break;
          case FConst.LoadNull:            code.Inst(Op.ldnull); break;
          case FConst.LoadFalse:           loadFalse(); break;
          case FConst.LoadTrue:            loadTrue(); break;
          case FConst.LoadInt:             loadInt(); break;
          case FConst.LoadFloat:           loadFloat(); break;
          case FConst.LoadDecimal:         loadDecimal(); break;
          case FConst.LoadStr:             loadStr(); break;
          case FConst.LoadDuration:        loadDuration(); break;
          case FConst.LoadUri:             loadUri(); break;
          case FConst.LoadType:            loadType(); break;

          case FConst.LoadVar:             loadVar(); break;
          case FConst.StoreVar:            storeVar(); break;
          case FConst.LoadInstance:        loadInstance(); break;
          case FConst.StoreInstance:       storeInstance(); break;
          case FConst.LoadStatic:          loadStatic(); break;
          case FConst.StoreStatic:         storeStatic(); break;
          case FConst.LoadMixinStatic:     loadMixinStatic(); break;
          case FConst.StoreMixinStatic:    storeMixinStatic(); break;

          case FConst.CallNew:             callNew(); break;
          case FConst.CallCtor:            callCtor(); break;
          case FConst.CallStatic:          callStatic(); break;
          case FConst.CallVirtual:         callVirtual(); break;
          case FConst.CallNonVirtual:      callNonVirtual(); break;
          case FConst.CallMixinStatic:     callMixinStatic(); break;
          case FConst.CallMixinVirtual:    callMixinVirtual(); break;
          case FConst.CallMixinNonVirtual: callMixinNonVirtual(); break;

          case FConst.Jump:                jump(); break;
          case FConst.JumpTrue:            jumpTrue(); break;
          case FConst.JumpFalse:           jumpFalse(); break;

          case FConst.CompareEQ:           compareEQ(); break;
          case FConst.CompareNE:           compareNE(); break;
          case FConst.Compare:             compare(); break;
          case FConst.CompareLT:           compareLT(); break;
          case FConst.CompareLE:           compareLE(); break;
          case FConst.CompareGE:           compareGE(); break;
          case FConst.CompareGT:           compareGT(); break;
          case FConst.CompareSame:         compareSame(); break;
          case FConst.CompareNotSame:      compareNotSame(); break;
          case FConst.CompareNull:         compareNull(); break;
          case FConst.CompareNotNull:      compareNotNull(); break;

          case FConst.ReturnVoid:          code.Inst(Op.ret); break;
          case FConst.ReturnObj:           code.Inst(Op.ret); break;
          case FConst.Pop:                 code.Inst(Op.pop); break;
          case FConst.Dup:                 code.Inst(Op.dup); break;
          //case FConst.DupDown:             code.op(DUP_X1); break; // WON'T SUPPORT
          case FConst.Is:                  @is(); break;
          case FConst.As:                  @as(); break;
          case FConst.Cast:                cast(); break;
          case FConst.Switch:              tableswitch(); break;

          case FConst.Throw:               doThrow(); break;
          case FConst.Leave:               doLeave(); break;
          case FConst.JumpFinally:         u2(); break; // not used in .NET, so just eat the branch loc
          case FConst.CatchAllStart:       catchAllStart(); break;
          case FConst.CatchErrStart:       catchErrStart(); break;
          case FConst.CatchEnd:            catchEnd(); break;
          case FConst.FinallyStart:        finallyStart(); break;
          case FConst.FinallyEnd:          finallyEnd(); break;

          default: throw new Exception(opcode < FConst.OpNames.Length ? FConst.OpNames[opcode] : "bad opcode=" + opcode);

        }
      }
    }

    /// <summary>
    /// Read out the line numbers and stick them in a hashmap.
    /// </summary>
    private void makeLineNumbers()
    {
      // source file
      string srcFile = parent.type.m_attrs.m_sourceFile;
      if (srcFile != null)
      {
        code.DefaultSourceFile = SourceFile.GetSourceFile(
          srcFile,             // source file
          System.Guid.Empty,   // lang
          System.Guid.Empty,   // vend
          System.Guid.Empty);  // docu
      }

      // line numbers
      if (fmethod == null) return;
      FBuf flines = fmethod.m_attrs.m_lineNums;
      if (flines != null)
      {
        int len = flines.m_len;
        byte[] buf = flines.m_buf;
        for (int i=2; i<len; i+=4)
        {
          int pc   = (buf[i]   & 0xFF) << 8 | (buf[i+1] & 0xFF);
          int line = (buf[i+2] & 0xFF) << 8 | (buf[i+3] & 0xFF);
          lineNums[pc] = line;
        }
      }
    }

    /// <summary>
    /// Process error table (if specified).  We handle catches of Err using
    /// a catch any (0 class index).  We also need to add extra entries into
    /// the exception table for special exceptions - for example NullErr get's
    /// mapped as fan.sys.NullErr+Val and java.lang.NullPointerException.
    /// </summary>
    private void makeErrTable()
    {
      if (fmethod == null) return;
      FBuf ferrs = fmethod.m_attrs.m_errTable;
      if (ferrs == null) return;

      int len = ferrs.m_len;
      byte[] buf = ferrs.m_buf;
      int count = (len-2)/8;

      tryStart = new int[count];
      tryEnd   = new int[count];
      tryJump  = new int[count];
      tryErr   = new int[count];

      for (int i=2, j=0; i<len; i+=8)
      {
        tryStart[j] = (buf[i+0] & 0xFF) << 8 | (buf[i+1] & 0xFF);
        tryEnd[j]   = (buf[i+2] & 0xFF) << 8 | (buf[i+3] & 0xFF);
        tryJump[j]  = (buf[i+4] & 0xFF) << 8 | (buf[i+5] & 0xFF);
        tryErr[j]   = (buf[i+6] & 0xFF) << 8 | (buf[i+7] & 0xFF);
        j++;
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // Load/Store
  //////////////////////////////////////////////////////////////////////////

    private void loadFalse()
    {
      if (parent.BoolFalse == null)
        parent.BoolFalse = emitter.findField("Fan.Sys.Bool", "False", "Fan.Sys.Bool");
      code.FieldInst(FieldOp.ldsfld, parent.BoolFalse);
    }

    private void loadTrue()
    {
      // TODO: optimize while (true) either here or in compiler
      if (parent.BoolTrue == null)
        parent.BoolTrue = emitter.findField("Fan.Sys.Bool", "True", "Fan.Sys.Bool");
      code.FieldInst(FieldOp.ldsfld, parent.BoolTrue);
    }

    private void loadInt()
    {
      int index = u2();
      PERWAPI.Field field = emitter.findField(podClass, "I" + index, "Fan.Sys.Int");
      code.FieldInst(FieldOp.ldsfld, field);
    }

    private void loadFloat()
    {
      int index = u2();
      PERWAPI.Field field = emitter.findField(podClass, "F" + index, "Fan.Sys.Double");
      code.FieldInst(FieldOp.ldsfld, field);
    }

    private void loadDecimal()
    {
      int index = u2();
      PERWAPI.Field field = emitter.findField(podClass, "D" + index, "Fan.Sys.Decimal");
      code.FieldInst(FieldOp.ldsfld, field);
    }

    private void loadStr()
    {
      int index = u2();
      PERWAPI.Field field = emitter.findField(podClass, "S" + index, "Fan.Sys.Str");
      code.FieldInst(FieldOp.ldsfld, field);
    }

    private void loadDuration()
    {
      int index = u2();
      PERWAPI.Field field = emitter.findField(podClass, "Dur" + index, "Fan.Sys.Duration");
      code.FieldInst(FieldOp.ldsfld, field);
    }

    private void loadUri()
    {
      int index = u2();
      PERWAPI.Field field = emitter.findField(podClass, "U" + index, "Fan.Sys.Uri");
      code.FieldInst(FieldOp.ldsfld, field);
    }

    private void loadType()
    {
      loadType(u2());
    }

    private void loadType(int typeRefIndex)
    {
      FTypeRef tref = pod.typeRef(typeRefIndex);
      string podName  = pod.name(tref.podName);
      string typeName = pod.name(tref.typeName);

      // if pod is "sys", then we can perform a shortcut and use
      // one of the predefined fields in Sys
      if (!tref.isGenericInstance() && podName == "sys")
      {
        PERWAPI.Field field = emitter.findField("Fan.Sys.Sys", typeName + "Type", "Fan.Sys.Type");
        code.FieldInst(FieldOp.ldsfld, field);
        return;
      }

      // lazy allocate my parent's type literal map: sig -> fieldName
      if (parent.typeLiteralFields == null) parent.typeLiteralFields = new Hashtable();
      Hashtable map = parent.typeLiteralFields;

      // types are lazy loaded and then cached in a private static field called
      // type$count which will get generated by FTypeEmit (we keep track of signature
      // to fieldname in the typeConstFields map)
      string sig = tref.Sig(pod);
      string fieldName = (string)map[sig];
      if (fieldName == null)
      {
        fieldName = "type$" + map.Count;
        map[sig] = fieldName;
      }
      //int fieldRef = emit.field(parent.className + "." + fieldName + ":Lfan/sys/Type;");

      //code.op2(GETSTATIC, fieldRef);
      //code.op(DUP);
      //int nonNull = code.branch(IFNONNULL);
      //code.op(POP);
      //code.op2(LDC_W, emit.strConst(sig));
      //code.op(ICONST_1);
      //code.op2(INVOKESTATIC, parent.sysFindType());
      //code.op(DUP);
      //code.op2(PUTSTATIC, fieldRef);
      //code.mark(nonNull);

      //emitter.EmitField(string name, string type, FieldAttr attr)
      //PERWAPI.Field field = emitter.EmitField("Fan.Sys.Sys", typeName + "Type", "Fan.Sys.Type");
      //code.FieldInst(FieldOp.ldsfld, field);

      // TODO - store in static field (all that crap above this)
      code.ldstr(sig);
      Method method = emitter.findMethod("Fan.Sys.Type", "find",
        new string[] { "System.String" }, "Fan.Sys.Type");
      code.MethInst(MethodOp.call, method);
    }

    private void loadVar()
    {
      int index = u2();
      if (index < paramCount)
      {
        switch (index)
        {
          case 0:  code.Inst(Op.ldarg_0); break;
          case 1:  code.Inst(Op.ldarg_1); break;
          case 2:  code.Inst(Op.ldarg_2); break;
          case 3:  code.Inst(Op.ldarg_3); break;
          default: code.IntInst(IntOp.ldarg, index); break;
        }
      }
      else
      {
        index -= paramCount;
        switch (index)
        {
          case 0:  code.Inst(Op.ldloc_0); break;
          case 1:  code.Inst(Op.ldloc_1); break;
          case 2:  code.Inst(Op.ldloc_2); break;
          case 3:  code.Inst(Op.ldloc_3); break;
          default: code.IntInst(IntOp.ldloc, index); break;
        }
      }
    }

    private void storeVar()
    {
      int index = u2();
      if (index < paramCount)
      {
        code.IntInst(IntOp.starg, index);
      }
      else
      {
        index -= paramCount;
        switch (index)
        {
          case 0:  code.Inst(Op.stloc_0); break;
          case 1:  code.Inst(Op.stloc_1); break;
          case 2:  code.Inst(Op.stloc_2); break;
          case 3:  code.Inst(Op.stloc_3); break;
          default: code.IntInst(IntOp.stloc, index); break;
        }
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // Field
  //////////////////////////////////////////////////////////////////////////

    private void loadInstance()
    {
      FPod.NField f = pod.nfield(u2(), false);
      PERWAPI.Field field = emitter.findField(f.parentType, f.fieldName, f.fieldType);
      code.FieldInst(FieldOp.ldfld, field);
    }

    private void storeInstance()
    {
      FPod.NField f = pod.nfield(u2(), false);
      PERWAPI.Field field = emitter.findField(f.parentType, f.fieldName, f.fieldType);
      code.FieldInst(FieldOp.stfld, field);
    }

    private void loadStatic()
    {
      FPod.NField f = pod.nfield(u2(), false);
      PERWAPI.Field field = emitter.findField(f.parentType, f.fieldName, f.fieldType);
      code.FieldInst(FieldOp.ldsfld, field);
    }

    private void storeStatic()
    {
      FPod.NField f = pod.nfield(u2(), false);
      PERWAPI.Field field = emitter.findField(f.parentType, f.fieldName, f.fieldType);
      code.FieldInst(FieldOp.stsfld, field);
    }

    private void loadMixinStatic()
    {
      FPod.NField f = pod.nfield(u2(), false);
      PERWAPI.Field field = emitter.findField(f.parentType, f.fieldName, f.fieldType);
      code.FieldInst(FieldOp.ldsfld, field);
    }

    private void storeMixinStatic()
    {
      FPod.NField f = pod.nfield(u2(), false);
      PERWAPI.Field field = emitter.findField(f.parentType, f.fieldName, f.fieldType);
      code.FieldInst(FieldOp.stsfld, field);
    }

  //////////////////////////////////////////////////////////////////////////
  // Calls
  //////////////////////////////////////////////////////////////////////////

    private void callNew()
    {
      // constructors are implemented as static factory methods
      FPod.NMethod ncall = pod.ncall(u2(), FConst.CallNew);
      Method method = emitter.findMethod(ncall.parentType, ncall.methodName,
        ncall.paramTypes, ncall.returnType);
      code.MethInst(MethodOp.call, method);
    }

    private void callCtor()
    {
      // constructor implementations (without object allow) are
      // implemented as static factory methods with "_" appended

      int index = u2();
      int[] m = pod.methodRef(index).val;
      string parent = pod.nname(m[0]);
      string name = pod.name(m[1]) + "_";

      string[] pars = new string[m.Length-3+1];
      pars[0] = parent;
      for (int i=0; i<pars.Length-1; i++)
        pars[i+1] = pod.nname(m[i+3]);

      Method method = emitter.findMethod(parent, name, pars, "System.Void");
      code.MethInst(MethodOp.call, method);
    }

    private void callStatic()
    {
      FPod.NMethod ncall = pod.ncall(u2(), FConst.CallStatic);
      Method method = emitter.findMethod(ncall.parentType, ncall.methodName,
        ncall.paramTypes, ncall.returnType);
      code.MethInst(MethodOp.call, method);
    }

    private void callVirtual()
    {
      int index = u2();
      FPod.NMethod ncall = pod.ncall(index, FConst.CallVirtual);
      Method method = emitter.findMethod(ncall.parentType, ncall.methodName,
        ncall.paramTypes, ncall.returnType);
      if (ncall.isStatic)
      {
        code.MethInst(MethodOp.call, method);
      }
      else
      {
        method.AddCallConv(CallConv.Instance);
        code.MethInst(MethodOp.callvirt, method);
      }
    }

    private void callNonVirtual()
    {
      FPod.NMethod ncall = pod.ncall(u2(), FConst.CallNonVirtual);
      Method method = emitter.findMethod(ncall.parentType, ncall.methodName,
        ncall.paramTypes, ncall.returnType);
      method.AddCallConv(CallConv.Instance);
      code.MethInst(MethodOp.call, method);
    }

    private void callMixinStatic()
    {
      FPod.NMethod ncall = pod.ncall(u2(), FConst.CallMixinStatic);
      Method method = emitter.findMethod(ncall.parentType, ncall.methodName,
        ncall.paramTypes, ncall.returnType);
      code.MethInst(MethodOp.call, method);

    }

    private void callMixinVirtual()
    {
      FPod.NMethod ncall = pod.ncall(u2(), FConst.CallMixinVirtual);
      Method method = emitter.findMethod(ncall.parentType, ncall.methodName,
        ncall.paramTypes, ncall.returnType);
      method.AddCallConv(CallConv.Instance);
      code.MethInst(MethodOp.callvirt, method);
    }

    private void callMixinNonVirtual()
    {
      FPod.NMethod ncall = pod.ncall(u2(), FConst.CallMixinNonVirtual);
      string parent = ncall.parentType;
      string name = ncall.methodName;
      string ret = ncall.returnType;
      string[] pars = new string[ncall.paramTypes.Length+1];
      pars[0] = parent;
      for (int i=1; i<pars.Length; i++)
        pars[i] = ncall.paramTypes[i-1];
      Method method = emitter.findMethod(parent+"_", name, pars, ret);
      code.MethInst(MethodOp.call, method);
    }

  //////////////////////////////////////////////////////////////////////////
  // Jump
  //////////////////////////////////////////////////////////////////////////

    private void jumpTrue()
    {
      loadBoolVal();
      code.Branch(BranchOp.brtrue, jumps.add(u2()));
    }

    private void jumpFalse()
    {
      loadBoolVal();
      code.Branch(BranchOp.brfalse, jumps.add(u2()));
    }

    private void jump()
    {
      code.Branch(BranchOp.br, jumps.add(u2()));
    }

  //////////////////////////////////////////////////////////////////////////
  // Compare
  //////////////////////////////////////////////////////////////////////////

    private void compareEQ()
    {
      int peek = peekOp();
      switch (peek)
      {
        case FConst.JumpFalse:
          if (parent.CompareEQz == null)
            parent.CompareEQz = emitter.findMethod("Fanx.Util.OpUtil", "compareEQz",
              new string[] { "System.Object", "System.Object" }, "System.Boolean");
          code.MethInst(MethodOp.call, parent.CompareEQz);
          consumeOp();
          code.Branch(BranchOp.brfalse, jumps.add(u2()));
          break;
        case FConst.JumpTrue:
          if (parent.CompareEQz == null)
            parent.CompareEQz = emitter.findMethod("Fanx.Util.OpUtil", "compareEQz",
              new string[] { "System.Object", "System.Object" }, "System.Boolean");
          code.MethInst(MethodOp.call, parent.CompareEQz);
          consumeOp();
          code.Branch(BranchOp.brtrue, jumps.add(u2()));
          break;
        default:
          if (parent.CompareEQ == null)
            parent.CompareEQ = emitter.findMethod("Fanx.Util.OpUtil", "compareEQ",
              new string[] { "System.Object", "System.Object" }, "Fan.Sys.Bool");
          code.MethInst(MethodOp.call, parent.CompareEQ);
          break;
      }
    }

    private void compareNE()
    {
      int peek = peekOp();
      switch (peek)
      {
        case FConst.JumpFalse:
          if (parent.CompareNEz == null)
            parent.CompareNEz = emitter.findMethod("Fanx.Util.OpUtil", "compareNEz",
              new string[] { "System.Object", "System.Object" }, "System.Boolean");
          code.MethInst(MethodOp.call, parent.CompareNEz);
          consumeOp();
          code.Branch(BranchOp.brfalse, jumps.add(u2()));
          break;
        case FConst.JumpTrue:
          if (parent.CompareNEz == null)
            parent.CompareNEz = emitter.findMethod("Fanx.Util.OpUtil", "compareNEz",
              new string[] { "System.Object", "System.Object" }, "System.Boolean");
          code.MethInst(MethodOp.call, parent.CompareNEz);
          consumeOp();
          code.Branch(BranchOp.brtrue, jumps.add(u2()));
          break;
        default:
          if (parent.CompareNE == null)
            parent.CompareNE = emitter.findMethod("Fanx.Util.OpUtil", "compareNE",
              new string[] { "System.Object", "System.Object" }, "Fan.Sys.Bool");
          code.MethInst(MethodOp.call, parent.CompareNE);
          break;
      }
    }

    private void compare()
    {
      if (parent.Compare == null)
        parent.Compare = emitter.findMethod("Fanx.Util.OpUtil", "compare",
          new string[] { "System.Object", "System.Object" }, "Fan.Sys.Int");
      code.MethInst(MethodOp.call, parent.Compare);
    }

    private void compareLT()
    {
      int peek = peekOp();
      switch (peek)
      {
       case FConst.JumpFalse:
          if (parent.CompareLTz == null)
            parent.CompareLTz = emitter.findMethod("Fanx.Util.OpUtil", "compareLTz",
              new string[] { "System.Object", "System.Object" }, "System.Boolean");
          code.MethInst(MethodOp.call, parent.CompareLTz);
          consumeOp();
          code.Branch(BranchOp.brfalse, jumps.add(u2()));
          break;
        case FConst.JumpTrue:
          if (parent.CompareLTz == null)
            parent.CompareLTz = emitter.findMethod("Fanx.Util.OpUtil", "compareLTz",
              new string[] { "System.Object", "System.Object" }, "System.Boolean");
          code.MethInst(MethodOp.call, parent.CompareLTz);
          consumeOp();
          code.Branch(BranchOp.brtrue, jumps.add(u2()));
          break;
       default:
          if (parent.CompareLT == null)
            parent.CompareLT = emitter.findMethod("Fanx.Util.OpUtil", "compareLT",
              new string[] { "System.Object", "System.Object" }, "Fan.Sys.Bool");
          code.MethInst(MethodOp.call, parent.CompareLT);
          break;
      }
    }

    private void compareLE()
    {
      int peek = peekOp();
      switch (peek)
      {
        case FConst.JumpFalse:
          if (parent.CompareLEz == null)
            parent.CompareLEz = emitter.findMethod("Fanx.Util.OpUtil", "compareLEz",
              new string[] { "System.Object", "System.Object" }, "System.Boolean");
          code.MethInst(MethodOp.call, parent.CompareLEz);
          consumeOp();
          code.Branch(BranchOp.brfalse, jumps.add(u2()));
          break;
        case FConst.JumpTrue:
          if (parent.CompareLEz == null)
            parent.CompareLEz = emitter.findMethod("Fanx.Util.OpUtil", "compareLEz",
              new string[] { "System.Object", "System.Object" }, "System.Boolean");
          code.MethInst(MethodOp.call, parent.CompareLEz);
          consumeOp();
          code.Branch(BranchOp.brtrue, jumps.add(u2()));
          break;
        default:
          if (parent.CompareLE == null)
            parent.CompareLE = emitter.findMethod("Fanx.Util.OpUtil", "compareLE",
              new string[] { "System.Object", "System.Object" }, "Fan.Sys.Bool");
          code.MethInst(MethodOp.call, parent.CompareLE);
          break;
      }
    }

    private void compareGE()
    {
      int peek = peekOp();
      switch (peek)
      {
        case FConst.JumpFalse:
          if (parent.CompareGEz == null)
            parent.CompareGEz = emitter.findMethod("Fanx.Util.OpUtil", "compareGEz",
              new string[] { "System.Object", "System.Object" }, "System.Boolean");
          code.MethInst(MethodOp.call, parent.CompareGEz);
          consumeOp();
          code.Branch(BranchOp.brfalse, jumps.add(u2()));
          break;
        case FConst.JumpTrue:
          if (parent.CompareGEz == null)
            parent.CompareGEz = emitter.findMethod("Fanx.Util.OpUtil", "compareGEz",
              new string[] { "System.Object", "System.Object" }, "System.Boolean");
          code.MethInst(MethodOp.call, parent.CompareGEz);
          consumeOp();
          code.Branch(BranchOp.brtrue, jumps.add(u2()));
          break;
        default:
          if (parent.CompareGE == null)
            parent.CompareGE = emitter.findMethod("Fanx.Util.OpUtil", "compareGE",
              new string[] { "System.Object", "System.Object" }, "Fan.Sys.Bool");
          code.MethInst(MethodOp.call, parent.CompareGE);
          break;
      }
    }

    private void compareGT()
    {
      int peek = peekOp();
      switch (peek)
      {
        case FConst.JumpFalse:
          if (parent.CompareGTz == null)
            parent.CompareGTz = emitter.findMethod("Fanx.Util.OpUtil", "compareGTz",
              new string[] { "System.Object", "System.Object" }, "System.Boolean");
          code.MethInst(MethodOp.call, parent.CompareGTz);
          consumeOp();
          code.Branch(BranchOp.brfalse, jumps.add(u2()));
          break;
        case FConst.JumpTrue:
          if (parent.CompareGTz == null)
            parent.CompareGTz = emitter.findMethod("Fanx.Util.OpUtil", "compareGTz",
              new string[] { "System.Object", "System.Object" }, "System.Boolean");
          code.MethInst(MethodOp.call, parent.CompareGTz);
          consumeOp();
          code.Branch(BranchOp.brtrue, jumps.add(u2()));
          break;
        default:
          if (parent.CompareGT == null)
            parent.CompareGT = emitter.findMethod("Fanx.Util.OpUtil", "compareGT",
              new string[] { "System.Object", "System.Object" }, "Fan.Sys.Bool");
          code.MethInst(MethodOp.call, parent.CompareGT);
          break;
      }
    }

    private void compareSame()
    {
      int peek = peekOp();
      switch (peek)
      {
        case FConst.JumpFalse:
          consumeOp();
          code.Branch(BranchOp.bne_un, jumps.add(u2()));
          break;
        case FConst.JumpTrue:
          consumeOp();
          code.Branch(BranchOp.beq, jumps.add(u2()));
          break;
        default:
          if (parent.CompareSame == null)
            parent.CompareSame = emitter.findMethod("Fanx.Util.OpUtil", "compareSame",
              new string[] { "System.Object", "System.Object" }, "Fan.Sys.Bool");
          code.MethInst(MethodOp.call, parent.CompareSame);
          break;
      }
    }

    private void compareNotSame()
    {
      int peek = peekOp();
      switch (peek)
      {
        case FConst.JumpFalse:
          consumeOp();
          code.Branch(BranchOp.beq, jumps.add(u2()));
          break;
        case FConst.JumpTrue:
          consumeOp();
          code.Branch(BranchOp.bne_un, jumps.add(u2()));
          break;
        default:
          if (parent.CompareNotSame == null)
            parent.CompareNotSame = emitter.findMethod("Fanx.Util.OpUtil", "compareNotSame",
              new string[] { "System.Object", "System.Object" }, "Fan.Sys.Bool");
          code.MethInst(MethodOp.call, parent.CompareNotSame);
          break;
      }
    }

    private void compareNull()
    {
      int peek = peekOp();
      switch (peek)
      {
        case FConst.JumpFalse:
          consumeOp();
          code.Branch(BranchOp.brtrue, jumps.add(u2()));
          break;
        case FConst.JumpTrue:
          consumeOp();
          code.Branch(BranchOp.brfalse, jumps.add(u2()));
          break;
        default:
          if (parent.CompareNull == null)
            parent.CompareNull = emitter.findMethod("Fanx.Util.OpUtil", "compareNull",
              new string[] { "System.Object" }, "Fan.Sys.Bool");
          code.MethInst(MethodOp.call, parent.CompareNull);
          break;
      }
    }

    private void compareNotNull()
    {
      int peek = peekOp();
      switch (peek)
      {
        case FConst.JumpFalse:
          consumeOp();
          code.Branch(BranchOp.brfalse, jumps.add(u2()));
          break;
        case FConst.JumpTrue:
          consumeOp();
          code.Branch(BranchOp.brtrue, jumps.add(u2()));
          break;
        default:
          if (parent.CompareNotNull == null)
            parent.CompareNotNull = emitter.findMethod("Fanx.Util.OpUtil", "compareNotNull",
              new string[] { "System.Object" }, "Fan.Sys.Bool");
          code.MethInst(MethodOp.call, parent.CompareNotNull);
         break;
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // Is/As
  //////////////////////////////////////////////////////////////////////////

    private void @is()
    {
      int typeRef = u2();
      PERWAPI.Type type = emitter.findType(pod.nname(typeRef));

      // if a generic instance, we have to use a method call
      // because Fan types don't map to Java classes exactly;
      // otherwise we can use straight bytecode
      if (pod.typeRef(typeRef).isGenericInstance())
      {
        if (parent.IsViaType == null)
          parent.IsViaType = emitter.findMethod("Fanx.Util.OpUtil", "is",
              new string[] { "System.Object", "Fan.Sys.Type" }, "Fan.Sys.Bool");
        loadType(typeRef);
        code.MethInst(MethodOp.call, parent.IsViaType);
      }
      else
      {
        code.TypeInst(TypeOp.isinst, type);
        code.Inst(Op.ldnull);
        code.Inst(Op.cgt_un);
        boolMake();
      }
    }

    private void @as()
    {
      int typeRef = u2();
      PERWAPI.Type type = emitter.findType(pod.nname(typeRef));

      // if a generic instance, we have to use a method call
      // because Fan types don't map to Java classes exactly;
      // otherwise we can use straight bytecode
      if (pod.typeRef(typeRef).isGenericInstance())
      {
        if (parent.AsViaType == null)
          parent.AsViaType = emitter.findMethod("Fanx.Util.OpUtil", "as",
              new string[] { "System.Object", "Fan.Sys.Type" }, "System.Object");
        loadType(typeRef);
        code.MethInst(MethodOp.call, parent.AsViaType);
        code.TypeInst(TypeOp.isinst, type);
      }
      else
      {
        //code.op(DUP);
        //code.op2(INSTANCEOF, cls);
        //int is = code.branch(IFNE);
        //code.op(POP);
        //code.op(ACONST_NULL);
        //int end = code.branch(GOTO);
        //code.mark(is);
        //code.op2(CHECKCAST, cls);
        //code.mark(end);
        code.TypeInst(TypeOp.isinst, type);
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // Switch
  //////////////////////////////////////////////////////////////////////////

    private void tableswitch()
    {
      loadIntVal();
      int count = u2();
      CILLabel[] labels = new CILLabel[count];
      for (int i=0; i<count; ++i)
        labels[i] = jumps.add(u2());
      code.Switch(labels);
    }

  //////////////////////////////////////////////////////////////////////////
  // Misc
  //////////////////////////////////////////////////////////////////////////

    private void cast()
    {
      code.TypeInst(TypeOp.castclass, emitter.findType(pod.nname(u2())));
    }

    private void doThrow()
    {
      if (parent.ErrVal == null)
        parent.ErrVal = emitter.findField("Fan.Sys.Err", "val", "Fan.Sys.Err/Val");
      code.FieldInst(FieldOp.ldfld, parent.ErrVal);
      code.Inst(Op.throwOp);
    }

    private void doLeave()
    {
      code.Branch(BranchOp.leave, jumps.add(u2()));
    }

    private void catchAllStart()
    {
      exType = "System.Object";
      errBlocks.Push(getLastTryBlock());
      code.StartBlock();
      code.Inst(Op.pop);
    }

    private void catchErrStart()
    {
      exType = "System.Exception";
      for (int i=0; i<tryJump.Length; i++)
        if (startPos == tryJump[i])
        {
          string ftype = pod.nname(tryErr[i]);
          netErr = Fan.Sys.Err.fanToNet(ftype);
          if (ftype != "Fan.Sys.Err") exType = ftype + "/Val";
          break;
        }

      // close try block
      errBlocks.Push(getLastTryBlock());

      // use a filter if we need to "dual-check" for native exception
      if (netErr != null)
      {
        code.CodeLabel(filterStart = code.NewLabel());
        CILLabel match = code.NewLabel();
        CILLabel endfilter = code.NewLabel();

        // check native type first
        code.Inst(Op.dup);
        code.TypeInst(TypeOp.isinst, emitter.findType(netErr));
        code.Inst(Op.ldnull);
        code.Branch(BranchOp.bne_un_s, match);

        // then check Fan type
        code.Inst(Op.dup);
        code.TypeInst(TypeOp.isinst, emitter.findType(exType));
        code.Inst(Op.ldnull);
        code.Branch(BranchOp.bne_un_s, match);

        // no match
        code.Inst(Op.pop); // pop exception off stack
        code.IntInst(IntOp.ldc_i4, 0);
        code.Branch(BranchOp.br_s, endfilter);

        // match
        code.CodeLabel(match);
        code.Inst(Op.pop); // pop exception off stack
        code.IntInst(IntOp.ldc_i4, 1);

        // endfilter
        code.CodeLabel(endfilter);
        code.Inst(Op.endfilter);
      }

      // start handler block
      code.StartBlock();

      // there is already a System.Exception on the stack, but
      // we need to map into a sys::Err type
      if (parent.ErrMake == null)
        parent.ErrMake = emitter.findMethod("Fan.Sys.Err", "make",
          new string[] { "System.Exception" }, "Fan.Sys.Err");
      code.MethInst(MethodOp.call, parent.ErrMake);
      cast();
    }

    private void catchEnd()
    {
      PERWAPI.TryBlock lastTry = (PERWAPI.TryBlock)errBlocks.Pop();
      if (netErr != null)
      {
        // use a filter if we need to "dual-check" for native exception
        code.EndFilterBlock(filterStart, lastTry);
        netErr = null;
        filterStart = null;
      }
      else
      {
        // this is the normal catch block
        code.EndCatchBlock(emitter.findType(exType) as PERWAPI.Class, lastTry);
      }
    }

    private void finallyStart()
    {
      code.EndTryBlock();
      errBlocks.Push(code.EndTryBlock());
      code.StartBlock();
    }

    private void finallyEnd()
    {
      code.Inst(Op.endfinally);
      code.EndFinallyBlock((PERWAPI.TryBlock)errBlocks.Pop());
    }

    private PERWAPI.TryBlock getLastTryBlock()
    {
      for (int i=0; i<tryJump.Length; i++)
        if (startPos == tryJump[i])
        {
          int start  = tryStart[i];
          int end    = tryEnd[i];
          string key = start + "/" + end;

          PERWAPI.TryBlock block = (PERWAPI.TryBlock)tryBlocks[key];
          if (block == null)
          {
            block = code.EndTryBlock();
            tryBlocks[key] = block;
          }
          return block;
        }

      throw new System.Exception("This is not good");
    }

  //////////////////////////////////////////////////////////////////////////
  // Utils
  //////////////////////////////////////////////////////////////////////////

    private void loadBoolVal()
    {
      if (parent.BoolVal == null)
        parent.BoolVal = emitter.findField("Fan.Sys.Bool", "val", "System.Boolean");
      code.FieldInst(FieldOp.ldfld, parent.BoolVal);
    }

    private void loadIntVal()
    {
      if (parent.IntVal == null)
        parent.IntVal = emitter.findField("Fan.Sys.Int", "val", "System.Int64");
      code.FieldInst(FieldOp.ldfld, parent.IntVal);
    }

    private void boolMake()
    {
      if (parent.BoolMake == null)
        parent.BoolMake = emitter.findMethod("Fan.Sys.Bool", "make",
          new string[] { "System.Boolean" }, "Fan.Sys.Bool");
      code.MethInst(MethodOp.call, parent.BoolMake);
    }

  //////////////////////////////////////////////////////////////////////////
  // Buf
  //////////////////////////////////////////////////////////////////////////

    private int consumeOp()
    {
      // check for line numbers
      object line = lineNums[pos];
      if (line != null) code.Line((uint)((int)line), 1);

      // add labels
      code.CodeLabel(jumps.add(pos));

      // check for try blocks
      int peek = peekOp();
      int endPos = -1;
      for (int i=0; i<tryStart.Length; i++)
        //if (pos == tryStart[i])
        if (pos == tryStart[i] && peek != FConst.CatchErrStart && peek != FConst.CatchAllStart)
        {
          int jump = Peek(tryJump[i]);
          if (jump == FConst.CatchErrStart || jump == FConst.CatchAllStart)
          {
            // target is a catch, make sure we don't already
            // have a try block emitted for this region
            if (tryEnd[i] != endPos)
            {
              endPos = tryEnd[i];
              code.StartBlock();
            }
          }
          else
          {
            // target is a finally
            code.StartBlock();
            code.StartBlock();
          }
        }

      // get next opcode
      return u1();
    }

    private int peekOp()
    {
      if (pos < len) return buf[pos];
      return -1;
    }

    private int Peek(int index)
    {
      if (index < len) return buf[index];
      return -1;
    }

    private int u1() { return buf[pos++]; }
    private int u2() { return (buf[pos++] & 0xFF) << 8 | (buf[pos++] & 0xFF); }
    private int u4() { return (buf[pos++] & 0xFF) << 24 | (buf[pos++] & 0xFF) << 16 | (buf[pos++] & 0xFF) << 8 | (buf[pos++] & 0xFF); }

  //////////////////////////////////////////////////////////////////////////
  // Jumps
  //////////////////////////////////////////////////////////////////////////

    internal class Jumps
    {
      public Jumps(CILInstructions code)
      {
        this.code = code;
      }

      public PERWAPI.CILLabel add(int loc)
      {
        if (map[loc] == null)
          map[loc] = code.NewLabel();
        return (PERWAPI.CILLabel)map[loc];
      }

      public PERWAPI.CILLabel get(int loc)
      {
        return (PERWAPI.CILLabel)map[loc];
      }

      Hashtable map = new Hashtable();
      CILInstructions code;
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    internal FPod pod;
    internal Emitter emitter;
    internal FTypeEmit parent;
    internal FMethod fmethod;        // maybe null
    internal int paramCount = -1;
    internal byte[] buf;
    internal int len;
    internal int pos;
    internal int startPos;          // start pos when processing a new opcode
    internal CILInstructions code;
    internal String podClass;
    internal Jumps jumps;                    // map of jump locs to CodeLabels
    internal int[] tryStart = new int[0];    // start offsets of try blocks
    internal int[] tryEnd   = new int[0];    // end offsets of try blocks
    internal int[] tryJump  = new int[0];    // jump offset of try blocks
    internal int[] tryErr   = new int[0];    // err types for catch blocks
    internal string exType;                  // the exception type for the next catch block
    internal Hashtable tryBlocks = new Hashtable(); // hash of opened try blocks
    internal Hashtable lineNums  = new Hashtable(); // map of fcode to line numbers
    internal Stack errBlocks = new Stack();  // stack of try-catch-finally block offsets
    internal string netErr;                  // used for mapping .NET exceptions -> Fan
    internal CILLabel filterStart;           // used for mapping .NET exceptions -> Fan
  }
}