//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   28 Dec 05  Brian Frank  Creation
//
package fan.sys;

/**
 * StrBuf mutable random-access sequence of integer characters.
 */
public class StrBuf
  extends FanObj
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  /**
   * Create with initial capacity of 16.
   */
  public static StrBuf make()
  {
    return new StrBuf(new StringBuilder(16));
  }

  /**
   * Create with specified capacity.
   */
  public static StrBuf make(Int capacity)
  {
    return new StrBuf(new StringBuilder((int)capacity.val));
  }

  public StrBuf(StringBuilder sb)
  {
    this.sb = sb;
  }

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  public Boolean isEmpty()
  {
    return sb.length() == 0;
  }

  public Int size()
  {
    return Int.pos(sb.length());
  }

  public Int get(Int index)
  {
    int i = (int)index.val;
    if (i < 0) i = sb.length()+i;
    return Int.pos(sb.charAt(i));
  }

  public StrBuf set(Int index, Int ch)
  {
    int i = (int)index.val;
    if (i < 0) i = sb.length()+i;
    sb.setCharAt(i, (char)ch.val);
    return this;
  }

  public StrBuf add(Object x)
  {
    String s = (x == null) ? "null" : toStr(x).val;
    sb.append(s);
    return this;
  }

  public StrBuf addChar(Int ch)
  {
    sb.append((char)ch.val);
    return this;
  }

  public StrBuf join(Object x) { return join(x, Str.ascii[' ']); }
  public StrBuf join(Object x, Str sep)
  {
    String s = (x == null) ? "null" : toStr(x).val;
    if (sb.length() > 0) sb.append(sep.val);
    sb.append(s);
    return this;
  }

  public StrBuf insert(Int index, Object x)
  {
    String s = (x == null) ? "null" : toStr(x).val;
    int i = (int)index.val;
    if (i < 0) i = sb.length()+i;
    if (i > sb.length()) throw IndexErr.make(index).val;
    sb.insert(i, s);
    return this;
  }

  public StrBuf remove(Int index)
  {
    int i = (int)index.val;
    if (i < 0) i = sb.length()+i;
    if (i >= sb.length()) throw IndexErr.make(index).val;
    sb.delete(i, i+1);
    return this;
  }

  public StrBuf grow(Int size)
  {
    sb.ensureCapacity((int)size.val);
    return this;
  }

  public StrBuf clear()
  {
    sb.setLength(0);
    return this;
  }

  public Str toStr()
  {
    return Str.make(sb.toString());
  }

  public Type type()
  {
    return Sys.StrBufType;
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  StringBuilder sb;

}