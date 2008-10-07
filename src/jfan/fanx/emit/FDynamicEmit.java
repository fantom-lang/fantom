//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   29 May 06  Brian Frank  Creation
//
package fanx.emit;

import java.util.*;
import fan.sys.*;
import fanx.fcode.*;
import fanx.util.*;

/**
 * FDynamicEmit emits a subclass of a normal class which stores
 * it's type per instance rather than in a static field.
 */
public class FDynamicEmit
  extends Emitter
  implements FConst
{

//////////////////////////////////////////////////////////////////////////
// Factory
//////////////////////////////////////////////////////////////////////////

  public static Class emitAndLoad(Type base)
    throws Exception
  {
    FDynamicEmit e = new FDynamicEmit(base);
    Box cf = e.emit();
    return FanClassLoader.loadClass(e.className.replace('/', '.'), cf);
  }

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  public FDynamicEmit(Type base)
  {
    this.base = base;
  }

//////////////////////////////////////////////////////////////////////////
// Overrides
//////////////////////////////////////////////////////////////////////////

  public Box emit()
  {
    superClassName = "fan/" + base.pod().name() + "/" + base.name();
    init(superClassName +"$Dynamic", superClassName , new String[0], PUBLIC);
    emitType();
    emitCtor();
    return pack();
  }

  private void emitType()
  {
    // generate public static Type $dtype; set in <init>
    dtypeField = emitField("$dtype", "Lfan/sys/Type;", EmitConst.PUBLIC|EmitConst.FINAL);

    // generate type() instance method
    MethodEmit me = emitMethod("type", "()Lfan/sys/Type;", EmitConst.PUBLIC);
    CodeEmit code = me.emitCode();
    code.maxLocals = 1;
    code.maxStack  = 2;
    code.op(ALOAD_0);
    code.op2(GETFIELD, dtypeField.ref());
    code.op(ARETURN);
 }

  private void emitCtor()
  {
    // no arg constructor
    MethodEmit me = emitMethod("<init>", "(Lfan/sys/Type;)V", EmitConst.PUBLIC);
    CodeEmit code = me.emitCode();
    code.maxLocals = 2;
    code.maxStack  = 2;
    code.op(ALOAD_0);
    code.op2(INVOKESPECIAL, method(superClassName +".<init>()V"));
    code.op(ALOAD_0);
    code.op(ALOAD_1);
    code.op2(PUTFIELD, dtypeField.ref());
    code.op(ALOAD_0);
    code.op2(INVOKESTATIC, method(superClassName +".make$(L" + superClassName + ";)V"));
    code.op(RETURN);
  }

  Type base;
  FieldEmit dtypeField;
}