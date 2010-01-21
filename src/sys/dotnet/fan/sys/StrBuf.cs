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
    public static StrBuf make(long capacity)
    {
      return new StrBuf(new StringBuilder((int)capacity));
    }

    public StrBuf(StringBuilder sb)
    {
      this.sb = sb;
    }

  //////////////////////////////////////////////////////////////////////////
  // Methods
  //////////////////////////////////////////////////////////////////////////

    public bool isEmpty()
    {
      return sb.Length == 0;
    }

    public long size()
    {
      return sb.Length;
    }

    public long capacity()
    {
      return sb.Capacity;
    }

    public void capacity(long size)
    {
      sb.EnsureCapacity((int)size);
    }

    public long get(long index)
    {
      try
      {
        int i = (int)index;
        if (i < 0) i = sb.Length+i;
        return sb[i];
      }
      catch (System.ArgumentOutOfRangeException e)
      {
        throw IndexErr.make(e).val;
      }
    }

    public StrBuf set(long index, long ch)
    {
      try
      {
        int i = (int)index;
        if (i < 0) i = sb.Length+i;
        sb[i] = (char)ch;
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

    public StrBuf addChar(long ch)
    {
      sb.Append((char)ch);
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

    public StrBuf insert(long index, object x)
    {
      string s = (x == null) ? "null" : toStr(x);
      int i = (int)index;
      if (i < 0) i = sb.Length+i;
      if (i > sb.Length) throw IndexErr.make(index).val;
      sb.Insert(i, s);
      return this;
    }

    public StrBuf remove(long index)
    {
      int i = (int)index;
      if (i < 0) i = sb.Length+i;
      if (i >= sb.Length) throw IndexErr.make(index).val;
      sb.Remove(i, 1);
      return this;
    }

    public StrBuf removeRange(Range r)
    {
      int s = r.start(sb.Length);
      int e = r.end(sb.Length);
      int n = e - s + 1;
      if (n < 0) throw IndexErr.make(r).val;
      sb.Remove(s, n);
      return this;
    }

    public StrBuf clear()
    {
      sb.Length = 0;
      return this;
    }

    public OutStream @out()
    {
      return new StrBufOutStream(this);
    }

    public override string toStr()
    {
      return sb.ToString();
    }

    public override Type @typeof()
    {
      return Sys.StrBufType;
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    internal StringBuilder sb;
  }
}