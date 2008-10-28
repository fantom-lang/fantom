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
      if (sig.EndsWith("?")) mask |= NULLABLE;
      if (sig.Length > 1)    mask |= GENERIC_INSTANCE;
      if (podName == "sys")
      {
        if (typeName == "Err") mask |= ERR;
      }
      this.mask = mask;

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
    /// Is this sys::Err
    /// </summary>
    public bool isErr() { return (mask & ERR) != 0; }

    /// <summary>
    /// .NET type name: Fan.Sys.Duration, System.Boolean
    /// </summary>
    public string nname()
    {
      if (m_nname == null) m_nname = FanUtil.toNetTypeName(podName, typeName, isNullable());
      return m_nname;
    }

    public override string ToString() { return "FTypeRef: " + signature; }

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

    public const int NULLABLE         = 0x0001;
    public const int GENERIC_INSTANCE = 0x0002;
    public const int ERR              = 0x0004;

    public readonly string podName;     // pod name "sys"
    public readonly string typeName;    // simple type name "Bool"
    public readonly int mask;           // bitmask
    public readonly string signature;   // full fan signature (qname or parameterized)
    private string m_nname;             // Fan.Sys.Duration, System.Boolean

  }
}