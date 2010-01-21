//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   29 Jan 07  Andy Frank  Creation
//

using System;
using System.Globalization;

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

    public static Range fromStr(string s) { return fromStr(s, true); }
    public static Range fromStr(string s, bool check)
    {
      try
      {
        int dot = s.IndexOf('.');
        if (s[dot+1] != '.') throw new Exception();
        bool exclusive = s[dot+2] == '<';
        long start = Convert.ToInt64(s.Substring(0, dot));
        long end   = Convert.ToInt64(s.Substring(dot + (exclusive?3:2)));
        return new Range(start, end, exclusive);
      }
      catch (Exception) {}
      if (!check) return null;
      throw ParseErr.make("Range", s).val;
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

    public bool isEmpty()
    {
      return m_exclusive && m_start == m_end;
    }

    public Long min()
    {
      if (isEmpty()) return null;
      if (m_end < m_start) return Long.valueOf(m_exclusive ? m_end+1 : m_end);
      return Long.valueOf(m_start);
    }

    public Long max()
    {
      if (isEmpty()) return null;
      if (m_end < m_start) return Long.valueOf(m_start);
      return Long.valueOf(m_exclusive ? m_end-1 : m_end);
    }

    public Long first()
    {
      if (isEmpty()) return null;
      return Long.valueOf(m_start);
    }

    public Long last()
    {
      if (isEmpty()) return null;
      if (!m_exclusive) return Long.valueOf(m_end);
      if (m_start < m_end) return Long.valueOf(m_end-1);
      return Long.valueOf(m_end+1);
    }

    public Range offset(long offset)
    {
      if (offset == 0) return this;
      return new Range(m_start+offset, m_end+offset, m_exclusive);
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
        for (long i=start; i<=end; ++i) f.call(i);
      }
      else
      {
        if (m_exclusive) ++end;
        for (long i=start; i>=end; --i) f.call(i);
      }
    }

    public List map(Func f)
    {
      long start = m_start;
      long end = m_end;
      Type r = f.returns();
      if (r == Sys.VoidType) r = Sys.ObjType.toNullable();
      List acc = new List(r);
      if (start < end)
      {
        if (m_exclusive) --end;
        for (long i=start; i<=end; ++i) acc.add(f.call(i));
      }
      else
      {
        if (m_exclusive) ++end;
        for (long i=start; i>=end; --i) acc.add(f.call(i));
      }
      return acc;
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

    public long random()
    {
      return FanInt.random(this);
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

    public override Type @typeof() { return Sys.RangeType; }

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