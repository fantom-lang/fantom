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
    return rChar();
  }

  public Long read()
  {
    int b = r(); return (b < 0) ? null : FanInt.pos[b & 0xFF];
  }

  public Long readBuf(Buf buf, Long n)
  {
    int nval = n.intValue();
    for (int i=0; i<nval; ++i)
    {
      int c = rChar();
      if (c < 0) return Long.valueOf(i);
      buf.out.w(c);
    }
    return n;
  }

  public InStream unread(Long c)
  {
    return unreadChar(c);
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

  public InStream unreadChar(Long c)
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
