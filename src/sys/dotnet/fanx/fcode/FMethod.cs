//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Sep 06  Andy Frank  Creation
//

using System;

namespace Fanx.Fcode
{
  /// <summary>
  /// FMethod is the read/write fcode representation of sys::Method.
  /// </summary>
  public class FMethod : FSlot
  {

    public FMethodVar[] pars()
    {
      FMethodVar[] temp = new FMethodVar[m_paramCount];
      Array.Copy(m_vars, temp, m_paramCount);
      return temp;
    }

    public int maxLocals()
    {
      int max = m_paramCount + m_localCount;
      if ((m_flags & FConst.Static) == 0) max++;
      return max;
    }

    public FMethod read(FStore.Input input)
    {
      base.readCommon(input);
      m_ret = input.u2();
      m_inheritedRet = input.u2();
      m_maxStack   = input.u1();
      m_paramCount = input.u1();
      m_localCount = input.u1();
      m_vars = new FMethodVar[m_paramCount+m_localCount];
      for (int i=0; i<m_vars.Length; i++)
        m_vars[i] = new FMethodVar().read(input);
      m_code = FBuf.read(input);
      base.readAttrs(input);
      return this;
    }

    public int m_ret;             // type qname index
    public int m_inheritedRet;    // type qname index
    public FMethodVar[] m_vars;   // parameters and local variables
    public int m_maxStack;        // max height of stack
    public int m_paramCount;      // number of params in vars
    public int m_localCount;      // number of locals in vars
    public FBuf m_code;           // method executable code

  }
}
