//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 Apr 07  Andy Frank  Creation
//

namespace Fan.Sys
{
  /// <summary>
  /// StrInStream.
  /// </summary>
  public class StrInStream : SysInStream
  {

  //////////////////////////////////////////////////////////////////////////
  // Constructor
  //////////////////////////////////////////////////////////////////////////

    public StrInStream(string val) : base(null)
    {
      m_str  = val;
      m_size = val.Length;
      m_pos  = 0;
    }

  //////////////////////////////////////////////////////////////////////////
  // InStream
  //////////////////////////////////////////////////////////////////////////

    public override int r()
    {
      return rChar();
    }

    public override Long read()
    {
      int b = r(); return (b < 0) ? null : Long.valueOf(b & 0xFF);
    }

    public override Long readBuf(Buf buf, long n)
    {
      int nval = (int)n;
      for (int i=0; i<nval; ++i)
      {
        int c = rChar();
        if (c < 0) return Long.valueOf(i);
        buf.m_out.w(c);
      }
      return Long.valueOf(n);
    }

    public override InStream unread(long c)
    {
      return unreadChar(c);
    }

    public override int rChar()
    {
      if (m_pushback != null && m_pushback.sz() > 0)
        return ((Long)m_pushback.pop()).intValue();
      if (m_pos >= m_size) return -1;
      return m_str[m_pos++];
    }

    public override Long readChar()
    {
      if (m_pushback != null && m_pushback.sz() > 0)
        return (Long)m_pushback.pop();
      if (m_pos >= m_size) return null;
      return Long.valueOf(m_str[m_pos++]);
    }

    public override InStream unreadChar(long c)
    {
      if (m_pushback == null) m_pushback = new List(Sys.IntType, 8);
      m_pushback.push(Long.valueOf(c));
      return this;
    }

    public override bool close()
    {
      return true;
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    internal string m_str;
    internal int m_pos;
    internal int m_size;
    internal List m_pushback;

  }

}