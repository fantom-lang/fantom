//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 Oct 11  Brian Frank  Creation
//
package fan.util;

import fan.sys.*;

public final class BoolArray extends FanObj
{

  public static BoolArray make(long size) { return new BoolArray(size); }

  public final Type typeof() { return typeof; }
  private static final Type typeof = Type.find("util::BoolArray");

  BoolArray(long size)
  {
    this.size  = size;
    this.words = new int[((int)size >> 0x5) + 1];
  }

  public final long size() { return size; }

  public final boolean get(long index)
  {
    int i = (int)index;
    return (words[i>>0x5] & (1 << (i & 0x1F))) != 0;
  }

  public final void set(long index, boolean v)
  {
    int i = (int)index;
    int mask = 1 << (i & 0x1F);
    if (v)
      words[i>>0x5] |= mask;
    else
      words[i>>0x5] &= ~mask;
  }

  public final boolean getAndSet(long index, boolean v)
  {
    int i = (int)index;
    int mask = 1 << (i & 0x1F);
    boolean prev = (words[i>>0x5] & mask) != 0;
    if (v)
      words[i>>0x5] |= mask;
    else
      words[i>>0x5] &= ~mask;
    return prev;
  }

  public BoolArray fill(boolean val) { return fill(val, null); }
  public BoolArray fill(boolean val, Range range)
  {
    if (range == null && !val) return clear();
    int start, end;
    int size = (int)size();
    if (range == null) { start = 0; end = size-1; }
    else  { start = range.startIndex(size); end = range.endIndex(size); }
    for (int i=start; i<=end; ++i) set(i, val);
    return this;
  }

  public BoolArray clear()
  {
    for (int i=0; i<words.length; ++i) words[i] = 0;
    return this;
  }

  public void eachTrue(Func func)
  {
    for (int i=0; i<words.length; ++i)
    {
      if (words[i] == 0) continue;
      for (int j=0; j<32; ++j)
      {
        int index = (i << 0x05) + j;
        if (get(index)) func.call(Long.valueOf(index));
      }
    }
  }

  public BoolArray copyFrom(BoolArray that)
  {
    System.arraycopy(that.words, 0, this.words, 0, that.words.length);
    return this;
  }

  private final long size;
  private final int[] words;
}