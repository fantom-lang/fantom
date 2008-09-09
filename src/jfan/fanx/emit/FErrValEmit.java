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
 * FErrValEmit the special Err$Val inner class for an Err subclass.
 */
public class FErrValEmit
  extends FClassEmit
  implements FConst
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  public FErrValEmit(Type parent, FType type)
  {
    super(parent, type);
  }

//////////////////////////////////////////////////////////////////////////
// Overrides
//////////////////////////////////////////////////////////////////////////

  public Box emit()
  {
    init(jname(type.self)+"$Val", base(), new String[0], PUBLIC);
    this.selfName = jname(type.self);
    emitCtor();
    return classFile = pack();
  }

  protected String base()
  {
    return jname(type.base) + "$Val";
  }

  private void emitCtor()
  {
    // no arg constructor
    MethodEmit me = emitMethod("<init>", "()V", EmitConst.PUBLIC);
    CodeEmit code = me.emitCode();
    code.maxLocals = 1;
    code.maxStack  = 2;
    code.op(ALOAD_0);
    code.op2(INVOKESPECIAL, method(superClassName +".<init>()V"));
    code.op(RETURN);
  }

}