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
 * FMethod is the fcode representation of sys::Method.
 */
public class FMethod
  extends FSlot
{

  public FMethodVar[] params()
  {
    FMethodVar[] temp = new FMethodVar[paramCount];
    System.arraycopy(vars, 0, temp, 0, paramCount);
    return temp;
  }

  public int maxLocals()
  {
    int max = paramCount + localCount;
    if ((flags & Static) == 0) max++;
    return max;
  }

  public FMethod read(FStore.Input in) throws IOException
  {
    super.readCommon(in);
    ret = in.u2();
    inheritedRet = in.u2();
    maxStack   = in.u1();
    paramCount = in.u1();
    localCount = in.u1();
    vars = new FMethodVar[paramCount+localCount];
    for (int i=0; i<vars.length; ++i)
      vars[i] = new FMethodVar().read(in);
    code = FBuf.read(in);
    super.readAttrs(in);
    return this;
  }

  public int ret;             // type qname index
  public int inheritedRet;    // type qname index
  public FMethodVar[] vars;   // parameters and local variables
  public int maxStack;        // max height of stack
  public int paramCount;      // number of params in vars
  public int localCount;      // number of locals in vars
  public FBuf code;           // method executable code

}