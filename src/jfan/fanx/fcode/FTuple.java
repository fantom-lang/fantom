//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   26 Dec 05  Brian Frank  Creation
//
package fanx.fcode;

import java.io.*;
import java.util.*;

/**
 * FTuple stores a list of FTable indices to model a more complex
 * struction like a type's qname or a slot signature.
 */
public class FTuple
{

//////////////////////////////////////////////////////////////////////////
// Constructors
//////////////////////////////////////////////////////////////////////////

  public FTuple(int a, int b)
  {
    this.val = new int[] { a, b };
  }

  public FTuple(int a, int b, int c)
  {
    this.val = new int[] { a, b, c };
  }

  public FTuple(int[] val)
  {
    this.val = val;
  }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  /*
  public int hashCode()
  {
    if (hashCode == 0)
    {
      int hash = 33;
      for (int i=0; i<val.length; ++i)
        hash ^= val[i] << i;
    }
    return hashCode;
  }

  public boolean equals(Object obj)
  {
    FTuple x = (FTuple)obj;
    if (val.length != x.val.length) return false;
    for (int i=0; i<val.length; ++i)
      if (val[i] != x.val[i]) return false;
    return true;
  }
  */

  public String toString()
  {
    StringBuilder s = new StringBuilder();
    s.append('{');
    for (int i=0; i<val.length; ++i)
    {
      if (i > 0) s.append(", ");
      s.append(val[i]);
    }
    s.append('}');
    return s.toString();
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
      for (int i=3; i<val.length; ++i)
      {
        FTypeRef tr = pod.typeRef(val[i]);
        numArgs += tr.isWide() ? 2 : 1;
      }
      this.iiNumArgs = numArgs;
    }
    return this.iiNumArgs;
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  public int[] val;
  private int iiNumArgs = -1;
}