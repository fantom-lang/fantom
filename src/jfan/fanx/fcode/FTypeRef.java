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
public class FTypeRef
{

//////////////////////////////////////////////////////////////////////////
// Constructors
//////////////////////////////////////////////////////////////////////////

  public FTypeRef(int podName, int typeName, String sig)
  {
    this.podName  = podName;
    this.typeName = typeName;
    this.sig      = sig;
    this.hash     = (podName << 7) ^ (typeName) ^ (sig.hashCode());
  }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  public boolean isGenericInstance()
  {
    return sig.length() > 1;  // "?" is non-generic nullable
  }

  public boolean isNullable()
  {
    return sig.length() > 0 && sig.charAt(sig.length()-1) == '?';
  }

  public int hashCode()
  {
    return hash;
  }

  public boolean equals(Object obj)
  {
    FTypeRef x = (FTypeRef)obj;
    return podName == x.podName && typeName == x.typeName && sig.equals(x.sig);
  }

  public String sig(FPod pod)
  {
    if (isGenericInstance()) return sig;
    return pod.name(podName) + "::" + pod.name(typeName) + sig;
  }

//////////////////////////////////////////////////////////////////////////
// IO
//////////////////////////////////////////////////////////////////////////

  public static FTypeRef read(FStore.Input in) throws IOException
  {
    return new FTypeRef(in.u2(), in.u2(), in.utf());
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  public final int podName;
  public final int typeName;
  public final String sig;  // full sig if parameterized, "?" if nullable
  public final int hash;

}