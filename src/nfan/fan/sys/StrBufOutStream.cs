//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 Apr 07  Andy Frank  Creation
//

using System.Text;

namespace Fan.Sys
{
  /// <summary>
  /// StrBufOutStream.
  /// </summary>
  public class StrBufOutStream : SysOutStream
  {

  //////////////////////////////////////////////////////////////////////////
  // Constructor
  //////////////////////////////////////////////////////////////////////////

    public StrBufOutStream(StrBuf buf) : base(null)
    {
      m_sb = buf.sb;
    }

    public StrBufOutStream() : base(null)
    {
      m_sb = new StringBuilder();
    }

  //////////////////////////////////////////////////////////////////////////
  // OutStream
  //////////////////////////////////////////////////////////////////////////

    public string @string() { return m_sb.ToString(); }

  //////////////////////////////////////////////////////////////////////////
  // OutStream
  //////////////////////////////////////////////////////////////////////////

    public override OutStream w(int v)
    {
      throw UnsupportedErr.make("binary write on StrBuf output").val;
    }

    public override OutStream writeBuf(Buf buf, long n)
    {
      throw UnsupportedErr.make("binary write on StrBuf output").val;
    }

    public override OutStream writeChar(char c)
    {
      m_sb.Append(c);
      return this;
    }

    public override OutStream writeChar(long c)
    {
      m_sb.Append((char)c);
      return this;
    }

    public override OutStream writeChars(string s, int off, int len)
    {
      m_sb.Append(s, off, len);
      return this;
    }

    public override OutStream flush()
    {
      return this;
    }

    public override Boolean close()
    {
      return Boolean.True;
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    internal StringBuilder m_sb;

  }
}