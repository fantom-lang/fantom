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

    public StrInStream(Str str) : base(null)
    {
      m_str  = str.val;
      m_size = str.val.Length;
      m_pos  = 0;
    }

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

    public override Int read()
    {
      int b = r(); return (b < 0) ? null : Int.m_pos[b & 0xFF];
    }

    public override Int readBuf(Buf buf, Int n)
    {
      int nval = (int)n.val;
      for (int i=0; i<nval; ++i)
      {
        int c = rChar();
        if (c < 0) return Int.make(i);
        buf.m_out.w(c);
      }
      return n;
    }

    public override InStream unread(int c)
    {
      return unreadChar(c);
    }

    public override int rChar()
    {
      if (m_pushback != null && m_pushback.sz() > 0)
        return (int)((Int)m_pushback.pop()).val;
      if (m_pos >= m_size) return -1;
      return m_str[m_pos++];
    }

    public override Int readChar()
    {
      if (m_pushback != null && m_pushback.sz() > 0)
        return (Int)m_pushback.pop();
      if (m_pos >= m_size) return null;
      return Int.pos(m_str[m_pos++]);
    }

    public override InStream unreadChar(Int c)
    {
      if (m_pushback == null) m_pushback = new List(Sys.IntType, 8);
      m_pushback.push(c);
      return this;
    }

    public override Boolean close()
    {
      return Boolean.True;
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
