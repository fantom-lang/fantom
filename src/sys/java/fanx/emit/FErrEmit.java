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
 * FErrEmit emits a normal Err class type, which requires a custom
 * constructor and a special type$Val inner class.
 */
public class FErrEmit
  extends FClassEmit
  implements FConst
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  public FErrEmit(Type parent, FType type)
  {
    super(parent, type);
  }

//////////////////////////////////////////////////////////////////////////
// Overrides
//////////////////////////////////////////////////////////////////////////

  protected void emitInstanceInit(FMethod m)
  {
    hasInstanceInit = true;

    // make peer
    if (isNative)
      throw new IllegalStateException("No native support for Err subclasses");

    // no arg constructor -> calls this(Err$Val)
    MethodEmit me = emitMethod("<init>", "()V", EmitConst.PUBLIC);
    CodeEmit code = me.emitCode();
    code.maxLocals = 1;
    code.maxStack  = 3;
    code.op(ALOAD_0);
    code.op2(NEW, cls(className +"$Val"));
    code.op(DUP);
    code.op2(INVOKESPECIAL, method(className +"$Val.<init>()V"));
    code.op2(INVOKESPECIAL, method(className +".<init>(Lfan/sys/Err$Val;)V"));
    code.op(RETURN);

    // arg constructor with Err$Val (and init implementation)
    me = emitMethod("<init>", "(Lfan/sys/Err$Val;)V", EmitConst.PUBLIC);
    code = me.emitCode();
    code.op(ALOAD_0);
    code.op(ALOAD_1);
    code.op2(INVOKESPECIAL, method(superClassName +".<init>(Lfan/sys/Err$Val;)V"));
    if (m == null)
    {
      code.maxLocals = 2;
      code.maxStack  = 2;
      code.op(RETURN);
    }
    else
    {
      FCodeEmit e = new FCodeEmit(this, m, code);
      e.code.maxLocals++;  // alloc room for Val extra argument
      e.emit();
    }
  }

}