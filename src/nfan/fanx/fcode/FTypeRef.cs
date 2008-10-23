//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 Sep 06  Andy Frank  Creation
//

using System;

namespace Fanx.Fcode
{
  ///
  /// FTypeRef stores a typeRef structure used to reference type signatures.
  ///
  public class FTypeRef
  {

  //////////////////////////////////////////////////////////////////////////
  // Constructors
  //////////////////////////////////////////////////////////////////////////

    public FTypeRef(int podName, int typeName, string sig)
    {
      this.podName  = podName;
      this.typeName = typeName;
      this.sig      = sig;
      this.hash     = (podName << 7) ^ (typeName) ^ (sig.GetHashCode());
    }

  //////////////////////////////////////////////////////////////////////////
  // Identity
  //////////////////////////////////////////////////////////////////////////

    public bool isGenericInstance()
    {
      return sig.Length > 1;  // "?" is non-generic nullable
    }

    public bool isNullable()
    {
      return sig.Length > 0 && sig[sig.Length-1] == '?';
    }

    public override int GetHashCode()
    {
      return hash;
    }

    public override bool Equals(Object obj)
    {
      FTypeRef x = (FTypeRef)obj;
      return podName == x.podName && typeName == x.typeName && sig.Equals(x.sig);
    }

    public string Sig(FPod pod)
    {
      if (isGenericInstance()) return sig;
      return pod.name(podName) + "::" + pod.name(typeName) + sig;
    }

  //////////////////////////////////////////////////////////////////////////
  // IO
  //////////////////////////////////////////////////////////////////////////

    public static FTypeRef read(FStore.Input input)
    {
      return new FTypeRef(input.u2(), input.u2(), input.utf());
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    public readonly int podName;
    public readonly int typeName;
    public readonly string sig;   // full sig if parameterized, "?" if nullable
    public readonly int hash;

  }
}