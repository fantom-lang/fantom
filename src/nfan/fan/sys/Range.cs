//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   29 Jan 07  Andy Frank  Creation
//

namespace Fan.Sys
{
  /// <summary>
  /// Range.
  /// </summary>
  public sealed class Range : FanObj
  {

  //////////////////////////////////////////////////////////////////////////
  // Constructors
  //////////////////////////////////////////////////////////////////////////

    public static Range makeInclusive(int start, int end)
    {
      return new Range(Int.make(start), Int.make(end), false);
    }

    public static Range makeInclusive(Int start, Int end)
    {
      return new Range(start, end, false);
    }

    public static Range makeExclusive(int start, int end)
    {
      return new Range(Int.make(start), Int.make(end), true);
    }

    public static Range makeExclusive(Int start, Int end)
    {
      return new Range(start, end, true);
    }

    public static Range make(Int start, Int end, Bool exclusive)
    {
      return new Range(start, end, exclusive.val);
    }

    private Range(Int start, Int end, bool exclusive)
    {
      if (start == null || end == null) throw NullErr.make().val;
      this.m_start = start;
      this.m_end = end;
      this.m_exclusive = exclusive;
    }

  //////////////////////////////////////////////////////////////////////////
  // Range
  //////////////////////////////////////////////////////////////////////////

    public Int start()
    {
      return m_start;
    }

    public Int end()
    {
      return m_end;
    }

    public Bool inclusive()
    {
      return m_exclusive ? Bool.False : Bool.True;
    }

    public Bool exclusive()
    {
      return m_exclusive ? Bool.True : Bool.False;
    }

    public Bool contains(Int i)
    {
      if (m_exclusive)
        return Bool.make(m_start.val <= i.val && i.val < m_end.val);
      else
        return Bool.make(m_start.val <= i.val && i.val <= m_end.val);
    }

    public void each(Func f)
    {
      int start = (int)this.m_start.val;
      int end = (int)this.m_end.val;
      if (!m_exclusive) end++;
      for (int i=start; i<end; ++i)
        f.call1(Int.make(i));
    }

    public List toList()
    {
      int start = (int)this.m_start.val;
      int end = (int)this.m_end.val;
      List acc = new List(Sys.IntType);
      if (start < end)
      {
        if (m_exclusive) --end;
        acc.capacity(Int.make(end-start));
        for (int i=start; i<=end; ++i)
          acc.add(Int.make(i));
      }
      else
      {
        if (m_exclusive) ++end;
        acc.capacity(Int.make(start-end));
        for (int i=start; i>=end; --i)
          acc.add(Int.make(i));
      }
      return acc;
    }

    public override Bool equals(Obj obj)
    {
      if (obj is Range)
      {
        Range that = (Range)obj;
        return Bool.make(this.m_start.val == that.m_start.val &&
                         this.m_end.val == that.m_end.val &&
                         this.m_exclusive == that.m_exclusive);
      }
      return Bool.False;
    }

    public override int GetHashCode()
    {
      return m_start.GetHashCode() ^ m_end.GetHashCode();
    }

    public override Int hash()
    {
      return Int.make(m_start.val ^ m_end.val);
    }

    public override Str toStr()
    {
      if (m_exclusive)
        return Str.make(m_start.toStr().val + "..." + m_end.toStr().val);
      else
        return Str.make(m_start.toStr().val + ".." + m_end.toStr().val);
    }

    public override Type type() { return Sys.RangeType; }

  //////////////////////////////////////////////////////////////////////////
  // Slice Utils
  //////////////////////////////////////////////////////////////////////////

    internal int start(int size)
    {
      int x = (int)m_start.val;
      if (x < 0) x = size + x;
      if (x > size) throw IndexErr.make(this).val;
      return x;
    }

    internal long start(long size)
    {
      long x = m_start.val;
      if (x < 0) x = size + x;
      if (x > size) throw IndexErr.make(this).val;
      return x;
    }

    internal int end(int size)
    {
      int x = (int)m_end.val;
      if (x < 0) x = size + x;
      if (m_exclusive) x--;
      if (x >= size) throw IndexErr.make(this).val;
      return x;
    }

    internal long end(long size)
    {
      long x = m_end.val;
      if (x < 0) x = size + x;
      if (m_exclusive) x--;
      if (x >= size) throw IndexErr.make(this).val;
      return x;
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    private Int m_start, m_end;
    private bool m_exclusive;
  }
}
