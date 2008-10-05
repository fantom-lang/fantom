//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   4 Dec 05  Brian Frank  Creation
//
package fan.sys;

import java.lang.Thread;
import java.util.Arrays;
import java.util.Collection;
import java.util.Comparator;
import java.util.HashMap;
import fanx.serial.*;
import fanx.util.*;

/**
 * List
 */
public final class List
  extends FanObj
  implements Literal
{

//////////////////////////////////////////////////////////////////////////
// Constructors
//////////////////////////////////////////////////////////////////////////

  public static List make(Type of, Long capacity)
  {
    return new List(of, capacity.intValue());
  }

  public static List makeObj(Long capacity)
  {
    return new List(Sys.ObjType, capacity.intValue());
  }

  public List(Type of, Object[] values)
  {
    if (of == null) { Thread.dumpStack(); throw new NullErr().val; }
    this.of = of;
    this.values = values;
    this.size = values.length;
  }

  public List(Type of, Object[] values, int size)
  {
    if (of == null) { Thread.dumpStack(); throw new NullErr().val; }
    this.of = of;
    this.values = values;
    this.size = size;
  }

  public List(Type of, int capacity)
  {
    if (of == null) { Thread.dumpStack(); throw new NullErr().val; }
    this.of = of;
    this.values = capacity == 0 ? empty : new Object[capacity];
  }

  public List(Type of)
  {
    if (of == null) { Thread.dumpStack(); throw new NullErr().val; }
    this.of = of;
    this.values = empty;
  }

  public List(Type of, Collection collection)
  {
    if (of == null) { Thread.dumpStack(); throw new NullErr().val; }
    this.of = of;
    this.size = collection.size();
    this.values = collection.toArray(new Object[size]);
  }

  public List(String[] values)
  {
    this.of = Sys.StrType;
    this.values = new Object[values.length];
    this.size = values.length;
    for (int i=0; i<values.length; ++i)
      this.values[i] = Str.make(values[i]);
  }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  public final Type type()
  {
    return of.toListOf();
  }

  public final Type of()
  {
    return of;
  }

//////////////////////////////////////////////////////////////////////////
// Access
//////////////////////////////////////////////////////////////////////////

  public final Boolean isEmpty()
  {
    return size == 0;
  }

  public final Long size()
  {
    return Long.valueOf(size);
  }

  public final void size(Long s)
  {
    modify();
    int newSize = s.intValue();
    if (newSize > size)
    {
      Object[] temp = new Object[newSize];
      System.arraycopy(values, 0, temp, 0, size);
      values = temp;
      size = newSize;
    }
    else
    {
      Object[] temp = new Object[newSize];
      System.arraycopy(values, 0, temp, 0, newSize);
      values = temp;
      size = newSize;
    }
  }

  public final Long capacity()
  {
    return Long.valueOf(values.length);
  }

  public final void capacity(Long c)
  {
    modify();
    int newCapacity = c.intValue();
    if (newCapacity < size) throw ArgErr.make("capacity < size").val;
    Object[] temp = new Object[newCapacity];
    System.arraycopy(values, 0, temp, 0, size);
    values = temp;
  }

  public final Object get(Long index)
  {
    try
    {
      int i = index.intValue();
      if (i < 0) i = size + i;
      if (i >= size) throw IndexErr.make(index).val;
      return values[i];
    }
    catch (ArrayIndexOutOfBoundsException e)
    {
      throw IndexErr.make(index).val;
    }
  }

  public final List slice(Range r)
  {
    try
    {
      int s = r.start(size);
      int e = r.end(size);
      int n = e - s + 1;
      if (n < 0) throw IndexErr.make(r).val;

      List acc = new List(of, n);
      acc.size = n;
      System.arraycopy(values, s, acc.values, 0, n);
      return acc;
    }
    catch (ArrayIndexOutOfBoundsException e)
    {
      throw IndexErr.make(r).val;
    }
  }

  public final Boolean contains(Object value)
  {
    return index(value) != null;
  }

  public final Boolean containsSame(Object value)
  {
    return indexSame(value) != null;
  }

  public final Boolean containsAll(List list)
  {
    for (int i=0; i<list.sz(); ++i)
      if (index(list.get(i)) == null)
        return false;
    return true;
  }

  public final Boolean containsAllSame(List list)
  {
    for (int i=0; i<list.sz(); ++i)
      if (indexSame(list.get(i)) == null)
        return false;
    return true;
  }

  public final Long index(Object value) { return index(value, 0L); }
  public final Long index(Object value, Long off)
  {
    if (size == 0) return null;
    int start = off.intValue();
    if (start < 0) start = size + start;
    if (start >= size) throw IndexErr.make(off).val;

    try
    {
      if (value == null)
      {
        for (int i=start; i<size; ++i)
          if (values[i] == null)
            return Long.valueOf(i);
      }
      else
      {
        for (int i=start; i<size; ++i)
        {
          Object obj = values[i];
          if (obj != null && obj.equals(value))
            return Long.valueOf(i);
        }
      }
      return null;
    }
    catch (ArrayIndexOutOfBoundsException e)
    {
      throw IndexErr.make(off).val;
    }
  }

  public final Long indexSame(Object value) { return indexSame(value, 0L); }
  public final Long indexSame(Object value, Long off)
  {
    if (size == 0) return null;
    int start = off.intValue();
    if (start < 0) start = size + start;
    if (start >= size) throw IndexErr.make(off).val;

    try
    {
      for (int i=start; i<size; ++i)
        if (value == values[i])
          return Long.valueOf(i);
      return null;
    }
    catch (ArrayIndexOutOfBoundsException e)
    {
      throw IndexErr.make(off).val;
    }
  }

  public final Object first()
  {
    if (size == 0) return null;
    return values[0];
  }

  public final Object last()
  {
    if (size == 0) return null;
    return values[size-1];
  }

  public final List dup()
  {
    Object[] dup = new Object[size];
    System.arraycopy(values, 0, dup, 0, size);
    return new List(of, dup);
  }

  public final Long hash()
  {
    long hash = 33;
    for (int i=0; i<size; ++i)
    {
      Object obj = values[i];
      if (obj != null) hash ^= hash(obj).longValue();
    }
    return Long.valueOf(hash);
  }

  public final Boolean _equals(Object that)
  {
    if (that instanceof List)
    {
      List x = (List)that;
      if (!of.equals(x.of)) return false;
      if (size != x.size) return false;
      for (int i=0; i<size; ++i)
        if (!OpUtil.compareEQ(values[i], x.values[i])) return false;
      return true;
    }
    return false;
  }

//////////////////////////////////////////////////////////////////////////
// Modification
//////////////////////////////////////////////////////////////////////////

  public final List set(Long index, Object value)
  {
    modify();
    try
    {
      int i = index.intValue();
      if (i < 0) i = size + i;
      if (i >= size) throw IndexErr.make(index).val;
      values[i] = value;
      return this;
    }
    catch (ArrayIndexOutOfBoundsException e)
    {
      throw IndexErr.make(index).val;
    }
  }

  public final List add(Object value)
  {
    // modify in insert(int, Obj)
    return insert(size, value);
  }

  public final List addAll(List list)
  {
    // modify in insertAll(int, List)
    return insertAll(size, list);
  }

  public final List insert(Long index, Object value)
  {
    // modify in insert(int, Obj)
    int i = index.intValue();
    if (i < 0) i = size + i;
    if (i > size) throw IndexErr.make(index).val;
    return insert(i, value);
  }

  private List insert(int i, Object value)
  {
    modify();
    if (values.length <= size)
      grow(size+1);
    if (i < size)
      System.arraycopy(values, i, values, i+1, size-i);
    values[i] = value;
    size++;
    return this;
  }

  public final List insertAll(Long index, List list)
  {
    // modify in insertAll(int, List)
    int i = index.intValue();
    if (i < 0) i = size + i;
    if (i > size) throw IndexErr.make(index).val;
    return insertAll(i, list);
  }

  private List insertAll(int i, List list)
  {
    modify();
    if (list.size == 0) return this;
    if (values.length < size+list.size)
      grow(size+list.size);
    if (i < size)
      System.arraycopy(values, i, values, i+list.size, size-i);
    System.arraycopy(list.values, 0, values, i, list.size);
    size+=list.size;
    return this;
  }

  public final Object remove(Object val)
  {
    // modify in removeAt(Int)
    Long index = index(val);
    if (index == null) return null;
    return removeAt(index);
  }

  public final Object removeSame(Object val)
  {
    // modify in removeAt(Int)
    Long index = indexSame(val);
    if (index == null) return null;
    return removeAt(index);
  }

  public final Object removeAt(Long index)
  {
    modify();
    int i = index.intValue();
    if (i < 0) i = size + i;
    if (i >= size) throw IndexErr.make(index).val;
    Object old = values[i];
    if (i < size-1)
      System.arraycopy(values, i+1, values, i, size-i-1);
    size--;
    return old;
  }

  public final List removeRange(Range r)
  {
    modify();
    int s = r.start(size);
    int e = r.end(size);
    int n = e - s + 1;
    if (n < 0) throw IndexErr.make(r).val;

    int shift = size-s-n;
    if (shift > 0) System.arraycopy(values, s+n, values, s, shift);
    size -= n;
    for (int i=size; i<size+n; ++i) values[i] = null;
    return this;
  }

  private void grow(int desiredSize)
  {
    int desired = (int)desiredSize;
    if (desired < 1) throw Err.make("desired " + desired + " < 1").val;
    int newSize = Math.max(desired, size*2);
    if (newSize < 10) newSize = 10;
    Object[] temp = new Object[newSize];
    System.arraycopy(values, 0, temp, 0, size);
    values = temp;
  }

  public final List trim()
  {
    modify();
    if (size == 0)
    {
      values = empty;
    }
    else if (values.length != size)
    {
      Object[] temp = new Object[size];
      System.arraycopy(values, 0, temp, 0, size);
      values = temp;
    }
    return this;
  }

  public final List clear()
  {
    modify();
    for (int i=0; i<size; ++i)
      values[i] = null;
    size = 0;
    return this;
  }

//////////////////////////////////////////////////////////////////////////
// Stack
//////////////////////////////////////////////////////////////////////////

  public final Object peek()
  {
    if (size == 0) return null;
    return values[size-1];
  }

  public final Object pop()
  {
    // modify in removeAt()
    if (size == 0) return null;
    return removeAt(FanInt.NegOne);
  }

  public final List push(Object obj)
  {
    // modify in add()
    return add(obj);
  }

//////////////////////////////////////////////////////////////////////////
// Iterators
//////////////////////////////////////////////////////////////////////////

  public final void each(Func f)
  {
    for (int i=0; i<size; ++i)
      f.call2(values[i], Long.valueOf(i));
  }

  public final void eachr(Func f)
  {
    for (int i=size-1; i>=0; --i)
      f.call2(values[i], Long.valueOf(i));
  }

  public final Object eachBreak(Func f)
  {
    for (int i=0; i<size; ++i)
    {
      Object r = f.call2(values[i], Long.valueOf(i));
      if (r != null) return r;
    }
    return null;
  }

  public final Object find(Func f)
  {
    for (int i=0; i<size; ++i)
      if (f.call2(values[i], Long.valueOf(i)) == Boolean.TRUE)
        return values[i];
    return null;
  }

  public final Long findIndex(Func f)
  {
    for (int i=0; i<size; ++i)
    {
      Long pos = Long.valueOf(i);
      if (f.call2(values[i], pos) == Boolean.TRUE)
        return pos;
    }
    return null;
  }

  public final List findAll(Func f)
  {
    List acc = new List(of, size);
    for (int i=0; i<size; ++i)
      if (f.call2(values[i], Long.valueOf(i)) == Boolean.TRUE)
        acc.add(values[i]);
    return acc;
  }

  public final List findType(Type t)
  {
    List acc = new List(t, size);
    for (int i=0; i<size; ++i)
    {
      Object item = values[i];
      if (item != null && type(item).is(t))
        acc.add(item);
    }
    return acc;
  }

  public final List exclude(Func f)
  {
    List acc = new List(of, size);
    for (int i=0; i<size; ++i)
      if (f.call2(values[i], Long.valueOf(i)) != Boolean.TRUE)
        acc.add(values[i]);
    return acc;
  }

  public final Boolean any(Func f)
  {
    for (int i=0; i<size; ++i)
      if (f.call2(values[i], Long.valueOf(i)) == Boolean.TRUE)
        return true;
    return false;
  }

  public final Boolean all(Func f)
  {
    for (int i=0; i<size; ++i)
      if (f.call2(values[i], Long.valueOf(i)) != Boolean.TRUE)
        return false;
    return true;
  }

  public final Object reduce(Object reduction, Func f)
  {
    for (int i=0; i<size; ++i)
      reduction = f.call3(reduction, values[i], Long.valueOf(i));
    return reduction;
  }

  public final List map(List acc, Func f)
  {
    if (acc.size == 0) acc.capacity(size());
    for (int i=0; i<size; ++i)
      acc.add(f.call2(values[i], Long.valueOf(i)));
    return acc;
  }

  public final Object max() { return max(null); }
  public final Object max(Func f)
  {
    if (size == 0) return null;
    Comparator c = toComparator(f);
    Object max = values[0];
    for (int i=1; i<size; ++i)
      if (c.compare(values[i], max) > 0)
        max = values[i];
    return max;
  }

  public final Object min() { return min(null); }
  public final Object min(Func f)
  {
    if (size == 0) return null;
    Comparator c = toComparator(f);
    Object min = values[0];
    for (int i=1; i<size; ++i)
      if (c.compare(values[i], min) < 0)
        min = values[i];
    return min;
  }

  public final List unique()
  {
    HashMap dups = new HashMap(size*3);
    List acc = new List(of, size);
    for (int i=0; i<size; ++i)
    {
      Object v = values[i];
      if (dups.get(v) == null)
      {
        dups.put(v, this);
        acc.add(v);
      }
    }
    return acc;
  }

  public final List union(List that)
  {
    int capacity = size + that.size;
    HashMap dups = new HashMap(capacity*3);
    List acc = new List(of, capacity);

    // first me
    for (int i=0; i<size; ++i)
    {
      Object v = values[i];
      if (dups.get(v) == null)
      {
        dups.put(v, this);
        acc.add(v);
      }
    }

    // then him
    for (int i=0; i<that.size; ++i)
    {
      Object v = that.values[i];
      if (dups.get(v) == null)
      {
        dups.put(v, this);
        acc.add(v);
      }
    }

    return acc;
  }

  public final List intersection(List that)
  {
    // put other list into map
    HashMap dups = new HashMap(that.size*3);
    for (int i=0; i<that.size; ++i)
      dups.put(that.values[i], this);

    // now walk this list and accumulate
    // everything found in the dups map
    List acc = new List(of, size);
    for (int i=0; i<size; ++i)
    {
      Object v = values[i];
      if (dups.get(v) != null)
      {
        acc.add(v);
        dups.remove(v);
      }
    }
    return acc;
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  public final List sort() { return sort(null); }
  public final List sort(final Func f)
  {
    modify();
    Arrays.sort(values, 0, size, toComparator(f));
    return this;
  }

  public final List sortr() { return sortr(null); }
  public final List sortr(final Func f)
  {
    modify();
    Arrays.sort(values, 0, size, toReverseComparator(f));
    return this;
  }

  public final Long binarySearch(Object key) { return binarySearch(key, null); }
  public final Long binarySearch(Object key, Func f)
  {
    Comparator c = toComparator(f);
    Object[] values = this.values;
    int low = 0, high = size-1;
    while (low <= high)
    {
      int probe = (low + high) >> 1;
      int cmp = c.compare(values[probe], key);
      if (cmp < 0)
        low = probe + 1;
      else if (cmp > 0)
        high = probe - 1;
      else
        return Long.valueOf(probe);
    }
    return Long.valueOf(-(low + 1));
  }

  public final List reverse()
  {
    modify();
    Object[] values = this.values;
    int size = this.size;
    int mid   = size/2;
    for (int i=0; i<mid; ++i)
    {
      Object a = values[i];
      Object b = values[size-i-1];
      values[i] = b;
      values[size-i-1] = a;
    }
    return this;
  }

  public final List swap(Long a, Long b)
  {
    // modify in set()
    Object temp = get(a);
    set(a, get(b));
    set(b, temp);
    return this;
  }

  public final List flatten()
  {
    List acc = new List(Sys.ObjType, size*2);
    doFlatten(acc);
    return acc;
  }

  private void doFlatten(List acc)
  {
    for (int i=0; i<size; ++i)
    {
      Object item = values[i];
      if (item instanceof List)
        ((List)item).doFlatten(acc);
      else
        acc.add(item);
    }
  }

//////////////////////////////////////////////////////////////////////////
// Conversion
//////////////////////////////////////////////////////////////////////////

  public final Str join() { return join(Str.Empty, null); }
  public final Str join(Str sep) { return join(sep, null); }
  public final Str join(Str sep, Func f)
  {
    if (size == 0) return Str.Empty;

    if (size == 1)
    {
      Object v = values[0];
      if (f != null) return (Str)f.call2(v, 0L);
      if (v == null) return Str.nullStr;
      return toStr(v);
    }

    StringBuilder s = new StringBuilder(32+size*32);
    for (int i=0; i<size; ++i)
    {
      if (i > 0) s.append(sep.val);
      if (f == null)
        s.append(values[i]);
      else
        s.append(f.call2(values[i], Long.valueOf(i)));
    }
    return Str.make(s.toString());
  }

  public final Str toStr()
  {
    if (size == 0) return Str.make("[,]");
    StringBuilder s = new StringBuilder(32+size*32);
    s.append("[");
    for (int i=0; i<size; ++i)
    {
      if (i > 0) s.append(", ");
      s.append(values[i]);
    }
    s.append("]");
    return Str.make(s.toString());
  }

  public final void encode(ObjEncoder out)
  {
    // route back to obj encoder
    out.writeList(this);
  }

//////////////////////////////////////////////////////////////////////////
// Runtime Utils
//////////////////////////////////////////////////////////////////////////

  public final int sz()
  {
    return size;
  }

  public final Object get(int i)
  {
    try
    {
      if (i >= size) throw IndexErr.make(""+i).val;
      return values[i];
    }
    catch (ArrayIndexOutOfBoundsException e)
    {
      throw IndexErr.make(""+i).val;
    }
  }

  public final Object[] toArray()
  {
    if (values.length == size) return values;
    Object[] r = new Object[size];
    System.arraycopy(values, 0, r, 0, size);
    return r;
  }

  public final Object[] toArray(Object[] a)
  {
    try
    {
      System.arraycopy(values, 0, a, 0, size);
      return a;
    }
    catch (ArrayIndexOutOfBoundsException e)
    {
      throw IndexErr.make().val;
    }
  }

  public final Object[] toArray(Object[] a, int start, int len)
  {
    try
    {
      System.arraycopy(values, start, a, 0, len);
      return a;
    }
    catch (ArrayIndexOutOfBoundsException e)
    {
      throw IndexErr.make().val;
    }
  }

  public final Object[] copyInto(Object[] a, int off, int len)
  {
    try
    {
      System.arraycopy(values, 0, a, off, len);
      return a;
    }
    catch (ArrayIndexOutOfBoundsException e)
    {
      throw IndexErr.make().val;
    }
  }

  public final String[] toStrings()
  {
    String[] a = new String[size];
    for (int i=0; i<size; ++i)
    {
      Object obj = get(i);
      if (obj == null) a[i] = "null";
      else a[i] = toStr(obj).val;
    }
    return a;
  }

  public final int[] toInts()
  {
    int[] a = new int[size];
    for (int i=0; i<size; ++i) a[i] = ((Long)get(i)).intValue();
    return a;
  }

//////////////////////////////////////////////////////////////////////////
// Comparators
//////////////////////////////////////////////////////////////////////////

  static Comparator toComparator(final Func f)
  {
    if (f == null) return defaultComparator;
    return new Comparator()
    {
      public int compare(Object a, Object b) { return ((Long)f.call2(a, b)).intValue(); }
    };
  }
  static final Comparator defaultComparator = new Comparator()
  {
    public int compare(Object a, Object b) { return OpUtil.compare(a, b).intValue(); }
  };

  static Comparator toReverseComparator(final Func f)
  {
    if (f == null) return defaultReverseComparator;
    return new Comparator()
    {
      public int compare(Object a, Object b) { return ((Long)f.call2(b, a)).intValue(); }
    };
  }
  static final Comparator defaultReverseComparator = new Comparator()
  {
    public int compare(Object a, Object b) { return OpUtil.compare(b, a).intValue(); }
  };

//////////////////////////////////////////////////////////////////////////
// Readonly
//////////////////////////////////////////////////////////////////////////

  public final Boolean isRW()
  {
    return !readonly;
  }

  public final Boolean isRO()
  {
    return readonly;
  }

  public final List rw()
  {
    if (!readonly) return this;

    Object[] temp = new Object[size];
    System.arraycopy(values, 0, temp, 0, size);

    List rw = new List(of);
    rw.values   = temp;
    rw.size     = size;
    rw.readonly = false;
    rw.readonlyList = this;
    return rw;
  }

  public final List ro()
  {
    if (readonly) return this;
    if (readonlyList == null)
    {
      List ro = new List(of);
      ro.values   = values;
      ro.size     = size;
      ro.readonly = true;
      readonlyList = ro;
    }
    return readonlyList;
  }

  public final Boolean isImmutable()
  {
    return immutable;
  }

  public final List toImmutable()
  {
    if (immutable) return this;

    // make safe copy
    Object[] temp = new Object[size];
    for (int i=0; i<size; ++i)
    {
      Object item = values[i];
      if (item != null)
      {
        if (item instanceof List)
          item = ((List)item).toImmutable();
        else if (item instanceof Map)
          item = ((Map)item).toImmutable();
        else if (!isImmutable(item))
          throw NotImmutableErr.make("Item [" + i + "] not immutable " + type(item)).val;
      }
      temp[i] = item;
    }

    // return new immutable list
    List ro = new List(of, temp);
    ro.readonly = true;
    ro.immutable = true;
    return ro;
  }

  private void modify()
  {
    // if readonly then throw readonly exception
    if (readonly)
      throw ReadonlyErr.make("List is readonly").val;

    // if we have a cached readonlyList, then detach
    // it so it remains immutable
    if (readonlyList != null)
    {
      Object[] temp = new Object[size];
      System.arraycopy(values, 0, temp, 0, size);
      readonlyList.values = temp;
      readonlyList = null;
    }
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private static final Object[] empty = new Object[0];

  private Type of;
  private Object[] values;
  private int size;
  private boolean readonly;
  private boolean immutable;
  private List readonlyList;

}
