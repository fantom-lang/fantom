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

    public static Range makeInclusive(long start, long end)
    {
      return new Range(start, end, false);
    }

    public static Range makeExclusive(long start, long end)
    {
      return new Range(start, end, true);
    }

    public static Range make(long start, long end, bool exclusive)
    {
      return new Range(start, end, exclusive);
    }

    private Range(long start, long end, bool exclusive)
    {
      this.m_start = start;
      this.m_end = end;
      this.m_exclusive = exclusive;
    }

  //////////////////////////////////////////////////////////////////////////
  // Range
  //////////////////////////////////////////////////////////////////////////

    public long start()
    {
      return m_start;
    }

    public long end()
    {
      return m_end;
    }

    public bool inclusive()
    {
      return !m_exclusive;
    }

    public bool exclusive()
    {
      return m_exclusive;
    }

    public bool contains(long i)
    {
      if (m_start < m_end)
      {
        if (m_exclusive)
          return m_start <= i && i < m_end;
        else
          return m_start <= i && i <= m_end;
      }
      else
      {
        if (m_exclusive)
          return m_end < i && i <= m_start;
        else
          return m_end <= i && i <= m_start;
      }
    }

    public void each(Func f)
    {
      long start = m_start;
      long end = m_end;
      if (start < end)
      {
        if (m_exclusive) --end;
        for (long i=start; i<=end; ++i) f.call1(i);
      }
      else
      {
        if (m_exclusive) ++end;
        for (long i=start; i>=end; --i) f.call1(i);
      }
    }

    public List toList()
    {
      int start = (int)m_start;
      int end = (int)m_end;
      List acc = new List(Sys.IntType);
      if (start < end)
      {
        if (m_exclusive) --end;
        acc.capacity(end-start+1);
        for (int i=start; i<=end; ++i)
          acc.add(Long.valueOf(i));
      }
      else
      {
        if (m_exclusive) ++end;
        acc.capacity(start-end+1);
        for (int i=start; i>=end; --i)
          acc.add(Long.valueOf(i));
      }
      return acc;
    }

    public override bool Equals(object obj)
    {
      if (obj is Range)
      {
        Range that = (Range)obj;
        return this.m_start == that.m_start &&
               this.m_end == that.m_end &&
               this.m_exclusive == that.m_exclusive;
      }
      return false;
    }

    public override int GetHashCode()
    {
      return m_start.GetHashCode() ^ m_end.GetHashCode();
    }

    public override long hash()
    {
      return m_start ^ m_end;
    }

    public override string toStr()
    {
      if (m_exclusive)
        return m_start.ToString() + "..<" + m_end.ToString();
      else
        return m_start.ToString() + ".." + m_end.ToString();
    }

    public override Type type() { return Sys.RangeType; }

  //////////////////////////////////////////////////////////////////////////
  // Slice Utils
  //////////////////////////////////////////////////////////////////////////

    internal int start(int size)
    {
      int x = (int)m_start;
      if (x < 0) x = size + x;
      if (x > size) throw IndexErr.make(this).val;
      return x;
    }

    internal long start(long size)
    {
      long x = m_start;
      if (x < 0) x = size + x;
      if (x > size) throw IndexErr.make(this).val;
      return x;
    }

    internal int end(int size)
    {
      int x = (int)m_end;
      if (x < 0) x = size + x;
      if (m_exclusive) x--;
      if (x >= size) throw IndexErr.make(this).val;
      return x;
    }

    internal long end(long size)
    {
      long x = m_end;
      if (x < 0) x = size + x;
      if (m_exclusive) x--;
      if (x >= size) throw IndexErr.make(this).val;
      return x;
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    private long m_start, m_end;
    private bool m_exclusive;
  }
}