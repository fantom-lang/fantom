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
      return new Range(Long.valueOf(start), Long.valueOf(end), false);
    }

    public static Range makeInclusive(Long start, Long end)
    {
      return new Range(start, end, false);
    }

    public static Range makeExclusive(int start, int end)
    {
      return new Range(Long.valueOf(start), Long.valueOf(end), true);
    }

    public static Range makeExclusive(Long start, Long end)
    {
      return new Range(start, end, true);
    }

    public static Range make(Long start, Long end, Boolean exclusive)
    {
      return new Range(start, end, exclusive.booleanValue());
    }

    private Range(Long start, Long end, bool exclusive)
    {
      if (start == null || end == null) throw NullErr.make().val;
      this.m_start = start;
      this.m_end = end;
      this.m_exclusive = exclusive;
    }

  //////////////////////////////////////////////////////////////////////////
  // Range
  //////////////////////////////////////////////////////////////////////////

    public Long start()
    {
      return m_start;
    }

    public Long end()
    {
      return m_end;
    }

    public Boolean inclusive()
    {
      return m_exclusive ? Boolean.False : Boolean.True;
    }

    public Boolean exclusive()
    {
      return m_exclusive ? Boolean.True : Boolean.False;
    }

    public Boolean contains(Long i)
    {
      if (m_exclusive)
        return Boolean.valueOf(m_start.longValue() <= i.longValue() && i.longValue() < m_end.longValue());
      else
        return Boolean.valueOf(m_start.longValue() <= i.longValue() && i.longValue() <= m_end.longValue());
    }

    public void each(Func f)
    {
      int start = this.m_start.intValue();
      int end = this.m_end.intValue();
      if (!m_exclusive) end++;
      for (int i=start; i<end; ++i)
        f.call1(Long.valueOf(i));
    }

    public List toList()
    {
      int start = this.m_start.intValue();
      int end = this.m_end.intValue();
      List acc = new List(Sys.IntType);
      if (start < end)
      {
        if (m_exclusive) --end;
        acc.capacity(Long.valueOf(end-start));
        for (int i=start; i<=end; ++i)
          acc.add(Long.valueOf(i));
      }
      else
      {
        if (m_exclusive) ++end;
        acc.capacity(Long.valueOf(start-end));
        for (int i=start; i>=end; --i)
          acc.add(Long.valueOf(i));
      }
      return acc;
    }

    public override Boolean _equals(object obj)
    {
      if (obj is Range)
      {
        Range that = (Range)obj;
        return Boolean.valueOf(this.m_start.longValue() == that.m_start.longValue() &&
                         this.m_end.longValue() == that.m_end.longValue() &&
                         this.m_exclusive == that.m_exclusive);
      }
      return Boolean.False;
    }

    public override int GetHashCode()
    {
      return m_start.GetHashCode() ^ m_end.GetHashCode();
    }

    public override Long hash()
    {
      return Long.valueOf(m_start.longValue() ^ m_end.longValue());
    }

    public override string toStr()
    {
      if (m_exclusive)
        return m_start.ToString() + "..." + m_end.ToString();
      else
        return m_start.ToString() + ".." + m_end.ToString();
    }

    public override Type type() { return Sys.RangeType; }

  //////////////////////////////////////////////////////////////////////////
  // Slice Utils
  //////////////////////////////////////////////////////////////////////////

    internal int start(int size)
    {
      int x = m_start.intValue();
      if (x < 0) x = size + x;
      if (x > size) throw IndexErr.make(this).val;
      return x;
    }

    internal long start(long size)
    {
      long x = m_start.longValue();
      if (x < 0) x = size + x;
      if (x > size) throw IndexErr.make(this).val;
      return x;
    }

    internal int end(int size)
    {
      int x = m_end.intValue();
      if (x < 0) x = size + x;
      if (m_exclusive) x--;
      if (x >= size) throw IndexErr.make(this).val;
      return x;
    }

    internal long end(long size)
    {
      long x = m_end.longValue();
      if (x < 0) x = size + x;
      if (m_exclusive) x--;
      if (x >= size) throw IndexErr.make(this).val;
      return x;
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    private Long m_start, m_end;
    private bool m_exclusive;
  }
}