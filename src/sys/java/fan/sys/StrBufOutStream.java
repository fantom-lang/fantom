//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   1 Aug 06  Brian Frank  Creation
//
package fan.sys;

import java.io.*;

/**
 * StrBufOutStream
 */
public class StrBufOutStream
  extends OutStream
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  public StrBufOutStream(StrBuf buf)
  {
    this.sb = buf.sb;
    this.charsetEncoder = strBufEncoder;
  }

  public StrBufOutStream()
  {
    this.sb = new StringBuilder();
    this.charsetEncoder = strBufEncoder;
  }

//////////////////////////////////////////////////////////////////////////
// OutStream
//////////////////////////////////////////////////////////////////////////

  public String string() { return sb.toString(); }

//////////////////////////////////////////////////////////////////////////
// OutStream
//////////////////////////////////////////////////////////////////////////

  public OutStream w(int v)
  {
    throw UnsupportedErr.make("Binary write on StrBuf.out").val;
  }

  public OutStream write(long x)
  {
    throw UnsupportedErr.make("Binary write on StrBuf.out").val;
  }

  public OutStream writeBuf(Buf buf, long n)
  {
    throw UnsupportedErr.make("Binary write on StrBuf.out").val;
  }

  public OutStream writeChar(char c)
  {
    sb.append(c);
    return this;
  }

  public OutStream writeChar(long c)
  {
    sb.append((char)c);
    return this;
  }

  public OutStream writeChars(String s, int off, int len)
  {
    sb.append(s, off, off+len);
    return this;
  }

  public OutStream flush()
  {
    return this;
  }

  public boolean close()
  {
    return true;
  }

  static final Charset.Encoder strBufEncoder = new Charset.Encoder()
  {
    public void encode(char ch, OutStream out)
    {
      ((StrBufOutStream)out).sb.append(ch);
    }

    public void encode(char ch, InStream out)
    {
      throw UnsupportedErr.make("Binary write on StrBuf.out").val;
    }
  };

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  StringBuilder sb;

}