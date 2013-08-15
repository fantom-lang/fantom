//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   4 Dec 05  Brian Frank  Creation
//
package fan.sys;

import java.lang.Thread;
import java.lang.reflect.Array;
import java.math.BigDecimal;
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

  public static List make(Type of, long capacity)
  {
    return new List(of, (int)capacity);
  }

  public static List makeObj(long capacity)
  {
    return new List(Sys.ObjType.toNullable(), (int)capacity);
  }

  public static List make(Type of, Object[] values)
  {
    if (values == null) return null;
    return new List(of, values);
  }

  public List(Type of, Object[] values)
  {
    if (of == null) { Thread.dumpStack(); throw NullErr.make(); }
    this.of = of;
    this.values = values;
    this.size = values.length;
  }

  public List(Type of, Object[] values, int size)
  {
    if (of == null) { Thread.dumpStack(); throw NullErr.make(); }
    this.of = of;
    this.values = values;
    this.size = size;
  }

  public List(Type of, int capacity)
  {
    if (of == null) { Thread.dumpStack(); throw NullErr.make(); }
    this.of = of;
    this.values = capacity == 0 ? empty : newArray(capacity);
  }

  public List(Type of)
  {
    if (of == null) { Thread.dumpStack(); throw NullErr.make(); }
    this.of = of;
    this.values = empty;
  }

  public List(Type of, Collection collection)
  {
    if (of == null) { Thread.dumpStack(); throw NullErr.make(); }
    this.of = of;
    this.size = collection.size();
    this.values = collection.toArray(newArray(size));
  }

  public List(String[] values)
  {
    this.of = Sys.StrType;
    this.size = values.length;
    this.values = values;
  }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  public final Type typeof()
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

  public final boolean isEmpty()
  {
    return size == 0;
  }

  public final long size()
  {
    return size;
  }

  public final void size(long s)
  {
    modify();
    int newSize = (int)s;
    if (newSize > size)
    {
      if (!of.isNullable()) throw ArgErr.make("Cannot grow non-nullable list of " + of);
      if (newSize > values.length)
      {
        Object[] temp = newArray(newSize);
        System.arraycopy(values, 0, temp, 0, size);
        values = temp;
      }
      else
      {
        for (int i=size; i<newSize; ++i) values[i] = null;
      }
      size = newSize;
    }
    else
    {
      // null out removed items for GC
      for (int i=newSize; i<size; ++i) values[i] = null;
      size = newSize;
    }
  }

  public final long capacity()
  {
    return values.length;
  }

  public final void capacity(long c)
  {
    modify();
    int newCapacity = (int)c;
    if (newCapacity < size) throw ArgErr.make("capacity < size");
    Object[] temp = newArray(newCapacity);
    System.arraycopy(values, 0, temp, 0, size);
    values = temp;
  }

  public final Object get(long index)
  {
    try
    {
      int i = (int)index;
      if (i < 0) i = size + i;
      if (i >= size) throw IndexErr.make(index);
      return values[i];
    }
    catch (ArrayIndexOutOfBoundsException e)
    {
      throw IndexErr.make(index);
    }
  }

  public final Object getSafe(long index) { return getSafe(index, null); }
  public final Object getSafe(long index, Object def)
  {
    if (index < 0) index = size + index;
    if (index >= size || index < 0) return def;
    return values[(int)index];
  }

  public final List getRange(Range r)
  {
    try
    {
      int s = r.startIndex(size);
      int e = r.endIndex(size);
      int n = e - s + 1;
      if (n < 0) throw IndexErr.make(r);

      List acc = new List(of, n);
      acc.size = n;
      System.arraycopy(values, s, acc.values, 0, n);
      return acc;
    }
    catch (ArrayIndexOutOfBoundsException e)
    {
      throw IndexErr.make(r);
    }
  }

  public final boolean contains(Object value)
  {
    return index(value) != null;
  }

  public final boolean containsAll(List list)
  {
    for (int i=0; i<list.sz(); ++i)
      if (index(list.get(i)) == null)
        return false;
    return true;
  }

  public final boolean containsAny(List list)
  {
    for (int i=0; i<list.sz(); ++i)
      if (index(list.get(i)) != null)
        return true;
    return false;
  }

  public final Long index(Object value) { return index(value, 0L); }
  public final Long index(Object value, long off)
  {
    if (size == 0) return null;
    int start = (int)off;
    if (start < 0) start = size + start;
    if (start >= size) throw IndexErr.make(off);

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
      throw IndexErr.make(off);
    }
  }

  public final Long indexr(Object value) { return indexr(value, -1L); }
  public final Long indexr(Object value, long off)
  {
    if (size == 0) return null;
    int start = (int)off;
    if (start < 0) start = size + start;
    if (start >= size) throw IndexErr.make(off);

    try
    {
      if (value == null)
      {
        for (int i=start; i>=0; --i)
          if (values[i] == null)
            return Long.valueOf(i);
      }
      else
      {
        for (int i=start; i>=0; --i)
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
      throw IndexErr.make(off);
    }
  }

  public final Long indexSame(Object value) { return indexSame(value, 0L); }
  public final Long indexSame(Object value, long off)
  {
    if (size == 0) return null;
    int start = (int)off;
    if (start < 0) start = size + start;
    if (start >= size) throw IndexErr.make(off);

    try
    {
      for (int i=start; i<size; ++i)
        if (value == values[i])
          return Long.valueOf(i);
      return null;
    }
    catch (ArrayIndexOutOfBoundsException e)
    {
      throw IndexErr.make(off);
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
    Object[] dup = newArray(size);
    System.arraycopy(values, 0, dup, 0, size);
    return new List(of, dup);
  }

  public final long hash()
  {
    long hash = 33;
    for (int i=0; i<size; ++i)
    {
      Object obj = values[i];
      hash = (31*hash) + (obj == null ? 0 : hash(obj));
    }
    return hash;
  }

  public final boolean equals(Object that)
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

  public final List set(long index, Object value)
  {
    modify();
    try
    {
      int i = (int)index;
      if (i < 0) i = size + i;
      if (i >= size) throw IndexErr.make(index);
      values[i] = value;
      return this;
    }
    catch (ArrayIndexOutOfBoundsException e)
    {
      throw IndexErr.make(index);
    }
    catch (ArrayStoreException e)
    {
      throw CastErr.make("Setting '" + FanObj.typeof(value) + "' into '" + of + "[]'");
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

  public final List insert(long index, Object value)
  {
    // modify in insert(int, Obj)
    int i = (int)index;
    if (i < 0) i = size + i;
    if (i > size) throw IndexErr.make(index);
    return insert(i, value);
  }

  private List insert(int i, Object value)
  {
    try
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
    catch (ArrayStoreException e)
    {
      throw CastErr.make("Adding '" + FanObj.typeof(value) + "' into '" + of + "[]'");
    }
  }

  public final List insertAll(long index, List list)
  {
    // modify in insertAll(int, List)
    int i = (int)index;
    if (i < 0) i = size + i;
    if (i > size || i < 0) throw IndexErr.make(index);
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

  public final Object removeAt(long index)
  {
    modify();
    int i = (int)index;
    if (i < 0) i = size + i;
    if (i >= size) throw IndexErr.make(index);
    Object old = values[i];
    if (i < size-1)
      System.arraycopy(values, i+1, values, i, size-i-1);
    size--;
    return old;
  }

  public final List removeRange(Range r)
  {
    modify();
    int s = r.startIndex(size);
    int e = r.endIndex(size);
    int n = e - s + 1;
    if (n < 0) throw IndexErr.make(r);

    int shift = size-s-n;
    if (shift > 0) System.arraycopy(values, s+n, values, s, shift);
    size -= n;
    for (int i=size; i<size+n; ++i) values[i] = null;
    return this;
  }

  public final List removeAll(List toRemove)
  {
    // optimize special cases
    modify();
    if (toRemove.sz() == 0) { return this; }
    if (toRemove.sz() == 1) { remove(toRemove.get(0)); return this; }

    // rebuild the backing store array, implementation
    // assumes that this list is bigger than toRemove list
    Object[] newValues = newArray(values.length);
    int newSize = 0;
    for (int i=0; i<size; ++i)
    {
      Object val = values[i];
      if (!toRemove.contains(val)) newValues[newSize++] = val;
    }
    this.values = newValues;
    this.size = newSize;
    return this;
  }

  private void grow(int desiredSize)
  {
    int desired = (int)desiredSize;
    if (desired < 1) throw Err.make("desired " + desired + " < 1");
    int newSize = Math.max(desired, size*2);
    if (newSize < 10) newSize = 10;
    Object[] temp = newArray(newSize);
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
      Object[] temp = newArray(size);
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

  public final List fill(Object val, long times)
  {
    modify();
    int t = (int)times;
    if (values.length < size+t) grow(size+t);
    for (int i=0; i<t; ++i) values[size+i] = val;
    size += t;
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
    return removeAt(-1);
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
    if (f.arity() == 1)
    {
      for (int i=0; i<size; ++i)
        f.call(values[i]);
    }
    else
    {
      for (int i=0; i<size; ++i)
        f.call(values[i], Long.valueOf(i));
    }
  }

  public final void eachr(Func f)
  {
    if (f.arity() == 1)
    {
      for (int i=size-1; i>=0; --i)
        f.call(values[i]);
    }
    else
    {
      for (int i=size-1; i>=0; --i)
        f.call(values[i], Long.valueOf(i));
    }
  }

  public final void eachRange(Range r, Func f)
  {
    int s = r.startIndex(size);
    int e = r.endIndex(size);
    int n = e - s + 1;
    if (n < 0) throw IndexErr.make(r);

    if (f.arity() == 1)
    {
      for (int i=s; i<=e; ++i)
        f.call(values[i]);
    }
    else
    {
      for (int i=s; i<=e; ++i)
        f.call(values[i], Long.valueOf(i));
    }
  }

  public final Object eachWhile(Func f)
  {
    if (f.arity() == 1)
    {
      for (int i=0; i<size; ++i)
      {
        Object r = f.call(values[i]);
        if (r != null) return r;
      }
    }
    else
    {
      for (int i=0; i<size; ++i)
      {
        Object r = f.call(values[i], Long.valueOf(i));
        if (r != null) return r;
      }
    }
    return null;
  }

  public final Object eachrWhile(Func f)
  {
    if (f.arity() == 1)
    {
      for (int i=size-1; i>=0; --i)
      {
        Object r = f.call(values[i]);
        if (r != null) return r;
      }
    }
    else
    {
      for (int i=size-1; i>=0; --i)
      {
        Object r = f.call(values[i], Long.valueOf(i));
        if (r != null) return r;
      }
    }
    return null;
  }

  public final Object find(Func f)
  {
    if (f.arity() == 1)
    {
      for (int i=0; i<size; ++i)
        if (f.callBool(values[i]))
          return values[i];
    }
    else
    {
      for (int i=0; i<size; ++i)
        if (f.callBool(values[i], Long.valueOf(i)))
          return values[i];
    }
    return null;
  }

  public final Long findIndex(Func f)
  {
    if (f.arity() == 1)
    {
      for (int i=0; i<size; ++i)
      {
        if (f.callBool(values[i]))
          return Long.valueOf(i);
      }
    }
    else
    {
      for (int i=0; i<size; ++i)
      {
        Long pos = Long.valueOf(i);
        if (f.callBool(values[i], pos))
          return pos;
      }
    }
    return null;
  }

  public final List findAll(Func f)
  {
    List acc = new List(of, size);
    if (f.arity() == 1)
    {
      for (int i=0; i<size; ++i)
        if (f.callBool(values[i]))
          acc.add(values[i]);
    }
    else
    {
      for (int i=0; i<size; ++i)
        if (f.callBool(values[i], Long.valueOf(i)))
          acc.add(values[i]);
    }
    return acc;
  }

  public final List findType(Type t)
  {
    List acc = new List(t, size);
    for (int i=0; i<size; ++i)
    {
      Object item = values[i];
      if (item != null && typeof(item).is(t))
        acc.add(item);
    }
    return acc;
  }

  public final List exclude(Func f)
  {
    List acc = new List(of, size);
    if (f.arity() == 1)
    {
      for (int i=0; i<size; ++i)
        if (!f.callBool(values[i]))
          acc.add(values[i]);
    }
    else
    {
      for (int i=0; i<size; ++i)
        if (!f.callBool(values[i], Long.valueOf(i)))
          acc.add(values[i]);
    }
    return acc;
  }

  public final boolean any(Func f)
  {
    if (f.arity() == 1)
    {
      for (int i=0; i<size; ++i)
        if (f.callBool(values[i]))
          return true;
    }
    else
    {
      for (int i=0; i<size; ++i)
        if (f.callBool(values[i], Long.valueOf(i)))
          return true;
    }
    return false;
  }

  public final boolean all(Func f)
  {
    if (f.arity() == 1)
    {
      for (int i=0; i<size; ++i)
        if (!f.callBool(values[i]))
          return false;
    }
    else
    {
      for (int i=0; i<size; ++i)
        if (!f.callBool(values[i], Long.valueOf(i)))
          return false;
    }
    return true;
  }

  public final Object reduce(Object reduction, Func f)
  {
    if (f.arity() == 1)
    {
      for (int i=0; i<size; ++i)
        reduction = f.call(reduction, values[i]);
    }
    else
    {
      for (int i=0; i<size; ++i)
        reduction = f.call(reduction, values[i], Long.valueOf(i));
    }
    return reduction;
  }

  public final List map(Func f)
  {
    Type r = f.returns();
    if (r == Sys.VoidType) r = Sys.ObjType.toNullable();
    List acc = new List(r, (int)size());
    if (f.arity() == 1)
    {
      for (int i=0; i<size; ++i)
        acc.add(f.call(values[i]));
    }
    else
    {
      for (int i=0; i<size; ++i)
        acc.add(f.call(values[i], Long.valueOf(i)));
    }
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
    if (size <= 1) return dup();
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

  public final long binarySearch(Object key) { return binarySearch(key, null); }
  public final long binarySearch(Object key, Func f)
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
        return probe;
    }
    return -(low + 1);
  }

  public final long binaryFind(Func f)
  {
    Object[] values = this.values;
    int low = 0, high = size-1;
    boolean oneArg = f.arity() == 1;
    while (low <= high)
    {
      int probe = (low + high) >> 1;
      Object val = values[probe];
      Object res = oneArg ? f.call(val) : f.call(val, Long.valueOf(probe));
      long cmp = ((Long)res).longValue();
      if (cmp > 0)
        low = probe + 1;
      else if (cmp < 0)
        high = probe - 1;
      else
        return probe;
    }
    return -(low + 1);
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

  public final List swap(long a, long b)
  {
    // modify in set()
    Object temp = get(a);
    set(a, get(b));
    set(b, temp);
    return this;
  }

  public final List moveTo(Object item, long toIndex)
  {
    modify();
    Long curIndex = index(item);
    if (curIndex == null) return this;
    if (curIndex == toIndex) return this;
    removeAt(curIndex);
    if (toIndex == -1) return add(item);
    if (toIndex < 0) ++toIndex;
    return insert(toIndex, item);
  }

  public final List flatten()
  {
    List acc = new List(Sys.ObjType.toNullable(), size*2);
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

  public final Object random()
  {
    if (size == 0) return null;
    int i = FanInt.random.nextInt();
    if (i < 0) i = -i;
    return values[i % size];
  }

  public final List shuffle()
  {
    modify();
    for (int i=0; i<size; ++i)
    {
      int randi = FanInt.random.nextInt(i+1);
      Object temp = values[i];
      values[i] = values[randi];
      values[randi] = temp;
    }
    return this;
  }

//////////////////////////////////////////////////////////////////////////
// Conversion
//////////////////////////////////////////////////////////////////////////

  public final String join() { return join("", null); }
  public final String join(String sep) { return join(sep, null); }
  public final String join(String sep, Func f)
  {
    if (size == 0) return "";

    if (size == 1)
    {
      Object v = values[0];
      if (f != null) return (String)f.call(v, 0L);
      if (v == null) return "null";
      return toStr(v);
    }

    StringBuilder s = new StringBuilder(32+size*32);
    for (int i=0; i<size; ++i)
    {
      if (i > 0) s.append(sep);
      if (f == null)
        s.append(values[i]);
      else
        s.append(f.call(values[i], Long.valueOf(i)));
    }
    return s.toString();
  }

  public final String toStr()
  {
    if (size == 0) return "[,]";
    StringBuilder s = new StringBuilder(32+size*32);
    s.append("[");
    for (int i=0; i<size; ++i)
    {
      if (i > 0) s.append(", ");
      s.append(values[i]);
    }
    s.append("]");
    return s.toString();
  }

  public final String toCode()
  {
    StringBuilder s = new StringBuilder(32+size*32);
    s.append(of.signature());
    s.append('[');
    if (size == 0) s.append(',');
    for (int i=0; i<size; ++i)
    {
      if (i > 0) s.append(',').append(' ');
      s.append(FanObj.trap(values[i], "toCode", null));
    }
    s.append(']');
    return s.toString();
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
      if (i >= size) throw IndexErr.make(""+i);
      return values[i];
    }
    catch (ArrayIndexOutOfBoundsException e)
    {
      throw IndexErr.make(""+i);
    }
  }

  private Object[] newArray(int capacity)
  {
    // use backing store of correct array type;
    // handle Java types and bootstrap types directly
    Type t = of.toNonNullable();
    if (t == Sys.ObjType)     return new Object[capacity];
    if (t == Sys.StrType)     return new String[capacity];
    if (t == Sys.IntType)     return new Long[capacity];
    if (t == Sys.BoolType)    return new Boolean[capacity];
    if (t == Sys.FloatType)   return new Double[capacity];
    if (t == Sys.DecimalType) return new BigDecimal[capacity];
    if (t == Sys.NumType)     return new Number[capacity];
    if (t == Sys.SlotType)    return new Slot[capacity];
    if (t == Sys.FieldType)   return new Field[capacity];
    if (t == Sys.MethodType)  return new Method[capacity];
    if (t == Sys.ParamType)   return new Param[capacity];
    return (Object[])Array.newInstance(of.toClass(), capacity);
  }

  /**
   * Get this list as an array of the specified class.  The resulting
   * array could potentially be a direct reference to the backing array.
   */
  public final Object[] asArray(Class of)
  {
    // short circuit if values is already correct array type
    if (size == values.length && of == values.getClass().getComponentType())
      return values;

    // make a safe copy of correct length and type
    Object[] r = (Object[]) Array.newInstance(of, size);
    System.arraycopy(values, 0, r, 0, size);
    return r;
  }

  public final Object[] toArray()
  {
    if (values.length == size) return values;
    Object[] r = newArray(size);
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
      throw IndexErr.make();
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
      throw IndexErr.make();
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
      throw IndexErr.make();
    }
  }

  public final String[] toStrings()
  {
    String[] a = new String[size];
    for (int i=0; i<size; ++i)
    {
      Object obj = get(i);
      if (obj == null) a[i] = "null";
      else a[i] = toStr(obj);
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
      public int compare(Object a, Object b) { return ((Long)f.call(a, b)).intValue(); }
    };
  }
  static final Comparator defaultComparator = new Comparator()
  {
    public int compare(Object a, Object b) { return (int)OpUtil.compare(a, b); }
  };

  static Comparator toReverseComparator(final Func f)
  {
    if (f == null) return defaultReverseComparator;
    return new Comparator()
    {
      public int compare(Object a, Object b) { return ((Long)f.call(b, a)).intValue(); }
    };
  }
  static final Comparator defaultReverseComparator = new Comparator()
  {
    public int compare(Object a, Object b) { return (int)OpUtil.compare(b, a); }
  };

//////////////////////////////////////////////////////////////////////////
// Readonly
//////////////////////////////////////////////////////////////////////////

  public final boolean isRW()
  {
    return !readonly;
  }

  public final boolean isRO()
  {
    return readonly;
  }

  public final List rw()
  {
    if (!readonly) return this;

    Object[] temp = newArray(size);
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

  public final boolean isImmutable()
  {
    return immutable;
  }

  public final Object toImmutable()
  {
    if (immutable) return this;

    // make safe copy
    Object[] temp = newArray(size);
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
          throw NotImmutableErr.make("Item [" + i + "] not immutable " + typeof(item));
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
      throw ReadonlyErr.make("List is readonly");

    // if we have a cached readonlyList, then detach
    // it so it remains immutable
    if (readonlyList != null)
    {
      Object[] temp = newArray(size);
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