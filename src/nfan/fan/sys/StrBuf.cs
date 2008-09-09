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

    /*
    public Bool equals(Obj obj)
    {
      return val.equals(((Str)obj).val) ? Bool.True : Bool.False;
    }
    */

    public Bool isEmpty()
    {
      return sb.Length == 0 ? Bool.True : Bool.False;
    }

    public Int size()
    {
      return Int.pos(sb.Length);
    }

    public Int get(Int index)
    {
      try
      {
        int i = (int)index.val;
        if (i < 0) i = sb.Length+i;
        return Int.m_pos[sb[i]];
      }
      catch (System.ArgumentOutOfRangeException e)
      {
        throw IndexErr.make(e).val;
      }
    }

    public StrBuf set(Int index, Int ch)
    {
      try
      {
        int i = (int)index.val;
        if (i < 0) i = sb.Length+i;
        sb[i] = (char)ch.val;
        return this;
      }
      catch (System.ArgumentOutOfRangeException e)
      {
        throw IndexErr.make(e).val;
      }
    }

    public StrBuf add(Obj x)
    {
      string s = (x == null) ? "null" : x.toStr().val;
      sb.Append(s);
      return this;
    }

    public StrBuf addChar(Int ch)
    {
      sb.Append((char)ch.val);
      return this;
    }

    public StrBuf join(Obj x) { return join(x, Str.m_ascii[' ']); }
    public StrBuf join(Obj x, Str sep)
    {
      String s = (x == null) ? "null" : x.toStr().val;
      if (sb.Length > 0) sb.Append(sep.val);
      sb.Append(s);
      return this;
    }

    public StrBuf insert(Int index, Obj x)
    {
      string s = (x == null) ? "null" : x.toStr().val;
      int i = (int)index.val;
      if (i < 0) i = sb.Length+i;
      if (i > sb.Length) throw IndexErr.make(index).val;
      sb.Insert(i, s);
      return this;
    }

    public StrBuf remove(Int index)
    {
      int i = (int)index.val;
      if (i < 0) i = sb.Length+i;
      if (i >= sb.Length) throw IndexErr.make(index).val;
      sb.Remove(i, 1);
      return this;
    }

    public StrBuf grow(Int size)
    {
      sb.EnsureCapacity((int)size.val);
      return this;
    }

    public StrBuf clear()
    {
      sb.Length = 0;
      return this;
    }

    public override Str toStr()
    {
      return Str.make(sb.ToString());
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