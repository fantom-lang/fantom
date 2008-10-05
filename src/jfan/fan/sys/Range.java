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

  public static final Range makeInclusive(int start, int end)
  {
    return makeInclusive(Long.valueOf(start), Long.valueOf(end));
  }

  public static final Range makeInclusive(Long start, Long end)
  {
    return new Range(start, end, false);
  }

  public static final Range makeExclusive(int start, int end)
  {
    return makeExclusive(Long.valueOf(start), Long.valueOf(end));
  }

  public static final Range makeExclusive(Long start, Long end)
  {
    return new Range(start, end, true);
  }

  public static final Range make(Long start, Long end, Boolean exclusive)
  {
    return new Range(start, end, exclusive);
  }

  private Range(Long start, Long end, boolean exclusive)
  {
    if (start == null || end == null) throw NullErr.make().val;
    this.start = start;
    this.end = end;
    this.exclusive = exclusive;
  }

//////////////////////////////////////////////////////////////////////////
// Range
//////////////////////////////////////////////////////////////////////////

  public final Long start()
  {
    return start;
  }

  public final Long end()
  {
    return end;
  }

  public final Boolean inclusive()
  {
    return !exclusive;
  }

  public final Boolean exclusive()
  {
    return exclusive;
  }

  public final Boolean contains(Long i)
  {
    if (exclusive)
      return start.longValue() <= i.longValue() && i.longValue() < end.longValue();
    else
      return start.longValue() <= i.longValue() && i.longValue() <= end.longValue();
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

  public final Boolean _equals(Object object)
  {
    if (object instanceof Range)
    {
      Range that = (Range)object;
      return this.start.longValue() == that.start.longValue()&&
             this.end.longValue() == that.end.longValue() &&
             this.exclusive == that.exclusive;
    }
    return false;
  }

  public final int hashCode()
  {
    return start.hashCode() ^ end.hashCode();
  }

  public final Long hash()
  {
    return (start.longValue() << 24) ^ end.longValue();
  }

  public Str toStr()
  {
    if (exclusive)
      return Str.make(start + "..." + end);
    else
      return Str.make(start + ".." + end);
  }

  public Type type() { return Sys.RangeType; }

//////////////////////////////////////////////////////////////////////////
// Slice Utils
//////////////////////////////////////////////////////////////////////////

  final int start(int size)
  {
    int x = start.intValue();
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
    int x = end.intValue();
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

  private Long start, end;
  private boolean exclusive;
}
