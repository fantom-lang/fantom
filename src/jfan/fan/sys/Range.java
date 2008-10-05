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
    return makeInclusive(Int.make(start), Int.make(end));
  }

  public static final Range makeInclusive(Int start, Int end)
  {
    return new Range(start, end, false);
  }

  public static final Range makeExclusive(int start, int end)
  {
    return makeExclusive(Int.make(start), Int.make(end));
  }

  public static final Range makeExclusive(Int start, Int end)
  {
    return new Range(start, end, true);
  }

  public static final Range make(Int start, Int end, Boolean exclusive)
  {
    return new Range(start, end, exclusive);
  }

  private Range(Int start, Int end, boolean exclusive)
  {
    if (start == null || end == null) throw NullErr.make().val;
    this.start = start;
    this.end = end;
    this.exclusive = exclusive;
  }

//////////////////////////////////////////////////////////////////////////
// Range
//////////////////////////////////////////////////////////////////////////

  public final Int start()
  {
    return start;
  }

  public final Int end()
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

  public final Boolean contains(Int i)
  {
    if (exclusive)
      return start.val <= i.val && i.val < end.val;
    else
      return start.val <= i.val && i.val <= end.val;
  }

  public final void each(Func f)
  {
    int start = (int)this.start.val;
    int end = (int)this.end.val;
    if (!exclusive) end++;
    for (int i=start; i<end; ++i)
      f.call1(Int.make(i));
  }

  public final List toList()
  {
    int start = (int)this.start.val;
    int end = (int)this.end.val;
    List acc = new List(Sys.IntType);
    if (start < end)
    {
      if (exclusive) --end;
      acc.capacity(Int.make(end-start));
      for (int i=start; i<=end; ++i)
        acc.add(Int.make(i));
    }
    else
    {
      if (exclusive) ++end;
      acc.capacity(Int.make(start-end));
      for (int i=start; i>=end; --i)
        acc.add(Int.make(i));
    }
    return acc;
  }

  public final Boolean _equals(Object object)
  {
    if (object instanceof Range)
    {
      Range that = (Range)object;
      return this.start.val == that.start.val &&
             this.end.val == that.end.val &&
             this.exclusive == that.exclusive;
    }
    return false;
  }

  public final int hashCode()
  {
    return start.hashCode() ^ end.hashCode();
  }

  public final Int hash()
  {
    return Int.make(start.val ^ end.val);
  }

  public Str toStr()
  {
    if (exclusive)
      return Str.make(start.toStr().val + "..." + end.toStr().val);
    else
      return Str.make(start.toStr().val + ".." + end.toStr().val);
  }

  public Type type() { return Sys.RangeType; }

//////////////////////////////////////////////////////////////////////////
// Slice Utils
//////////////////////////////////////////////////////////////////////////

  final int start(int size)
  {
    int x = (int)start.val;
    if (x < 0) x = size + x;
    if (x > size) throw IndexErr.make(this).val;
    return x;
  }

  final long start(long size)
  {
    long x = start.val;
    if (x < 0) x = size + x;
    if (x > size) throw IndexErr.make(this).val;
    return x;
  }

  final int end(int size)
  {
    int x = (int)end.val;
    if (x < 0) x = size + x;
    if (exclusive) x--;
    if (x >= size) throw IndexErr.make(this).val;
    return x;
  }

  final long end(long size)
  {
    long x = end.val;
    if (x < 0) x = size + x;
    if (exclusive) x--;
    if (x >= size) throw IndexErr.make(this).val;
    return x;
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private Int start, end;
  private boolean exclusive;
}