//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   30 Jan 06  Brian Frank  Creation
//
package fanx.fcode;

import java.io.*;
import fanx.util.*;

/**
 * FTypeRef stores a typeRef structure used to reference type signatures.
 */
public final class FTypeRef
{

//////////////////////////////////////////////////////////////////////////
// Constructors
//////////////////////////////////////////////////////////////////////////

  FTypeRef(String podName, String typeName, String sig)
  {
    this.podName  = podName;
    this.typeName = typeName;

    // compute mask
    int mask = 0;
    int stackType = OBJ;
    boolean nullable = false;
    if (sig.endsWith("?")) { mask |= NULLABLE; nullable = true; }
    if (sig.length() > 1)  mask |= GENERIC_INSTANCE;
    if (podName.equals("sys"))
    {
      switch (typeName.charAt(0))
      {
        case 'B':
          if (typeName.equals("Bool"))
          {
            mask |= SYS_BOOL;
            if (!nullable) stackType = INT;
          }
          break;
        case 'E':
          if (typeName.equals("Err")) mask |= SYS_ERR;
          break;
        case 'F':
          if (typeName.equals("Float"))
          {
            mask |= SYS_FLOAT;
            if (!nullable) stackType = DOUBLE;
          }
          break;
        case 'I':
          if (typeName.equals("Int"))
          {
            mask |= SYS_INT;
            if (!nullable) stackType = LONG;
          }
          break;
        case 'O':
          if (typeName.equals("Obj")) mask |= SYS_OBJ;
          break;
        case 'V':
          if (typeName.equals("Void")) stackType = VOID;
          break;
      }
    }
    this.mask = mask;
    this.stackType = stackType;

    // compute full siguature
    if (isGenericInstance())
      this.signature = sig;
    else
      this.signature = podName + "::" + typeName + sig;
  }

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  /**
   * Is this a nullable type
   */
  public boolean isNullable() { return (mask & NULLABLE) != 0; }

  /**
   * Is this a parameterized generic instance like Str[]
   */
  public boolean isGenericInstance() { return (mask & GENERIC_INSTANCE) != 0; }

  /**
   * Is this a reference (boxed) type?
   */
  public boolean isRef() { return stackType == OBJ; }

  /**
   * Is this sys::Obj or sys::Obj?
   */
  public boolean isObj() { return (mask & SYS_OBJ) != 0; }

  /**
   * Is this sys::Bool or sys::Bool?
   */
  public boolean isBool() { return (mask & SYS_BOOL) != 0; }

  /**
   * Is this sys::Bool, boolean primitive
   */
  public boolean isBoolPrimitive() { return stackType == INT && isBool(); }

  /**
   * Is this sys::Int or sys::Int?
   */
  public boolean isInt() { return (mask & SYS_INT) != 0; }

  /**
   * Is this sys::Int, long primitive
   */
  public boolean isIntPrimitive() { return stackType == LONG && isInt(); }

  /**
   * Is this sys::Float or sys::Float?
   */
  public boolean isFloat() { return (mask & SYS_FLOAT) != 0; }

  /**
   * Is this sys::Float, double primitive
   */
  public boolean isFloatPrimitive() { return stackType == DOUBLE && isFloat(); }

  /**
   * Is this sys::Err or sys::Err?
   */
  public boolean isErr() { return (mask & SYS_ERR) != 0; }

  /**
   * Is this a wide stack type (double or long)
   */
  public boolean isWide() { return stackType == LONG || stackType == DOUBLE; }

  /**
   * Java type name:  fan/sys/Duration, java/lang/Boolean, Z
   */
  public String jname()
  {
    if (jname == null) jname = FanUtil.toJavaTypeSig(podName, typeName, isNullable());
    return jname;
  }

  /**
   * Java type name, but if this is a primitive return its
   * boxed class name.
   */
  public String jnameBoxed()
  {
    if (stackType == OBJ)   return jname();
    if (isBoolPrimitive())  return "java/lang/Boolean";
    if (isIntPrimitive())   return "java/lang/Long";
    if (isFloatPrimitive()) return "java/lang/Double";
    throw new IllegalStateException(signature);
  }

  /**
   * Java type name for the implementation class:
   *   fan/sys/Duration, fan/sys/FanBool
   */
  public String jimpl()
  {
    return FanUtil.toJavaImplSig(jname());
  }

  /**
   * Java type name for member signatures:
   *   Lfan/sys/Duration;, Ljava/lang/Boolean;, Z
   */
  public String jsig()
  {
    String jname = jname();
    if (jname.length() == 1) return jname;
    return "L" + jname + ";";
  }

  /**
   * Java type name for member signatures:
   *   Lfan/sys/Duration;, Ljava/lang/Boolean;, Z
   */
  public void jsig(StringBuilder s)
  {
    String jname = jname();
    if (jname.length() == 1)
      s.append(jname);
    else
      s.append('L').append(jname).append(';');
  }

  public String toString() { return signature; }

//////////////////////////////////////////////////////////////////////////
// IO
//////////////////////////////////////////////////////////////////////////

  public static FTypeRef read(FStore.Input in) throws IOException
  {
    FPod fpod = in.fpod;
    String podName = fpod.name(in.u2());
    String typeName = fpod.name(in.u2());
    String sig = in.utf(); // full sig if parameterized, "?" if nullable, or ""
    return new FTypeRef(podName, typeName, sig);
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  // mask constants
  public static final int NULLABLE         = 0x0001;
  public static final int GENERIC_INSTANCE = 0x0002;
  public static final int SYS_OBJ          = 0x0004;
  public static final int SYS_BOOL         = 0x0008;
  public static final int SYS_INT          = 0x0010;
  public static final int SYS_FLOAT        = 0x0020;
  public static final int SYS_ERR          = 0x0040;

  // stack type constants
  public static final int VOID   = 'V';
  public static final int INT    = 'I';
  public static final int LONG   = 'J';
  public static final int DOUBLE = 'D';
  public static final int OBJ    = 'A';

  public final String podName;     // pod name "sys"
  public final String typeName;    // simple type name "Bool"
  public final int mask;           // bitmask
  public final int stackType;      // stack type constant
  public final String signature;   // full fan signature (qname or parameterized)
  private String jname;            // fan/sys/Duration, java/lang/Boolean, Z

}