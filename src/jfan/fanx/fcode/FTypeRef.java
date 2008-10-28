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
    if (sig.endsWith("?")) mask |= NULLABLE;
    if (sig.length() > 1)  mask |= GENERIC_INSTANCE;
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

  public boolean isNullable() { return (mask & NULLABLE) != 0; }

  public boolean isGenericInstance() { return (mask & GENERIC_INSTANCE) != 0; }

  public String jname()
  {
    if (jname == null) jname = FanUtil.toJavaTypeSig(podName, typeName, isNullable());
    return jname;
  }

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

  public static final int NULLABLE         = 0x0001;
  public static final int GENERIC_INSTANCE = 0x0002;

  public final String podName;     // pod name "sys"
  public final String typeName;    // simple type name "Bool"
  public final int mask;           // bitmask
  public final String signature;   // full fan signature (qname or parameterized)
  private String jname;           // fan/sys/Duration, java/lang/Boolean, Z

}