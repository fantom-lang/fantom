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
      m_charsetEncoder = strBufEncoder();
    }

    public StrBufOutStream() : base(null)
    {
      m_sb = new StringBuilder();
      m_charsetEncoder = strBufEncoder();
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

    public override OutStream write(long x)
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

    public override bool close()
    {
      return true;
    }

  //////////////////////////////////////////////////////////////////////////
  // Charset
  //////////////////////////////////////////////////////////////////////////

    static Charset.Encoder strBufEncoder()
    {
      if (m_strBufEncoder == null) m_strBufEncoder = new StrBufEncoder();
      return m_strBufEncoder;
    }

    static Charset.Encoder m_strBufEncoder;

    class StrBufEncoder : Charset.Encoder
    {
      public override void encode(char ch, OutStream output)
      {
        ((StrBufOutStream)output).m_sb.Append(ch);
      }

      public override void encode(char ch, InStream input)
      {
        throw UnsupportedErr.make("binary write on StrBuf output").val;
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    internal StringBuilder m_sb;

  }
}