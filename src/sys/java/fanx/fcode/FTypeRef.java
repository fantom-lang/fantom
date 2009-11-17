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
 * We use FTypeRef to cache and model the mapping from a Fantom type to Java
 * type.
 */
public final class FTypeRef
{

//////////////////////////////////////////////////////////////////////////
// Constructors
//////////////////////////////////////////////////////////////////////////

  FTypeRef(int id, String podName, String typeName, String sig)
  {
    this.id = id;
    this.podName  = podName;
    this.typeName = typeName;

    // compute mask
    int mask = 0;
    int stackType = OBJ;
    boolean nullable = false;
    if (sig.endsWith("?")) { mask |= NULLABLE; nullable = true; }
    if (sig.length() > 1)  mask |= GENERIC_INSTANCE;
    if (podName.startsWith("[java]"))
    {
      // [java]::
      if (podName.length() == 6)
      {
        if (typeName.equals("int"))        { mask |= PRIMITIVE_INT;   stackType = INT; }
        else if (typeName.equals("char"))  { mask |= PRIMITIVE_CHAR;  stackType = CHAR; }
        else if (typeName.equals("byte"))  { mask |= PRIMITIVE_BYTE;  stackType = BYTE; }
        else if (typeName.equals("short")) { mask |= PRIMITIVE_SHORT; stackType = SHORT; }
        else if (typeName.equals("float")) { mask |= PRIMITIVE_FLOAT; stackType = FLOAT; }
        else throw new IllegalStateException(typeName);
      }

      // [java]fanx.interop::
      else if (podName.equals("[java]fanx.interop"))
      {
        if (typeName.equals("BooleanArray"))     { mask |= ARRAY_BOOL; }
        else if (typeName.equals("ByteArray"))   { mask |= ARRAY_BYTE; }
        else if (typeName.equals("ShortArray"))  { mask |= ARRAY_SHORT; }
        else if (typeName.equals("CharArray"))   { mask |= ARRAY_CHAR; }
        else if (typeName.equals("IntArray"))    { mask |= ARRAY_INT; }
        else if (typeName.equals("LongArray"))   { mask |= ARRAY_LONG; }
        else if (typeName.equals("FloatArray"))  { mask |= ARRAY_FLOAT; }
        else if (typeName.equals("DoubleArray")) { mask |= ARRAY_DOUBLE; }
      }
    }
    else if (podName.equals("sys"))
    {
      switch (typeName.charAt(0))
      {
        case 'B':
          if (typeName.equals("Bool"))
          {
            mask |= SYS_BOOL;
            if (!nullable) { mask |= PRIMITIVE_BOOL; stackType = BOOL; }
          }
          break;
        case 'E':
          if (typeName.equals("Err")) mask |= SYS_ERR;
          break;
        case 'F':
          if (typeName.equals("Float"))
          {
            mask |= SYS_FLOAT;
            if (!nullable) { mask |= PRIMITIVE_DOUBLE; stackType = DOUBLE; }
          }
          break;
        case 'I':
          if (typeName.equals("Int"))
          {
            mask |= SYS_INT;
            if (!nullable) { mask |= PRIMITIVE_LONG; stackType = LONG; }
          }
          break;
        case 'L':
          if (typeName.equals("List")) mask |= SYS_LIST;
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
   * Is this sys::Int or sys::Int?
   */
  public boolean isInt() { return (mask & SYS_INT) != 0; }

  /**
   * Is this sys::Float or sys::Float?
   */
  public boolean isFloat() { return (mask & SYS_FLOAT) != 0; }

  /**
   * Is this sys::Err or sys::Err?
   */
  public boolean isErr() { return (mask & SYS_ERR) != 0; }

  /**
   * Is this some type of sys::List (nullable or parameterized)
   */
  public boolean isList() { return (mask & SYS_LIST) != 0; }

  /**
   * Is this a FFI direct java type?
   */
  public boolean isFFI() { return podName.startsWith("[java]"); }

  /**
   * Is this a wide stack type (double or long)
   */
  public boolean isWide() { return stackType == LONG || stackType == DOUBLE; }
  public static boolean isWide(int stackType) { return stackType == LONG || stackType == DOUBLE; }

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
    if (stackType == OBJ)    return jname();
    if (isPrimitiveBool())   return "java/lang/Boolean";
    if (isPrimitiveLong())   return "java/lang/Long";
    if (isPrimitiveDouble()) return "java/lang/Double";
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
    if (jname.length() == 1 || jname.charAt(0) == '[') return jname;
    return "L" + jname + ";";
  }

  /**
   * Java type name for member signatures:
   *   Lfan/sys/Duration;, Ljava/lang/Boolean;, Z
   */
  public void jsig(StringBuilder s)
  {
    String jname = jname();
    if (jname.length() == 1  || jname.charAt(0) == '[')
      s.append(jname);
    else
      s.append('L').append(jname).append(';');
  }

  public String toString() { return signature; }

//////////////////////////////////////////////////////////////////////////
// Primitives
//////////////////////////////////////////////////////////////////////////

  public boolean isPrimitive()        { return (mask & PRIMITIVE)        != 0; }
  public boolean isPrimitiveBool()    { return (mask & PRIMITIVE_BOOL)   != 0; }
  public boolean isPrimitiveByte()    { return (mask & PRIMITIVE_BYTE)   != 0; }
  public boolean isPrimitiveShort()   { return (mask & PRIMITIVE_SHORT)  != 0; }
  public boolean isPrimitiveChar()    { return (mask & PRIMITIVE_CHAR)   != 0; }
  public boolean isPrimitiveInt()     { return (mask & PRIMITIVE_INT)    != 0; }
  public boolean isPrimitiveLong()    { return (mask & PRIMITIVE_LONG)   != 0; }
  public boolean isPrimitiveFloat()   { return (mask & PRIMITIVE_FLOAT)  != 0; }
  public boolean isPrimitiveDouble()  { return (mask & PRIMITIVE_DOUBLE) != 0; }

  /**
   * Return if this is a byte, short, or int primitive which
   * are all treated as an int on the JVM stack.
   */
  public boolean isPrimitiveIntLike()
  {
    int like = PRIMITIVE_INT | PRIMITIVE_CHAR | PRIMITIVE_SHORT | PRIMITIVE_BYTE;
    return (mask & like) != 0;
  }

//////////////////////////////////////////////////////////////////////////
// Primitive Arrays
//////////////////////////////////////////////////////////////////////////

  /**
   * Return if type is represented directly as a Java primitive array
   * such as "[java]fanx.interop::IntArray".
   */
  public boolean isPrimitiveArray()  { return (mask & PRIMITIVE_ARRAY) != 0; }

  /**
   * If this type is represented as a Java primitive array, get the
   * stack type of component type: int[] -> INT.
   */
  public int arrayOfStackType()
  {
    switch (mask & PRIMITIVE_ARRAY)
    {
      case ARRAY_BOOL:   return BOOL;
      case ARRAY_BYTE:   return BYTE;
      case ARRAY_SHORT:  return SHORT;
      case ARRAY_CHAR:   return CHAR;
      case ARRAY_INT:    return INT;
      case ARRAY_LONG:   return LONG;
      case ARRAY_FLOAT:  return FLOAT;
      case ARRAY_DOUBLE: return DOUBLE;
      default: throw new IllegalStateException(toString());
    }
  }

//////////////////////////////////////////////////////////////////////////
// IO
//////////////////////////////////////////////////////////////////////////

  public static FTypeRef read(int id, FStore.Input in) throws IOException
  {
    FPod fpod = in.fpod;
    String podName = fpod.name(in.u2());
    String typeName = fpod.name(in.u2());
    String sig = in.utf(); // full sig if parameterized, "?" if nullable, or ""
    return new FTypeRef(id, podName, typeName, sig);
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
  public static final int SYS_LIST         = 0x0080;

  // mask primitive constants
  public static final int PRIMITIVE        = 0xff00;
  public static final int PRIMITIVE_BOOL   = 0x0100;
  public static final int PRIMITIVE_BYTE   = 0x0200;
  public static final int PRIMITIVE_SHORT  = 0x0400;
  public static final int PRIMITIVE_CHAR   = 0x0800;
  public static final int PRIMITIVE_INT    = 0x1000;
  public static final int PRIMITIVE_LONG   = 0x2000;
  public static final int PRIMITIVE_FLOAT  = 0x4000;
  public static final int PRIMITIVE_DOUBLE = 0x8000;

  // mask primitive array constants
  public static final int PRIMITIVE_ARRAY  = 0xff0000;
  public static final int ARRAY_BOOL       = 0x010000;
  public static final int ARRAY_BYTE       = 0x020000;
  public static final int ARRAY_SHORT      = 0x040000;
  public static final int ARRAY_CHAR       = 0x080000;
  public static final int ARRAY_INT        = 0x100000;
  public static final int ARRAY_LONG       = 0x200000;
  public static final int ARRAY_FLOAT      = 0x400000;
  public static final int ARRAY_DOUBLE     = 0x800000;

  // stack type constants
  public static final int VOID   = 'V';
  public static final int BOOL   = 'Z';
  public static final int BYTE   = 'B';
  public static final int SHORT  = 'S';
  public static final int CHAR   = 'C';
  public static final int INT    = 'I';
  public static final int LONG   = 'J';
  public static final int FLOAT  = 'F';
  public static final int DOUBLE = 'D';
  public static final int OBJ    = 'A';

  public final int id;             // constant pool index
  public final String podName;     // pod name "sys"
  public final String typeName;    // simple type name "Bool"
  public final int mask;           // bitmask
  public final int stackType;      // stack type constant
  public final String signature;   // full fan signature (qname or parameterized)
  private String jname;            // fan/sys/Duration, java/lang/Boolean, Z

}