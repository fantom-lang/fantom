//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   26 Dec 05  Brian Frank  Creation
//   06 Dec 07  Brian Frank  Rename from FTuple
//
package fanx.fcode;

import java.io.*;
import java.util.*;

/**
 * FMethodRef is used to reference methods for a call operation.
 * We use FMethodRef to cache and model the mapping from a Fan
 * method to Java method.
 */
public class FMethodRef
  implements FConst
{

//////////////////////////////////////////////////////////////////////////
// Constructors
//////////////////////////////////////////////////////////////////////////

  /**
   * Construct from read.
   */
  private FMethodRef(FTypeRef parent, String name, FTypeRef ret, FTypeRef[] params)
  {
    this.parent = parent;
    this.name   = name;
    this.ret    = ret;
    this.params = params;
  }

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  /**
   * Return qname.
   */
  public String toString()
  {
    return parent + "." + name + "()";
  }

  /**
   * Map a fcode method signature to a Java method emit signature.
   */
  public JCall jcall(int opcode)
  {
    JCall jcall = this.jcall;
    if (jcall == null || opcode == CallNonVirtual) // don't use cache on nonvirt (see below)
    {
      // if the type signature is java/lang then we route
      // to static methods on FanObj, FanFloat, etc
      String jname = parent.jname();
      String impl = parent.jimpl();
      boolean explicitSelf = false;
      if (jname != impl)
      {
        explicitSelf = opcode == CallVirtual;
      }
      else
      {
        // if no object method then ok to use cache
        if (jcall != null) return jcall;
      }

      StringBuilder s = new StringBuilder();
      s.append(impl);
      if (opcode == CallMixinStatic) s.append('$');
      s.append('.').append(name).append('(');
      if (explicitSelf) parent.jsig(s);
      for (int i=0; i<params.length; ++i) params[i].jsig(s);
      s.append(')');

      if (opcode == CallNew) parent.jsig(s); // factory
      else ret.jsig(s);

      jcall = new JCall();
      jcall.invokestatic = explicitSelf;
      jcall.sig = s.toString();

      // we don't cache nonvirtuals on Obj b/c of conflicting signatures:
      //  - CallVirtual:     Obj.toStr => static FanObj.toStr(Object)
      //  - CallNonVirtual:  Obj.toStr => FanObj.toStr()
      if (jname == impl || opcode != CallNonVirtual)
        this.jcall = jcall;
    }
    return jcall;
  }

  public static class JCall
  {
    public boolean invokestatic;
    public String sig;
  }

  /**
   * Get this MethodRef's number of arguments for an invokeinterface
   * operation taking into account wide parameters.
   */
  public int toInvokeInterfaceNumArgs(FPod pod)
  {
    if (this.iiNumArgs < 0)
    {
      int numArgs = 1;
      for (int i=0; i<params.length; ++i)
        numArgs += params[i].isWide() ? 2 : 1;
      this.iiNumArgs = numArgs;
    }
    return this.iiNumArgs;
  }

//////////////////////////////////////////////////////////////////////////
// IO
//////////////////////////////////////////////////////////////////////////

  /**
   * Parse from fcode constant pool format:
   *   methodRef
   *   {
   *     u2 parent  (typeRefs.def)
   *     u2 name    (names.def)
   *     u2 retType (typeRefs.def)
   *     u1 paramCount
   *     u2[paramCount] params (typeRefs.def)
   *   }
   */
  public static FMethodRef read(FStore.Input in) throws IOException
  {
    FPod fpod = in.fpod;
    FTypeRef parent = fpod.typeRef(in.u2());
    String name = fpod.name(in.u2());
    FTypeRef ret = fpod.typeRef(in.u2());
    int numParams = in.u1();
    FTypeRef[] params = noParams;
    if (numParams > 0)
    {
      params = new FTypeRef[numParams];
      for (int i=0; i<numParams; ++i) params[i] = fpod.typeRef(in.u2());
    }
    return new FMethodRef(parent, name, ret, params);
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  static final FTypeRef[] noParams = new FTypeRef[0];

  public final FTypeRef parent;
  public final String name;
  public final FTypeRef ret;
  public final FTypeRef[] params;
  private int iiNumArgs = -1;
  private JCall jcall;
}