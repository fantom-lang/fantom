//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   9 Nov 06  Andy Frank  Creation
//

using System;
using System.Text;

namespace Fan.Sys
{
  /// <summary>
  /// StrBuf mutable random-access sequence of integer characters.
  /// </summary>
  public class StrBuf : FanObj
  {

  //////////////////////////////////////////////////////////////////////////
  // Construction
  //////////////////////////////////////////////////////////////////////////

    /// <summary>
    /// Create with initial capacity of 16.
    /// </summary>
    public static StrBuf make()
    {
      return new StrBuf(new StringBuilder(16));
    }

    /// <summary>
    /// Create with specified capacity.
    /// </summary>
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
      return sb.Length == 0 ? Boolean.True : Boolean.False;
    }

    public Long size()
    {
      return Long.valueOf(sb.Length);
    }

    public Long get(Long index)
    {
      try
      {
        int i = index.intValue();
        if (i < 0) i = sb.Length+i;
        return FanInt.m_pos[sb[i]];
      }
      catch (System.ArgumentOutOfRangeException e)
      {
        throw IndexErr.make(e).val;
      }
    }

    public StrBuf set(Long index, Long ch)
    {
      try
      {
        int i = index.intValue();
        if (i < 0) i = sb.Length+i;
        sb[i] = (char)ch.longValue();
        return this;
      }
      catch (System.ArgumentOutOfRangeException e)
      {
        throw IndexErr.make(e).val;
      }
    }

    public StrBuf add(object x)
    {
      string s = (x == null) ? "null" : toStr(x);
      sb.Append(s);
      return this;
    }

    public StrBuf addChar(Long ch)
    {
      sb.Append((char)ch.longValue());
      return this;
    }

    public StrBuf join(object x) { return join(x, FanStr.m_ascii[' ']); }
    public StrBuf join(object x, string sep)
    {
      string s = (x == null) ? "null" : toStr(x);
      if (sb.Length > 0) sb.Append(sep);
      sb.Append(s);
      return this;
    }

    public StrBuf insert(Long index, object x)
    {
      string s = (x == null) ? "null" : toStr(x);
      int i = index.intValue();
      if (i < 0) i = sb.Length+i;
      if (i > sb.Length) throw IndexErr.make(index).val;
      sb.Insert(i, s);
      return this;
    }

    public StrBuf remove(Long index)
    {
      int i = index.intValue();
      if (i < 0) i = sb.Length+i;
      if (i >= sb.Length) throw IndexErr.make(index).val;
      sb.Remove(i, 1);
      return this;
    }

    public StrBuf grow(Long size)
    {
      sb.EnsureCapacity(size.intValue());
      return this;
    }

    public StrBuf clear()
    {
      sb.Length = 0;
      return this;
    }

    public override string toStr()
    {
      return sb.ToString();
    }

    public override Type type()
    {
      return Sys.StrBufType;
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    internal StringBuilder sb;
  }
}