//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 Sep 06  Andy Frank  Creation
//

using Fanx.Util;

namespace Fanx.Fcode
{
  /// <summary>
  /// FTypeRef stores a typeRef structure used to reference type signatures.
  /// </summary>
  public sealed class FTypeRef
  {

  //////////////////////////////////////////////////////////////////////////
  // Constructors
  //////////////////////////////////////////////////////////////////////////

    public FTypeRef(string podName, string typeName, string sig)
    {
      this.podName  = podName;
      this.typeName = typeName;

      // compute mask
      int mask = 0;
      int stackType = OBJ;
      bool nullable = false;
      if (sig.EndsWith("?")) { mask |= NULLABLE; nullable = true; }
      if (sig.Length > 1)    mask |= GENERIC_INSTANCE;
      if (podName == "sys")
      {
        switch (typeName[0])
        {
          case 'B':
            if (typeName == "Bool")
            {
              mask |= SYS_BOOL;
              if (!nullable) stackType = INT;
            }
            break;
          case 'E':
            if (typeName == "Err") mask |= SYS_ERR;
            break;
          case 'F':
            if (typeName == "Float")
            {
              mask |= SYS_FLOAT;
              if (!nullable) stackType = DOUBLE;
            }
            break;
          case 'I':
            if (typeName == "Int")
            {
              mask |= SYS_INT;
              if (!nullable) stackType = LONG;
            }
            break;
          case 'O':
            if (typeName == "Obj") mask |= SYS_OBJ;
            break;
          case 'V':
            if (typeName == "Void") stackType = VOID;
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

    /// <summary>
    /// Is this a nullable type.
    /// </summary>
    public bool isNullable() { return (mask & NULLABLE) != 0; }

    /// <summary>
    /// Is this a parameterized generic instance like Str[]
    /// </summary>
    public bool isGenericInstance() { return (mask & GENERIC_INSTANCE) != 0; }

    /// <summary>
    /// Is this a reference (boxed) type?
    /// </summary>
    public bool isRef() { return stackType == OBJ; }

    /// <summary>
    /// Is this sys::Obj or sys::Obj?
    /// </summary>
    public bool isObj() { return (mask & SYS_OBJ) != 0; }

    /// <summary>
    /// Is this sys::Bool or sys::Bool?
    /// </summary>
    public bool isBool() { return (mask & SYS_BOOL) != 0; }

    /// <summary>
    /// Is this sys::Bool, boolean primitive
    /// </summary>
    public bool isBoolPrimitive() { return stackType == INT && isBool(); }

    /// <summary>
    /// Is this sys::Int or sys::Int?
    /// </summary>
    public bool isInt() { return (mask & SYS_INT) != 0; }

    /// <summary>
    /// Is this sys::Int, long primitive
    /// </summary>
    public bool isIntPrimitive() { return stackType == LONG && isInt(); }

    /// <summary>
    /// Is this sys::Float or sys::Float?
    /// </summary>
    public bool isFloat() { return (mask & SYS_FLOAT) != 0; }

    /// <summary>
    /// Is this sys::Float, double primitive
    /// </summary>
    public bool isFloatPrimitive() { return stackType == DOUBLE && isFloat(); }

    /// <summary>
    /// Is this sys::Err or sys::Err?
    /// </summary>
    public bool isErr() { return (mask & SYS_ERR) != 0; }

    /// <summary>
    /// Is this a wide stack type (double or long)
    /// </summary>
    public bool isWide() { return stackType == LONG || stackType == DOUBLE; }
    public static bool isWide(int stackType) { return stackType == LONG || stackType == DOUBLE; }

    /// <summary>
    /// .NET type name: Fan.Sys.Duration, System.Boolean
    /// </summary>
    public string nname()
    {
      if (m_nname == null) m_nname = FanUtil.toDotnetTypeName(podName, typeName, isNullable());
      return m_nname;
    }

    /// <summary>
    /// .NET type name, but if this is a primitive return its
    /// boxed class name.
    /// </summary>
    public string nnameBoxed()
    {
      /*
      if (stackType == OBJ) return nname();
      if (isBoolPrimitive()) return "java/lang/Boolean";
      if (isFloatPrimitive()) return "java/lang/Double";
      throw new IllegalStateException(signature);
      */
      if (isFloatPrimitive()) return "Fan.Sys.Double";
      if (isIntPrimitive()) return "Fan.Sys.Long";
      return nname();
    }

    public override string ToString() { return signature; }

  //////////////////////////////////////////////////////////////////////////
  // IO
  //////////////////////////////////////////////////////////////////////////

    public static FTypeRef read(FStore.Input input)
    {
      FPod fpod = input.fpod;
      string podName = fpod.name(input.u2());
      string typeName = fpod.name(input.u2());
      string sig = input.utf(); // full sig if parameterized, "?" if nullable, or ""
      return new FTypeRef(podName, typeName, sig);
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    // mask constants
    public const int NULLABLE         = 0x0001;
    public const int GENERIC_INSTANCE = 0x0002;
    public const int SYS_OBJ          = 0x0004;
    public const int SYS_BOOL         = 0x0008;
    public const int SYS_INT          = 0x0010;
    public const int SYS_FLOAT        = 0x0020;
    public const int SYS_ERR          = 0x0040;

    // stack type constants
    public const int VOID   = 'V';
    public const int INT    = 'I';
    public const int LONG   = 'J';
    public const int DOUBLE = 'D';
    public const int OBJ    = 'A';

    public readonly string podName;     // pod name "sys"
    public readonly string typeName;    // simple type name "Bool"
    public readonly int mask;           // bitmask
    public readonly int stackType;      // stack type constant
    public readonly string signature;   // full fan signature (qname or parameterized)
    private string m_nname;             // Fan.Sys.Duration, System.Boolean

  }
}