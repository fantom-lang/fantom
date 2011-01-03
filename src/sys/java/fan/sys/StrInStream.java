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
 * StrInStream
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

//////////////////////////////////////////////////////////////////////////
// InStream
//////////////////////////////////////////////////////////////////////////

  public int r()
  {
    throw UnsupportedErr.make("Binary read on Str.in").val;
  }

  public Long read()
  {
    throw UnsupportedErr.make("Binary read on Str.in").val;
  }

  public Long readBuf(Buf buf, long n)
  {
    throw UnsupportedErr.make("Binary read on Str.in").val;
  }

  public InStream unread(long c)
  {
    throw UnsupportedErr.make("Binary read on Str.in").val;
  }

  public int rChar()
  {
    if (pushback != null && pushback.sz() > 0)
      return ((Long)pushback.pop()).intValue();
    if (pos >= size) return -1;
    return str.charAt(pos++);
  }

  public Long readChar()
  {
    if (pushback != null && pushback.sz() > 0)
      return (Long)pushback.pop();
    if (pos >= size) return null;
    return Long.valueOf(str.charAt(pos++));
  }

  public InStream unreadChar(long c)
  {
    if (pushback == null) pushback = new List(Sys.IntType, 8);
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
  List pushback;

}