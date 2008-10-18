//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Dec 05  Brian Frank  Creation
//
package fanx.emit;

import java.util.*;
import fan.sys.*;
import fanx.fcode.*;
import fanx.util.*;

/**
 * FCodeEmit translates FCode fcode to Java bytecode.
 */
public class FCodeEmit
  implements EmitConst, FConst
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  public FCodeEmit(FTypeEmit parent, FMethod fmethod, CodeEmit code)
  {
    this(parent, fmethod.code, code, parent.pod.typeRef(fmethod.ret));
    this.fmethod    = fmethod;
    this.vars       = fmethod.vars;
    this.isStatic   = (fmethod.flags & FConst.Static) != 0;
    code.maxLocals  = fmethod.maxLocals();
    code.maxStack   = fmethod.maxStack;
  }

  public FCodeEmit(FTypeEmit parent, FBuf fcode, CodeEmit code, FTypeRef ret)
  {
    this.pod        = parent.pod;
    this.parent     = parent;
    this.buf        = fcode.buf;
    this.len        = fcode.len;
    this.emit       = code.emit;
    this.code       = code;
    this.podClass   = "fan/" + pod.podName + "/$Pod";
    this.reloc      = new int[len];
    this.ret        = ret;
  }

//////////////////////////////////////////////////////////////////////////
// Overrides
//////////////////////////////////////////////////////////////////////////

  /**
   * Translate fcode to Java bytecode.
   */
  public void emit()
  {
    emitInstructions();
    backpatch();
    errTable();
    lineTable();
  }

  /**
   * Map fcode instructions to Java bytecode instructions.
   */
  private void emitInstructions()
  {
    while (pos < len)
    {
      int opcode = consumeOp();
      switch (opcode)
      {
        case Nop:                 break;
        case LoadNull:            code.op(ACONST_NULL); break;
        case LoadFalse:           loadFalse(); break;
        case LoadTrue:            loadTrue(); break;
        case LoadInt:             loadInt(); break;
        case LoadFloat:           loadFloat(); break;
        case LoadDecimal:         loadDecimal(); break;
        case LoadStr:             loadStr(); break;
        case LoadDuration:        loadDuration(); break;
        case LoadUri:             loadUri(); break;
        case LoadType:            loadType(); break;

        case LoadVar:             loadVar(); break;
        case StoreVar:            storeVar(); break;
        case LoadInstance:        loadInstance(); break;
        case StoreInstance:       storeInstance(); break;
        case LoadStatic:          loadStatic(); break;
        case StoreStatic:         storeStatic(); break;
        case LoadMixinStatic:     loadMixinStatic(); break;
        case StoreMixinStatic:    storeMixinStatic(); break;

        case CallNew:             callNew(); break;
        case CallCtor:            callCtor(); break;
        case CallStatic:          callStatic(); break;
        case CallVirtual:         callVirtual(); break;
        case CallNonVirtual:      callNonVirtual(); break;
        case CallMixinStatic:     callMixinStatic(); break;
        case CallMixinVirtual:    callMixinVirtual(); break;
        case CallMixinNonVirtual: callMixinNonVirtual(); break;

        case Jump:                jump(); break;
        case JumpTrue:            jumpTrue(); break;
        case JumpFalse:           jumpFalse(); break;

        case CompareEQ:           compareEQ(); break;
        case CompareNE:           compareNE(); break;
        case Compare:             compare(); break;
        case CompareLT:           compareLT(); break;
        case CompareLE:           compareLE(); break;
        case CompareGE:           compareGE(); break;
        case CompareGT:           compareGT(); break;
        case CompareSame:         compareSame(); break;
        case CompareNotSame:      compareNotSame(); break;
        case CompareNull:         compareNull(); break;
        case CompareNotNull:      compareNotNull(); break;

case UnusedReturnObj: // TODO: replaced by single Return
        case Return:              returnOp(); break;
        case Pop:                 pop(); break;
        case Dup:                 dup(); break;
        case Is:                  is(); break;
        case As:                  as(); break;
case Cast: cast(); break;  // TODO: replaced by Coerce
        case Coerce:              coerce(); break;
        case Switch:              tableswitch(); break;

        case Throw:               doThrow(); break;
        case Leave:               jump(); break;  // no diff than Jump in Java
        case JumpFinally:         jumpFinally(); break;
        case CatchAllStart:       code.op(POP); break;
        case CatchErrStart:       catchErrStart(); break;
        case CatchEnd:            break;
        case FinallyStart:        finallyStart(); break;
        case FinallyEnd:          finallyEnd(); break;
        default: throw new IllegalStateException(opcode < OpNames.length ? OpNames[opcode] : "bad opcode=" + opcode);
      }
    }
  }

  /**
   * Back patch fcode to bytecode jumps
   */
  private void backpatch()
  {
    JumpNode j = jumps;
    while (j != null)
    {
      int javaLoc = reloc[j.fcodeLoc];
      int jsrOffset = j.isFinally ? 8 : 0;  // see startFinally()
      if (j.size == 2)
        code.info.u2(j.javaMark+CodeEmit.Header, javaLoc-j.javaFrom+jsrOffset);
      else
        code.info.u4(j.javaMark+CodeEmit.Header, javaLoc-j.javaFrom);
      j = j.next;
    }
  }

  /**
   * Process error table (if specified).  We handle catches of Err using
   * a catch any (0 class index).  We also need to add extra entries into
   * the exception table for special exceptions - for example NullErr get's
   * mapped as fan.sys.NullErr$Val and java.lang.NullPointerException.
   */
  private void errTable()
  {
    if (fmethod == null) return;
    FBuf ferrs = fmethod.attrs.errTable;
    if (ferrs== null) return;

    int len = ferrs.len;
    byte[] buf = ferrs.buf;
    int count = (len-2)/8;
    Box java = new Box(new byte[len], 0);
    java.u2(count);

    for (int i=2; i<len; i += 8)
    {
      int start = reloc[(buf[i+0] & 0xFF) << 8 | (buf[i+1] & 0xFF)];
      int end   = reloc[(buf[i+2] & 0xFF) << 8 | (buf[i+3] & 0xFF)];
      int trap  = reloc[(buf[i+4] & 0xFF) << 8 | (buf[i+5] & 0xFF)];

      java.u2(start);
      java.u2(end);
      java.u2(trap);

      int typeRefId = (buf[i+6] & 0xFF) << 8 | (buf[i+7] & 0xFF);
      FTypeRef typeRef = pod.typeRef(typeRefId);
      if (typeRef.isErr())
      {
        java.u2(0);
      }
      else
      {
        int jtype = emit.cls(typeRef.jname() + "$Val");
        java.u2(jtype);
        String javaEx = Err.fanToJava(typeRef.jname());
        if (javaEx != null)
        {
          java.u2(0, ++count);
          java.u2(start);
          java.u2(end);
          java.u2(trap);
          java.u2(emit.cls(javaEx));
        }
      }
    }

    code.exceptionTable = java;
  }

  /**
   * Pocess line number table (if specified), we just reuse the
   * fcode line table buffer and replace the fcode pc with bytecode
   * pc since they are the same sized data structures.
   */
  private void lineTable()
  {
    if (fmethod == null) return;
    FBuf flines = fmethod.attrs.lineNums;
    if (flines == null) return;

    int len = flines.len;
    byte[] buf = flines.buf;
    for (int i=2; i<len; i += 4)
    {
      reloc(buf, i);
    }

    AttrEmit attr = code.emitAttr("LineNumberTable");
    attr.info.len = len;
    attr.info.buf = buf;
  }

  private void reloc(byte[] buf, int offset)
  {
    int fpos = (buf[offset] & 0xFF) << 8 | (buf[offset+1] & 0xFF);
    int jpos = reloc[fpos];
    buf[offset+0] = (byte)(jpos >>> 8);
    buf[offset+1] = (byte)(jpos >>> 0);
  }

//////////////////////////////////////////////////////////////////////////
// Load/Store
//////////////////////////////////////////////////////////////////////////

  private void loadFalse()
  {
    code.op(ICONST_0);
  }

  private void loadTrue()
  {
    code.op(ICONST_1);
  }

  private void loadInt()
  {
    int index = u2();
    int field = emit.field(podClass + ".I" + index + ":Ljava/lang/Long;");
    code.op2(GETSTATIC, field);
  }

  private void loadFloat()
  {
    int index = u2();
    int field = emit.field(podClass + ".F" + index + ":Ljava/lang/Double;");
    code.op2(GETSTATIC, field);
  }

  private void loadDecimal()
  {
    int index = u2();
    int field = emit.field(podClass + ".D" + index + ":Ljava/math/BigDecimal;");
    code.op2(GETSTATIC, field);
  }

  private void loadStr()
  {
    int index = u2();
    int field = emit.field(podClass + ".S" + index + ":Ljava/lang/String;");
    code.op2(GETSTATIC, field);
  }

  private void loadDuration()
  {
    int index = u2();
    int field = emit.field(podClass + ".Dur" + index + ":Lfan/sys/Duration;");
    code.op2(GETSTATIC, field);
  }

  private void loadUri()
  {
    int index = u2();
    int field = emit.field(podClass + ".U" + index + ":Lfan/sys/Uri;");
    code.op2(GETSTATIC, field);
  }

  private void loadType()
  {
    loadType(pod.typeRef(u2()));
  }

  private void loadType(FTypeRef ref)
  {
    String podName  = ref.podName;
    String typeName = ref.typeName;

    // if pod is "sys", then we can perform a shortcut and use
    // one of the predefined fields in Sys
    if (!ref.isGenericInstance() && podName.equals("sys"))
    {
      code.op2(GETSTATIC, emit.field("fan/sys/Sys." + typeName + "Type:Lfan/sys/Type;"));
      if (ref.isNullable()) typeToNullable();
      return;
    }

    // lazy allocate my parent's type literal map: sig -> fieldName
    if (parent.typeLiteralFields == null) parent.typeLiteralFields= new HashMap();
    HashMap map = parent.typeLiteralFields;

    // types are lazy loaded and then cached in a private static field called
    // type$count which will get generated by FTypeEmit (we keep track of signature
    // to fieldname in the typeConstFields map)
    String sig = ref.signature;
    String fieldName = (String)map.get(sig);
    if (fieldName == null)
    {
      fieldName = "type$" + map.size();
      map.put(sig, fieldName);
    }
    int fieldRef = emit.field(parent.className + "." + fieldName + ":Lfan/sys/Type;");

    code.op2(GETSTATIC, fieldRef);
    code.op(DUP);
    int nonNull = code.branch(IFNONNULL);
    code.op(POP);
    code.op2(LDC_W, emit.strConst(sig));
    code.op(ICONST_1);
    code.op2(INVOKESTATIC, parent.typeFind());
    code.op(DUP);
    code.op2(PUTSTATIC, fieldRef);
    code.mark(nonNull);
  }

//////////////////////////////////////////////////////////////////////////
// Load Var
//////////////////////////////////////////////////////////////////////////

  private void loadVar()
  {
    loadVar(u2());
  }

  private void loadVar(int index)
  {
    loadVar(code, varStackType(index), index);
  }

  static void loadVar(CodeEmit code, int stackType, int index)
  {
    switch (stackType)
    {
      case FTypeRef.INT: loadVarInt(code, index); break;
      case FTypeRef.OBJ: loadVarObj(code, index); break;
      default: throw new IllegalStateException(""+(char)stackType);
    }
  }

  private static void loadVarInt(CodeEmit code, int index)
  {
    switch (index)
    {
      case 0:  code.op(ILOAD_0); break;
      case 1:  code.op(ILOAD_1); break;
      case 2:  code.op(ILOAD_2); break;
      case 3:  code.op(ILOAD_3); break;
      default: code.op1(ILOAD, index); break;
    }
  }

  private static void loadVarObj(CodeEmit code, int index)
  {
    switch (index)
    {
      case 0:  code.op(ALOAD_0); break;
      case 1:  code.op(ALOAD_1); break;
      case 2:  code.op(ALOAD_2); break;
      case 3:  code.op(ALOAD_3); break;
      default: code.op1(ALOAD, index); break;
    }
  }

//////////////////////////////////////////////////////////////////////////
// Store Var
//////////////////////////////////////////////////////////////////////////

  private void storeVar()
  {
    storeVar(u2());
  }

  private void storeVar(int index)
  {
    switch (varStackType(index))
    {
      case FTypeRef.INT: storeVarInt(index); break;
      case FTypeRef.OBJ: storeVarObj(index); break;
      default: throw new IllegalStateException(""+(char)varStackType(index));
    }
  }

  private void storeVarInt(int index)
  {
    switch (index)
    {
      case 0:  code.op(ISTORE_0); break;
      case 1:  code.op(ISTORE_1); break;
      case 2:  code.op(ISTORE_2); break;
      case 3:  code.op(ISTORE_3); break;
      default: code.op1(ISTORE, index); break;
    }
  }

  private void storeVarObj(int index)
  {
    switch (index)
    {
      case 0:  code.op(ASTORE_0); break;
      case 1:  code.op(ASTORE_1); break;
      case 2:  code.op(ASTORE_2); break;
      case 3:  code.op(ASTORE_3); break;
      default: code.op1(ASTORE, index); break;
    }
  }

//////////////////////////////////////////////////////////////////////////
// Field
//////////////////////////////////////////////////////////////////////////

  private void loadInstance()
  {
    int field = emit.field(pod.jfield(u2(), false));
    code.op2(GETFIELD, field);
  }

  private void storeInstance()
  {
    int field = emit.field(pod.jfield(u2(), false));
    code.op2(PUTFIELD, field);
  }

  private void loadStatic()
  {
    int field = emit.field(pod.jfield(u2(), false));
    code.op2(GETSTATIC, field);
  }

  private void storeStatic()
  {
    int field = emit.field(pod.jfield(u2(), false));
    code.op2(PUTSTATIC, field);
  }

  private void loadMixinStatic()
  {
    int field = emit.field(pod.jfield(u2(), true));
    code.op2(GETSTATIC, field);
  }

  private void storeMixinStatic()
  {
    int field = emit.field(pod.jfield(u2(), true));
    code.op2(PUTSTATIC, field);
  }

//////////////////////////////////////////////////////////////////////////
// Calls
//////////////////////////////////////////////////////////////////////////

  private void call(int index, int fanOp, int javaOp)
  {
    FPod.JCall jcall = pod.jcall(index, fanOp);
    int method = emit.method(jcall.sig);
    if (jcall.invokestatic) javaOp = INVOKESTATIC;
    code.op2(javaOp, method);
  }

  private void callNew()
  {
    call(u2(), CallNew, INVOKESTATIC);
  }

  private void callCtor()
  {
    // constructor implementations (without object allow) are
    // implemented as static factory methods with "$" appended
    int index = u2();
    int[] m = pod.methodRef(index).val;
    String parent = pod.typeRef(m[0]).jname();
    String name = pod.name(m[1]);

    StringBuilder s = new StringBuilder();
    s.append(parent).append('.').append(name).append('$').append('(');
    s.append('L').append(parent).append(';');
    for (int i=3; i<m.length; ++i) pod.typeRef(m[i]).jsig(s);
    s.append(')').append('V');

    int method = emit.method(s.toString());
    code.op2(INVOKESTATIC, method);
  }

  private void callStatic()
  {
    call(u2(), CallStatic, INVOKESTATIC);
  }

  private void callVirtual()
  {
    call(u2(), CallVirtual, INVOKEVIRTUAL);
  }

  private void callNonVirtual()
  {
    // invokespecial in Java is really queer - it can only
    // be used for calls in the declaring class (basically
    // for private methods or super call)
    call(u2(), CallNonVirtual, INVOKESPECIAL);
  }

  private void callMixinStatic()
  {
    call(u2(), CallMixinStatic, INVOKESTATIC);
  }

  private void callMixinVirtual()
  {
    int index = u2();
    int[] m = pod.methodRef(index).val;
    int nargs = m.length-3;

    String sig = pod.jcall(index, CallMixinVirtual).sig;
    int method = emit.interfaceRef(sig);
    code.op2(INVOKEINTERFACE, method);
    code.info.u1(nargs+1);
    code.info.u1(0);
  }

  private void callMixinNonVirtual()
  {
    // call the mixin "$" implementation method
    // directly (but don't use cache)
    int index = u2();
    int[] m = pod.methodRef(index).val;
    String parent = pod.typeRef(m[0]).jname();
    String name = pod.name(m[1]);
    FTypeRef ret = pod.typeRef(m[2]);

    StringBuilder s = new StringBuilder();
    s.append(parent).append("$.").append(name).append('(');
    s.append('L').append(parent).append(';');
    for (int i=3; i<m.length; ++i) pod.typeRef(m[i]).jsig(s);
    s.append(')');
    ret.jsig(s);

    int method = emit.method(s.toString());
    code.op2(INVOKESTATIC, method);
  }

//////////////////////////////////////////////////////////////////////////
// Jump
//////////////////////////////////////////////////////////////////////////

  private void jumpTrue()
  {
    code.op(IFNE);
    branch();
  }

  private void jumpFalse()
  {
    code.op(IFEQ);
    branch();
  }

  private void jump()
  {
    code.op(GOTO);
    branch();
  }

  private JumpNode branch()
  {
    // at this point we don't know how fcode locations (abs) will
    // map to Java bytecode locations (rel offsets), so we just
    // keep track of locations to backpatch in a linked list
    JumpNode j = new JumpNode();
    j.fcodeLoc = u2();
    j.javaFrom = code.pos() - 1;
    j.javaMark = code.pos();
    j.next = jumps;
    jumps = j;

    // leave two bytes to back patch later
    code.info.u2(0xFFFF);

    // return jump node
    return j;
  }

//////////////////////////////////////////////////////////////////////////
// Compare
//////////////////////////////////////////////////////////////////////////

  private void compareEQ()
  {
    if (parent.CompareEQ == 0) parent.CompareEQ = emit.method("fanx/util/OpUtil.compareEQ(Ljava/lang/Object;Ljava/lang/Object;)Z");
    int peek = peekOp();
    switch (peek)
    {
      case JumpFalse:
        code.op2(INVOKESTATIC, parent.CompareEQ);
        consumeOp();
        code.op(IFEQ);
        branch();
        break;
      case JumpTrue:
        code.op2(INVOKESTATIC, parent.CompareEQ);
        consumeOp();
        code.op(IFNE);
        branch();
        break;
      default:
       code.op2(INVOKESTATIC, parent.CompareEQ);
    }
  }

  private void compareNE()
  {
    if (parent.CompareNE == 0) parent.CompareNE = emit.method("fanx/util/OpUtil.compareNE(Ljava/lang/Object;Ljava/lang/Object;)Z");
    int peek = peekOp();
    switch (peek)
    {
      case JumpFalse:
        code.op2(INVOKESTATIC, parent.CompareNE);
        consumeOp();
        code.op(IFEQ);
        branch();
        break;
      case JumpTrue:
        code.op2(INVOKESTATIC, parent.CompareNE);
        consumeOp();
        code.op(IFNE);
        branch();
        break;
      default:
       code.op2(INVOKESTATIC, parent.CompareNE);
    }
  }

  private void compare()
  {
    if (parent.Compare == 0) parent.Compare = emit.method("fanx/util/OpUtil.compare(Ljava/lang/Object;Ljava/lang/Object;)Ljava/lang/Long;");
    code.op2(INVOKESTATIC, parent.Compare);
  }

  private void compareLT()
  {
    if (parent.CompareLT == 0) parent.CompareLT = emit.method("fanx/util/OpUtil.compareLT(Ljava/lang/Object;Ljava/lang/Object;)Z");
    int peek = peekOp();
    switch (peek)
    {
     case JumpFalse:
        code.op2(INVOKESTATIC, parent.CompareLT);
        consumeOp();
        code.op(IFEQ);
        branch();
        break;
      case JumpTrue:
        code.op2(INVOKESTATIC, parent.CompareLT);
        consumeOp();
        code.op(IFNE);
        branch();
        break;
     default:
       code.op2(INVOKESTATIC, parent.CompareLT);
    }
  }

  private void compareLE()
  {
    if (parent.CompareLE == 0) parent.CompareLE = emit.method("fanx/util/OpUtil.compareLE(Ljava/lang/Object;Ljava/lang/Object;)Z");
    int peek = peekOp();
    switch (peek)
    {
      case JumpFalse:
        code.op2(INVOKESTATIC, parent.CompareLE);
        consumeOp();
        code.op(IFEQ);
        branch();
        break;
      case JumpTrue:
        code.op2(INVOKESTATIC, parent.CompareLE);
        consumeOp();
        code.op(IFNE);
        branch();
        break;
      default:
       code.op2(INVOKESTATIC, parent.CompareLE);
    }
  }

  private void compareGE()
  {
    if (parent.CompareGE == 0) parent.CompareGE = emit.method("fanx/util/OpUtil.compareGE(Ljava/lang/Object;Ljava/lang/Object;)Z");
    int peek = peekOp();
    switch (peek)
    {
      case JumpFalse:
        code.op2(INVOKESTATIC, parent.CompareGE);
        consumeOp();
        code.op(IFEQ);
        branch();
        break;
      case JumpTrue:
        code.op2(INVOKESTATIC, parent.CompareGE);
        consumeOp();
        code.op(IFNE);
        branch();
        break;
      default:
       code.op2(INVOKESTATIC, parent.CompareGE);
    }
  }

  private void compareGT()
  {
    if (parent.CompareGT == 0) parent.CompareGT = emit.method("fanx/util/OpUtil.compareGT(Ljava/lang/Object;Ljava/lang/Object;)Z");
    int peek = peekOp();
    switch (peek)
    {
      case JumpFalse:
        code.op2(INVOKESTATIC, parent.CompareGT);
        consumeOp();
        code.op(IFEQ);
        branch();
        break;
      case JumpTrue:
        code.op2(INVOKESTATIC, parent.CompareGT);
        consumeOp();
        code.op(IFNE);
        branch();
        break;
      default:
       code.op2(INVOKESTATIC, parent.CompareGT);
    }
  }

  private void compareSame()
  {
    int peek = peekOp();
    switch (peek)
    {
      case JumpFalse:
        consumeOp();
        code.op(IF_ACMPNE);
        branch();
        break;
      case JumpTrue:
        consumeOp();
        code.op(IF_ACMPEQ);
        branch();
        break;
      default:
       if (parent.CompareSame == 0) parent.CompareSame = emit.method("fanx/util/OpUtil.compareSame(Ljava/lang/Object;Ljava/lang/Object;)Z");
       code.op2(INVOKESTATIC, parent.CompareSame);
    }
  }

  private void compareNotSame()
  {
    int peek = peekOp();
    switch (peek)
    {
      case JumpFalse:
        consumeOp();
        code.op(IF_ACMPEQ);
        branch();
        break;
      case JumpTrue:
        consumeOp();
        code.op(IF_ACMPNE);
        branch();
        break;
      default:
        if (parent.CompareNotSame == 0) parent.CompareNotSame = emit.method("fanx/util/OpUtil.compareNotSame(Ljava/lang/Object;Ljava/lang/Object;)Z");
        code.op2(INVOKESTATIC, parent.CompareNotSame);
    }
  }

  private void compareNull()
  {
    int peek = peekOp();
    switch (peek)
    {
      case JumpFalse:
        consumeOp();
        code.op(IFNONNULL);
        branch();
        break;
      case JumpTrue:
        consumeOp();
        code.op(IFNULL);
        branch();
        break;
      default:
       if (parent.CompareNull == 0) parent.CompareNull = emit.method("fanx/util/OpUtil.compareNull(Ljava/lang/Object;)Z");
       code.op2(INVOKESTATIC, parent.CompareNull);
    }
  }

  private void compareNotNull()
  {
    int peek = peekOp();
    switch (peek)
    {
      case JumpFalse:
        consumeOp();
        code.op(IFNULL);
        branch();
        break;
      case JumpTrue:
        consumeOp();
        code.op(IFNONNULL);
        branch();
        break;
      default:
       if (parent.CompareNotNull == 0) parent.CompareNotNull = emit.method("fanx/util/OpUtil.compareNotNull(Ljava/lang/Object;)Z");
       code.op2(INVOKESTATIC, parent.CompareNotNull);
    }
  }

//////////////////////////////////////////////////////////////////////////
// Stack Manipulation
//////////////////////////////////////////////////////////////////////////

  private void returnOp()  { code.op(returnOp(ret)); }

  static int returnOp(FTypeRef ret) { return returnOp(ret.stackType); }

  static int returnOp(int retStackType)
  {
    switch (retStackType)
    {
      case 'A': return ARETURN;
      case 'I': return IRETURN;
      case 'V': return RETURN;
      case 'Z': return IRETURN;
      default: throw new IllegalStateException(""+(char)retStackType);
    }
  }

  private void dup()
  {
    if (pod.version == FPod.OldFCodeVersion)
    {
      code.op(DUP);
    }
    else
    {
      int typeRef = u2();
      code.op(DUP);
    }
  }

  private void pop()
  {
    if (pod.version == FPod.OldFCodeVersion)
    {
      code.op(POP);
    }
    else
    {
      int typeRef = u2();
      code.op(POP);
    }
  }

//////////////////////////////////////////////////////////////////////////
// Is/As
//////////////////////////////////////////////////////////////////////////

  private void is()
  {
    FTypeRef typeRef = pod.typeRef(u2());

    // if a generic instance, we have to use a method call
    // because Fan types don't map to Java classes exactly;
    // otherwise we can use straight bytecode
    if (typeRef.isGenericInstance())
    {
      if (parent.IsViaType == 0) parent.IsViaType = emit.method("fanx/util/OpUtil.is(Ljava/lang/Object;Lfan/sys/Type;)Z");
      loadType(typeRef);
      code.op2(INVOKESTATIC, parent.IsViaType);
    }
    else
    {
      int cls = emit.cls(typeRef.jnameBoxed());
      code.op2(INSTANCEOF, cls);
    }
  }

  private void as()
  {
    FTypeRef typeRef = pod.typeRef(u2());
    int cls = emit.cls(typeRef.jnameBoxed());

    // if a generic instance, we have to use a method call
    // because Fan types don't map to Java classes exactly;
    // otherwise we can use straight bytecode
    if (typeRef.isGenericInstance())
    {
      if (parent.AsViaType == 0) parent.AsViaType = emit.method("fanx/util/OpUtil.as(Ljava/lang/Object;Lfan/sys/Type;)Ljava/lang/Object;");
      loadType(typeRef);
      code.op2(INVOKESTATIC, parent.AsViaType);
      code.op2(CHECKCAST, cls);
    }
    else
    {
      code.op(DUP);
      code.op2(INSTANCEOF, cls);
      int is = code.branch(IFNE);
      code.op(POP);
      code.op(ACONST_NULL);
      int end = code.branch(GOTO);
      code.mark(is);
      code.op2(CHECKCAST, cls);
      code.mark(end);
    }
  }

//////////////////////////////////////////////////////////////////////////
// Switch
//////////////////////////////////////////////////////////////////////////

  private void tableswitch()
  {
    int count = u2();

    loadIntVal();
    code.op(L2I);
    int start = code.pos();
    code.op(TABLESWITCH);
    int pad = code.padAlign4();
    code.info.u4(1+pad+12+count*4); // default is always fall thru
    code.info.u4(0);
    code.info.u4(count-1);

    // at this point we don't know how fcode locations (abs) will
    // map to Java bytecode locations (rel offsets), so we just
    // keep track of locations to backpatch in a linked list
    for (int i=0; i<count; ++i)
    {
      JumpNode j = new JumpNode();
      j.fcodeLoc = u2();
      j.size     = 4;
      j.javaFrom = start;
      j.javaMark = code.info.len-CodeEmit.Header;
      j.next = jumps;
      jumps = j;
      code.info.u4(-1);  // place holder for backpatch
    }
  }

//////////////////////////////////////////////////////////////////////////
// Coercion
//////////////////////////////////////////////////////////////////////////

  private void coerce()
  {
    FTypeRef from = pod.typeRef(u2());
    FTypeRef to   = pod.typeRef(u2());

    // Bool boxing
    if (from.isBoolPrimitive())
    {
      if (to.isRef()) { boolBox(); return; }
      throw new IllegalStateException("Coerce " + from  + " => " + to);
    }

    // Bool unboxing
    if (to.isBoolPrimitive())
    {
      if (from.isRef()) { boolUnbox(!from.isBool()); return; }
      throw new IllegalStateException("Coerce " + from  + " => " + to);
    }

    // don't bother casting to obj
    if (to.isObj()) return;

    code.op2(CHECKCAST, emit.cls(to.jname()));
  }

  private void cast()
  {
    int cls = emit.cls(pod.typeRef(u2()).jname());
    code.op2(CHECKCAST, cls);
  }

//////////////////////////////////////////////////////////////////////////
// Misc
//////////////////////////////////////////////////////////////////////////

  private void doThrow()
  {
    if (parent.ErrVal == 0) parent.ErrVal = emit.field("fan/sys/Err.val:Lfan/sys/Err$Val;");
    code.op2(GETFIELD, parent.ErrVal);
    code.op(ATHROW);
  }

  private void catchErrStart()
  {
    // there is already a java.lang.Exception on the stack, but
    // we need to map into a sys::Err type
    if (parent.ErrMake == 0) parent.ErrMake = emit.method("fan/sys/Err.make(Ljava/lang/Throwable;)Lfan/sys/Err;");
    code.op2(INVOKESTATIC, parent.ErrMake);
    cast();
  }

  private void jumpFinally()
  {
    code.op(JSR);
    JumpNode j = branch();
    j.isFinally = true;
  }

  private void finallyStart()
  {
    // create a new temporary local variable to stash stack pointer
    if (finallyEx < 0)
    {
      finallyEx = fmethod.maxLocals();
      finallySp = fmethod.maxLocals()+1;
      code.maxLocals += 2;
    }

    // generate the "catch all" block - this section of code
    // is always 8 bytes, hence the eight byte offset we have to
    // add to the JumpFinally/JSR offset to skip it to get the
    // real finally block start instruction
    code.op1(ASTORE, finallyEx); // stash exception (ensure fixed width instr)
    code.op2(JSR, 6);            // call finally "subroutine"
    code.op1(ALOAD, finallyEx);  // stash exception (ensure fixed width instr)
    code.op(ATHROW);             // rethrow it

    // generate start of finally block
    storeVarObj(finallySp);      // stash stack pointer
  }

  private void finallyEnd()
  {
    code.op1(RET, finallySp);
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  private int varStackType(int index)
  {
    if (vars == null) throw new IllegalStateException("Use of variable outside of method");
    if (!isStatic)
    {
      if (index == 0) return FTypeRef.OBJ; // assume this pointer
      else --index;
    }
    return pod.typeRef(vars[index].type).stackType;
  }

  private void boolBox()
  {
    if (parent.BoolBox == 0) parent.BoolBox = emit.method("java/lang/Boolean.valueOf(Z)Ljava/lang/Boolean;");
    code.op2(INVOKESTATIC, parent.BoolBox);
  }

  private void boolUnbox(boolean cast)
  {
    if (cast) code.op2(CHECKCAST, emit.cls("java/lang/Boolean"));
    if (parent.BoolUnbox== 0) parent.BoolUnbox = emit.method("java/lang/Boolean.booleanValue()Z");
    code.op2(INVOKEVIRTUAL, parent.BoolUnbox);
  }

  private void loadIntVal()
  {
    if (parent.IntVal == 0) parent.IntVal = emit.method("java/lang/Long.longValue()J");
    code.op2(INVOKEVIRTUAL, parent.IntVal);
  }

  private void typeToNullable()
  {
    if (parent.TypeToNullable == 0) parent.TypeToNullable = emit.method("fan/sys/Type.toNullable()Lfan/sys/Type;");
    code.op2(INVOKEVIRTUAL, parent.TypeToNullable);
  }

//////////////////////////////////////////////////////////////////////////
// Buf
//////////////////////////////////////////////////////////////////////////

  private int consumeOp()
  {
    reloc[pos] = code.pos();  // store fcode -> bytecode relocation offsets (8 bytes left for Code header)
    return u1();
  }

  private int peekOp()
  {
    if (pos < len) return buf[pos];
    return -1;
  }

  private int u1() { return buf[pos++]; }
  private int u2() { return (buf[pos++] & 0xFF) << 8 | (buf[pos++] & 0xFF); }
  private int u4() { return (buf[pos++] & 0xFF) << 24 | (buf[pos++] & 0xFF) << 16 | (buf[pos++] & 0xFF) << 8 | (buf[pos++] & 0xFF); }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  static class JumpNode
  {
    int fcodeLoc;       // fcode location (index of fcode opcode in byte buffer)
    int javaMark;       // location in java bytecode to backpatch the java offset
    int javaFrom;       // loc in java to consider as jump base in computing relative offset
    int size = 2;       // size in bytes to backpatch (2 or 4)
    boolean isFinally;  // is this a JSR branch to a finally block
    JumpNode next;      // next in linked list
  }

  FPod pod;
  FTypeEmit parent;
  FMethod fmethod;     // maybe null
  FMethodVar[] vars;   // method variables must be set for loadVar/storeVar
  boolean isStatic;    // used to determine how to index vars
  FTypeRef ret;        // return type
  byte[] buf;
  int len;
  int pos;
  Emitter emit;
  CodeEmit code;
  String podClass;
  int[] reloc;        // fcode offsets -> java bytecode offsets
  JumpNode jumps;     // link list of jumps to back patch
  int finallyEx = -1; // local variable used in finally to stash catch exception
  int finallySp = -1; // local variable used in finally to stash stack pointer

}