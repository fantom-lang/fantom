//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   1 Aug 06  Brian Frank  Creation
//
package fan.sys;

import java.io.*;
import sun.nio.cs.StreamEncoder;

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
  }

  public StrBufOutStream()
  {
    this.sb = new StringBuilder();
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
    throw UnsupportedErr.make("binary write on StrBuf output").val;
  }

  public OutStream writeBuf(Buf buf, Long n)
  {
    throw UnsupportedErr.make("binary write on StrBuf output").val;
  }

  public OutStream writeChar(char c)
  {
    sb.append(c);
    return this;
  }

  public OutStream writeChar(Long c)
  {
    sb.append((char)c.longValue());
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

  public Boolean close()
  {
    return true;
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  StringBuilder sb;

}
