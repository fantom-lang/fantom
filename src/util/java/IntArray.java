//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 Oct 11  Brian Frank  Creation
//
package fan.util;

import fan.sys.*;
import java.util.Arrays;

public abstract class IntArray extends FanObj
{

  public static IntArray makeS1(long size) { return new S1((int)size); }
  public static IntArray makeU1(long size) { return new U1((int)size); }
  public static IntArray makeS2(long size) { return new S2((int)size); }
  public static IntArray makeU2(long size) { return new U2((int)size); }
  public static IntArray makeS4(long size) { return new S4((int)size); }
  public static IntArray makeU4(long size) { return new U4((int)size); }
  public static IntArray makeS8(long size) { return new S8((int)size); }

  public final Type typeof() { return typeof; }
  private static final Type typeof = Type.find("util::IntArray");

  public abstract String kind();
  public abstract Object array();

  public abstract long size();
  public abstract long get(long i);
  public abstract void set(long i, long v);

  public IntArray copyFrom(IntArray that) { return copyFrom(that, null, 0); }
  public IntArray copyFrom(IntArray that, Range thatRange) { return copyFrom(that, thatRange, 0); }
  public IntArray copyFrom(IntArray that, Range thatRange, long thisOffset)
  {
    if (kind() != that.kind()) throw ArgErr.make("Mismatched arrays: " + kind() + " != " + that.kind());
    int start, end;
    int thatSize = (int)that.size();
    if (thatRange == null) { start = 0; end = thatSize-1; }
    else  { start = thatRange.startIndex(thatSize); end  = thatRange.endIndex(thatSize); }
    System.arraycopy(that.array(), start, this.array(), (int)thisOffset, end-start+1);
    return this;
  }

  public IntArray fill(long val) { return fill(val, null); }
  public IntArray fill(long val, Range range)
  {
    int start, end;
    int size = (int)size();
    if (range == null) { start = 0; end = size-1; }
    else  { start = range.startIndex(size); end = range.endIndex(size); }
    for (int i=start; i<=end; ++i) set(i, val);
    return this;
  }

  public IntArray sort() { return sort(null); }
  public IntArray sort(Range range)
  {
    int start, end;
    int size = (int)size();
    if (range == null) { start = 0; end = size-1; }
    else { start = range.startIndex(size); end = range.endIndex(size); }
    doSort(start, end+1);
    return this;
  }
  abstract void doSort(int from, int to);

  static class S1 extends IntArray
  {
    S1(int size) { array = new byte[size]; }
    public String kind() { return "S1"; }
    public final long size() { return array.length; }
    public long get(long i) { return array[(int)i]; }
    public final void set(long i, long v) { array[(int)i] = (byte)v; }
    public final Object array() { return array; }
    final void doSort(int from, int to) { Arrays.sort(array, from, to); }
    final byte[] array;
  }

  static class U1 extends S1
  {
    U1(int size) { super(size); }
    public final String kind() { return "U1"; }
    public final long get(long i) { return array[(int)i] & 0xFFL; }
  }

  static class S2 extends IntArray
  {
    S2(int size) { array = new short[size]; }
    public String kind() { return "S2"; }
    public final long size() { return array.length; }
    public long get(long i) { return array[(int)i]; }
    public final void set(long i, long v) { array[(int)i] = (short)v; }
    public final Object array() { return array; }
    final void doSort(int from, int to) { Arrays.sort(array, from, to); }
    final short[] array;
  }

  static class U2 extends S2
  {
    U2(int size) { super(size); }
    public final String kind() { return "U2"; }
    public final long get(long i) { return array[(int)i] & 0xFFFFL; }
  }

  static class S4 extends IntArray
  {
    S4(int size) { array = new int[size]; }
    public String kind() { return "S4"; }
    public final long size() { return array.length; }
    public long get(long i) { return array[(int)i]; }
    public final void set(long i, long v) { array[(int)i] = (int)v; }
    public final Object array() { return array; }
    final void doSort(int from, int to) { Arrays.sort(array, from, to); }
    final int[] array;
  }

  static class U4 extends S4
  {
    U4(int size) { super(size); }
    public final String kind() { return "U4"; }
    public final long get(long i) { return array[(int)i] & 0xFFFFFFFFL; }
  }

  static class S8 extends IntArray
  {
    S8(int size) { array = new long[size]; }
    public final String kind() { return "S8"; }
    public final long size() { return array.length; }
    public final long get(long i) { return array[(int)i]; }
    public final void set(long i, long v) { array[(int)i] = v; }
    public final Object array() { return array; }
    final void doSort(int from, int to) { Arrays.sort(array, from, to); }
    private final long[] array;
  }

}