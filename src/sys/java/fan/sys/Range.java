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

  public static final Range makeInclusive(long start, long end)
  {
    return new Range(start, end, false);
  }

  public static final Range makeExclusive(long start, long end)
  {
    return new Range(start, end, true);
  }

  public static final Range make(long start, long end, boolean exclusive)
  {
    return new Range(start, end, exclusive);
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

  public final boolean contains(long i)
  {
    if (exclusive)
      return start <= i && i < end;
    else
      return start <= i && i <= end;
  }

  public final void each(Func f)
  {
    long start = this.start;
    long end = this.end;
    if (!exclusive) end++;
    for (long i=start; i<end; ++i)
      f.call1(Long.valueOf(i));
  }

  public final List toList()
  {
    long start = this.start;
    long end = this.end;
    List acc = new List(Sys.IntType);
    if (start < end)
    {
      if (exclusive) --end;
      acc.capacity(Long.valueOf(end-start));
      for (long i=start; i<=end; ++i)
        acc.add(Long.valueOf(i));
    }
    else
    {
      if (exclusive) ++end;
      acc.capacity(Long.valueOf(start-end));
      for (long i=start; i>=end; --i)
        acc.add(Long.valueOf(i));
    }
    return acc;
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
      return start + "..." + end;
    else
      return start + ".." + end;
  }

  public Type type() { return Sys.RangeType; }

//////////////////////////////////////////////////////////////////////////
// Slice Utils
//////////////////////////////////////////////////////////////////////////

  final int start(int size)
  {
    int x = (int)start;
    if (x < 0) x = size + x;
    if (x > size) throw IndexErr.make(this).val;
    return x;
  }

  final long start(long size)
  {
    long x = start;
    if (x < 0) x = size + x;
    if (x > size) throw IndexErr.make(this).val;
    return x;
  }

  final int end(int size)
  {
    int x = (int)end;
    if (x < 0) x = size + x;
    if (exclusive) x--;
    if (x >= size) throw IndexErr.make(this).val;
    return x;
  }

  final long end(long size)
  {
    long x = end;
    if (x < 0) x = size + x;
    if (exclusive) x--;
    if (x >= size) throw IndexErr.make(this).val;
    return x;
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private long start, end;
  private boolean exclusive;
}