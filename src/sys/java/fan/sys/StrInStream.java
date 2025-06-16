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
 * StrInStream implements InStream for a String
 */
public class StrInStream
  extends InStream
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  public StrInStream(String val)
  {
    this.str  = val;
    this.size = val.length();
    this.pos  = 0;
  }

  protected InStream toCharInStream()
  {
    return this;
  }

//////////////////////////////////////////////////////////////////////////
// InStream
//////////////////////////////////////////////////////////////////////////

  public int r()
  {
    throw UnsupportedErr.make("Binary read on Str.in");
  }

  public Long read()
  {
    throw UnsupportedErr.make("Binary read on Str.in");
  }

  public Long readBuf(Buf buf, long n)
  {
    throw UnsupportedErr.make("Binary read on Str.in");
  }

  public InStream unread(long c)
  {
    throw UnsupportedErr.make("Binary read on Str.in");
  }

  public int rChar()
  {
    if (pushback != null && pushback.sz() > 0)
      return ((Long)pushback.pop()).intValue();

    if (pos >= size) return -1;

    final char c = str.charAt(pos++);
    if (Character.isHighSurrogate(c) && pos<size)
    {
      final char low = str.charAt(pos++);
      return Character.toCodePoint(c, low);
    }
    return c;
  }

  public Long readChar()
  {
    if (pushback != null && pushback.sz() > 0)
      return (Long)pushback.pop();
    if (pos >= size) return null;

    final char c = str.charAt(pos++);
    if (Character.isHighSurrogate(c) && pos<size)
    {
      final char low = str.charAt(pos++);
      return (long)Character.toCodePoint(c, low);
    }
    return (long)c;
  }

  public InStream unreadChar(long c)
  {
    if (pushback == null) pushback = new List<>(Sys.IntType, 8);
    pushback.push(c);
    return this;
  }

  public boolean close()
  {
    return true;
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  String str;
  int pos;
  int size;
  List<Long> pushback;

}

