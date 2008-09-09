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

  public StrInStream(Str str)
  {
    this.str  = str.val;
    this.size = str.val.length();
    this.pos  = 0;
  }

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

  public Int read()
  {
    int b = r(); return (b < 0) ? null : Int.pos[b & 0xFF];
  }

  public Int readBuf(Buf buf, Int n)
  {
    int nval = (int)n.val;
    for (int i=0; i<nval; ++i)
    {
      int c = rChar();
      if (c < 0) return Int.make(i);
      buf.out.w(c);
    }
    return n;
  }

  public InStream unread(Int c)
  {
    return unreadChar(c);
  }

  public int rChar()
  {
    if (pushback != null && pushback.sz() > 0)
      return (int)((Int)pushback.pop()).val;
    if (pos >= size) return -1;
    return str.charAt(pos++);
  }

  public Int readChar()
  {
    if (pushback != null && pushback.sz() > 0)
      return (Int)pushback.pop();
    if (pos >= size) return null;
    return Int.pos(str.charAt(pos++));
  }

  public InStream unreadChar(Int c)
  {
    if (pushback == null) pushback = new List(Sys.IntType, 8);
    pushback.push(c);
    return this;
  }

  public Bool close()
  {
    return Bool.True;
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  String str;
  int pos;
  int size;
  List pushback;

}