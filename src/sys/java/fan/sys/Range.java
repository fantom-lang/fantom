//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   11 Dec 05  Brian Frank  Creation
//
package fan.sys;

/**
 * Range
 */
public final class Range
  extends FanObj
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

  public static Range make(long start, long end, boolean exclusive)
  {
    return new Range(start, end, exclusive);
  }

  public static Range fromStr(String s) { return fromStr(s, true); }
  public static Range fromStr(String s, boolean checked)
  {
    try
    {
      int dot = s.indexOf('.');
      if (s.charAt(dot+1) != '.') throw new Exception();
      boolean exclusive = s.charAt(dot+2) == '<';
      long start = Long.parseLong(s.substring(0, dot));
      long end   = Long.parseLong(s.substring(dot + (exclusive?3:2)));
      return new Range(start, end, exclusive);
    }
    catch (Exception e) {}
    if (!checked) return null;
    throw ParseErr.make("Range", s);
  }

  private Range(long start, long end, boolean exclusive)
  {
    this.start = start;
    this.end = end;
    this.exclusive = exclusive;
  }

//////////////////////////////////////////////////////////////////////////
// Range
//////////////////////////////////////////////////////////////////////////

  public final long start()
  {
    return start;
  }

  public final long end()
  {
    return end;
  }

  public final boolean inclusive()
  {
    return !exclusive;
  }

  public final boolean exclusive()
  {
    return exclusive;
  }

  public final boolean isEmpty()
  {
    return exclusive && start == end;
  }

  public final Long min()
  {
    if (isEmpty()) return null;
    if (end < start) return Long.valueOf(exclusive ? end+1 : end);
    return Long.valueOf(start);
  }

  public final Long max()
  {
    if (isEmpty()) return null;
    if (end < start) return Long.valueOf(start);
    return Long.valueOf(exclusive ? end-1 : end);
  }

  public final Long first()
  {
    if (isEmpty()) return null;
    return Long.valueOf(start);
  }

  public final Long last()
  {
    if (isEmpty()) return null;
    if (!exclusive) return Long.valueOf(end);
    if (start < end) return Long.valueOf(end-1);
    return Long.valueOf(end+1);
  }

  public final boolean contains(long i)
  {
    if (start < end)
    {
      if (exclusive)
        return start <= i && i < end;
      else
        return start <= i && i <= end;
    }
    else
    {
      if (exclusive)
        return end < i && i <= start;
      else
        return end <= i && i <= start;
    }
  }

  public final Range offset(long offset)
  {
    if (offset == 0) return this;
    return new Range(start+offset, end+offset, exclusive);
  }

  public final void each(Func f)
  {
    long start = this.start;
    long end = this.end;
    if (start < end)
    {
      if (exclusive) --end;
      for (long i=start; i<=end; ++i) f.call(Long.valueOf(i));
    }
    else
    {
      if (exclusive) ++end;
      for (long i=start; i>=end; --i) f.call(Long.valueOf(i));
    }
  }

  public final List map(Func f)
  {
    long start = this.start;
    long end = this.end;
    Type r = f.returns();
    if (r == Sys.VoidType) r = Sys.ObjType.toNullable();
    List acc = new List(r);
    if (start < end)
    {
      if (exclusive) --end;
      for (long i=start; i<=end; ++i) acc.add(f.call(Long.valueOf(i)));
    }
    else
    {
      if (exclusive) ++end;
      for (long i=start; i>=end; --i) acc.add(f.call(Long.valueOf(i)));
    }
    return acc;
  }

  public final List toList()
  {
    long start = this.start;
    long end = this.end;
    List acc = new List(Sys.IntType);
    if (start < end)
    {
      if (exclusive) --end;
      acc.capacity(Long.valueOf(end-start+1));
      for (long i=start; i<=end; ++i) acc.add(Long.valueOf(i));
    }
    else
    {
      if (exclusive) ++end;
      acc.capacity(Long.valueOf(start-end+1));
      for (long i=start; i>=end; --i) acc.add(Long.valueOf(i));
    }
    return acc;
  }

  public final long random()
  {
    return FanInt.random(this);
  }

  public final boolean equals(Object object)
  {
    if (object instanceof Range)
    {
      Range that = (Range)object;
      return this.start == that.start &&
             this.end == that.end &&
             this.exclusive == that.exclusive;
    }
    return false;
  }

  public final long hash()
  {
    return (start << 24) ^ end;
  }

  public String toStr()
  {
    if (exclusive)
      return start + "..<" + end;
    else
      return start + ".." + end;
  }

  public Type typeof() { return Sys.RangeType; }

//////////////////////////////////////////////////////////////////////////
// Slice Utils
//////////////////////////////////////////////////////////////////////////

  final int start(int size)
  {
    int x = (int)start;
    if (x < 0) x = size + x;
    if (x > size) throw IndexErr.make(this);
    return x;
  }

  final long start(long size)
  {
    long x = start;
    if (x < 0) x = size + x;
    if (x > size) throw IndexErr.make(this);
    return x;
  }

  final int end(int size)
  {
    int x = (int)end;
    if (x < 0) x = size + x;
    if (exclusive) x--;
    if (x >= size) throw IndexErr.make(this);
    return x;
  }

  final long end(long size)
  {
    long x = end;
    if (x < 0) x = size + x;
    if (exclusive) x--;
    if (x >= size) throw IndexErr.make(this);
    return x;
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private final long start, end;
  private final boolean exclusive;
}