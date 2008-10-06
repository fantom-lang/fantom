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
  public static StrBuf make(Long capacity)
  {
    return new StrBuf(new StringBuilder(capacity.intValue()));
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

  public Long size()
  {
    return Long.valueOf(sb.length());
  }

  public Long get(Long index)
  {
    int i = index.intValue();
    if (i < 0) i = sb.length()+i;
    return Long.valueOf(sb.charAt(i));
  }

  public StrBuf set(Long index, Long ch)
  {
    int i = index.intValue();
    if (i < 0) i = sb.length()+i;
    sb.setCharAt(i, (char)ch.longValue());
    return this;
  }

  public StrBuf add(Object x)
  {
    String s = (x == null) ? "null" : toStr(x);
    sb.append(s);
    return this;
  }

  public StrBuf addChar(Long ch)
  {
    sb.append((char)ch.longValue());
    return this;
  }

  public StrBuf join(Object x) { return join(x, " "); }
  public StrBuf join(Object x, String sep)
  {
    String s = (x == null) ? "null" : toStr(x);
    if (sb.length() > 0) sb.append(sep);
    sb.append(s);
    return this;
  }

  public StrBuf insert(Long index, Object x)
  {
    String s = (x == null) ? "null" : toStr(x);
    int i = index.intValue();
    if (i < 0) i = sb.length()+i;
    if (i > sb.length()) throw IndexErr.make(index).val;
    sb.insert(i, s);
    return this;
  }

  public StrBuf remove(Long index)
  {
    int i = index.intValue();
    if (i < 0) i = sb.length()+i;
    if (i >= sb.length()) throw IndexErr.make(index).val;
    sb.delete(i, i+1);
    return this;
  }

  public StrBuf grow(Long size)
  {
    sb.ensureCapacity(size.intValue());
    return this;
  }

  public StrBuf clear()
  {
    sb.setLength(0);
    return this;
  }

  public String toStr()
  {
    return sb.toString();
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
