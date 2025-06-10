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
import java.util.Iterator;
import java.util.ListIterator;
import java.util.NoSuchElementException;
import fanx.serial.*;
import fanx.util.*;

/**
 * List
 */
public final class List<V>
  extends FanObj
  implements Literal, java.util.List<V>
{

//////////////////////////////////////////////////////////////////////////
// Constructors
//////////////////////////////////////////////////////////////////////////

  /**
   * Construct empty list of given type
   */
  public static List make(Type of)
  {
    return new List(of);
  }

  /**
   * Construct empty list of given type with given capacity
   */
  public static List make(Type of, long capacity)
  {
    return new List(of, (int)capacity);
  }

  /**
   * Construct empty list of Obj? with given capacity
   */
  public static List makeObj(long capacity)
  {
    return new List(Sys.ObjType.toNullable(), (int)capacity);
  }

  /**
   * Construct list of Obj? for an array. No copy is made
   * of the backing array, it should be no used again.  If the
   * array is null then return null.
   */
  public static List makeObj(Object[] values)
  {
    if (values == null) return null;
    return new List(Sys.ObjType.toNullable(), values, values.length);
  }

  /**
   * Construct list of given type for an array. No copy is made
   * of the backing array, it should be no used again.  If the
   * array is null then return null.
   */
  public static List make(Type of, Object[] values)
  {
    if (values == null) return null;
    return new List(of, values);
  }

  /**
   * Construct list of given type for an array and size. No copy is made
   * of the backing array, it should be no used again.  If the
   * array is null then return null.
   */
  public static List make(Type of, Object[] values, int size)
  {
    if (values == null) return null;
    return new List(of, values, size);
  }

  /**
   * Construct list of given type using collection.
   */
  public static List make(Type of, Collection c)
  {
    return new List(of, c);
  }

  List(Type of)
  {
    if (of == null) { Thread.dumpStack(); throw NullErr.make(); }
    this.of = of;
    this.values = (V[])empty;
  }

  List(Type of, int capacity)
  {
    if (of == null) { Thread.dumpStack(); throw NullErr.make(); }
    this.of = of;
    this.values = capacity == 0 ? (V[])empty : newArray(capacity);
  }

  List(Type of, V[] values)
  {
    if (of == null) { Thread.dumpStack(); throw NullErr.make(); }
    this.of = of;
    this.values = values;
    this.size = values.length;
  }

  List(Type of, V[] values, int size)
  {
    if (of == null) { Thread.dumpStack(); throw NullErr.make(); }
    this.of = of;
    this.values = values;
    this.size = size;
  }

  List(Type of, Collection collection)
  {
    if (of == null) { Thread.dumpStack(); throw NullErr.make(); }
    this.of = of;
    this.size = collection.size();
    this.values = (V[])collection.toArray(newArray(size));
  }

  List(String[] values)
  {
    this.of = Sys.StrType;
    this.size = values.length;
    this.values = (V[])values;
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

  public final long _size()
  {
    return size;
  }

  public final void _size(long s)
  {
    modify();
    int newSize = (int)s;
    if (newSize > size)
    {
      if (!of.isNullable()) throw ArgErr.make("Cannot grow non-nullable list of " + of);
      if (newSize > values.length)
      {
        V[] temp = newArray(newSize);
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
    V[] temp = newArray(newCapacity);
    System.arraycopy(values, 0, temp, 0, size);
    values = temp;
  }

  public final V get(long index)
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

  public final V getSafe(long index) { return getSafe(index, null); }
  public final V getSafe(long index, V def)
  {
    if (index < 0) index = size + index;
    if (index >= size || index < 0) return def;
    return values[(int)index];
  }

  public final List<V> getRange(Range r)
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

  public final boolean contains(Object value)
  {
    if (value == null) return containsSame(value);
    for (int i=0; i<size; ++i)
    {
      Object obj = values[i];
      if (obj != null && obj.equals(value))
        return true;
    }
    return false;
  }

  public final boolean containsSame(Object value)
  {
    for (int i=0; i<size; ++i)
      if (values[i] == value) return true;
    return false;
  }

  public final boolean containsAll(List<V> list)
  {
    for (int i=0; i<list.sz(); ++i)
      if (index(list.get(i)) == null)
        return false;
    return true;
  }

  public final boolean containsAny(List<V> list)
  {
    for (int i=0; i<list.sz(); ++i)
      if (index(list.get(i)) != null)
        return true;
    return false;
  }

  public final Long index(V value) { return index(value, 0L); }
  public final Long index(V value, long off)
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

  public final Long indexr(V value) { return indexr(value, -1L); }
  public final Long indexr(V value, long off)
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

  public final Long indexSame(V value) { return indexSame(value, 0L); }
  public final Long indexSame(V value, long off)
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

  public final V first()
  {
    if (size == 0) return null;
    return values[0];
  }

  public final V last()
  {
    if (size == 0) return null;
    return values[size-1];
  }

  public final List<V> dup()
  {
    V[] dup = newArray(size);
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

  public final List<V> set(long index, V value)
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

  public final List<V> setNotNull(long index, V value)
  {
    if (value == null) return this;
    return set(index, value);
  }

  public final List<V> _add(V value)
  {
    // modify in insert(int, Obj)
    return insert(size, value);
  }

  // deprecated
  public final List<V> addIfNotNull(V value) { return addNotNull(value); }

  public final List<V> addNotNull(V value)
  {
    if (value == null) return this;
    return _add(value);
  }

  public final List<V> addAll(List<V> list)
  {
    // modify in insertAll(int, List)
    return insertAll(size, list);
  }

  public final List<V> insert(long index, V value)
  {
    // modify in insert(int, Obj)
    int i = (int)index;
    if (i < 0) i = size + i;
    if (i > size) throw IndexErr.make(index);
    return insert(i, value);
  }

  private List<V> insert(int i, V value)
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

  public final List<V> insertAll(long index, List<V> list)
  {
    // modify in insertAll(int, List)
    int i = (int)index;
    if (i < 0) i = size + i;
    if (i > size || i < 0) throw IndexErr.make(index);
    return insertAll(i, list);
  }

  private List<V> insertAll(int i, List<V> list)
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

  public final V _remove(V val)
  {
    // modify in removeAt(Int)
    Long index = index(val);
    if (index == null) return null;
    return removeAt(index);
  }

  public final V removeSame(V val)
  {
    // modify in removeAt(Int)
    Long index = indexSame(val);
    if (index == null) return null;
    return removeAt(index);
  }

  public final V removeAt(long index)
  {
    modify();
    int i = (int)index;
    if (i < 0) i = size + i;
    if (i >= size) throw IndexErr.make(index);
    V old = values[i];
    if (i < size-1)
      System.arraycopy(values, i+1, values, i, size-i-1);
    size--;
    return old;
  }

  public final List<V> removeRange(Range r)
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

  public final List<V> removeAll(List<V> toRemove)
  {
    // optimize special cases
    modify();
    if (toRemove.sz() == 0) { return this; }
    if (toRemove.sz() == 1) { remove(toRemove.get(0)); return this; }

    // rebuild the backing store array, implementation
    // assumes that this list is bigger than toRemove list
    V[] newValues = newArray(values.length);
    int newSize = 0;
    for (int i=0; i<size; ++i)
    {
      V val = values[i];
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
    V[] temp = newArray(newSize);
    System.arraycopy(values, 0, temp, 0, size);
    values = temp;
  }

  public final List<V> trim()
  {
    modify();
    if (size == 0)
    {
      values = (V[])empty;
    }
    else if (values.length != size)
    {
      V[] temp = newArray(size);
      System.arraycopy(values, 0, temp, 0, size);
      values = temp;
    }
    return this;
  }

  public final List<V> _clear()
  {
    modify();
    for (int i=0; i<size; ++i)
      values[i] = null;
    size = 0;
    return this;
  }

  public final List<V> fill(V val, long times)
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

  public final V peek()
  {
    if (size == 0) return null;
    return values[size-1];
  }

  public final V pop()
  {
    // modify in removeAt()
    if (size == 0) return null;
    return removeAt(-1);
  }

  public final List<V> push(V obj)
  {
    // modify in add()
    return _add(obj);
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

  public final void eachNotNull(Func f)
  {
    if (f.arity() == 1)
    {
      for (int i=0; i<size; ++i)
      {
        Object value = values[i];
        if (value != null) f.call(value);
      }
    }
    else
    {
      for (int i=0; i<size; ++i)
      {
        Object value = values[i];
        if (value != null) f.call(value, Long.valueOf(i));
      }
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

  public final V find(Func f)
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

  public final List<V> findAll(Func f)
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

  public final List<V> findType(Type t)
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

  public final List<V> findNotNull()
  {
    List acc = new List(of.toNonNullable(), size);
    for (int i=0; i<size; ++i)
    {
      Object item = values[i];
      if (item != null)
        acc.add(item);
    }
    return acc;
  }

  public final List<V> exclude(Func f)
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
    List acc = new List(r, size);
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

  public final List mapNotNull(Func f)
  {
    Type r = f.returns();
    if (r == Sys.VoidType) r = Sys.ObjType;
    List acc = new List(r.toNonNullable(), size);
    if (f.arity() == 1)
    {
      for (int i=0; i<size; ++i)
        acc.addNotNull(f.call(values[i]));
    }
    else
    {
      for (int i=0; i<size; ++i)
        acc.addNotNull(f.call(values[i], Long.valueOf(i)));
    }
    return acc;
  }

  public final List flatMap(Func f)
  {
    Type r = f.returns();
    Type of = Sys.ObjType.toNullable();
    if (r instanceof ListType) of = ((ListType)r).v;
    List acc = new List(of, size);
    if (f.arity() == 1)
    {
      for (int i=0; i<size; ++i)
        acc.addAll((List)f.call(values[i]));
    }
    else
    {
      for (int i=0; i<size; ++i)
        acc.addAll((List)f.call(values[i], Long.valueOf(i)));
    }
    return acc;
  }

  public final Map<Object,List<V>> groupBy(Func f)
  {
    Type r = f.returns();
    if (r == Sys.VoidType) r = Sys.ObjType;
    Map acc = new Map(r, typeof());
    return groupByInto(acc, f);
  }

  public final Map<Object,List<V>> groupByInto(Map acc, Func f)
  {
    MapType accType = acc.type();
    if (!(accType.v instanceof ListType)) throw ArgErr.make("Map value type is not list: $accType");
    Type bucketOfType = ((ListType)accType.v).v;
    boolean arity1 = f.arity() == 1;
    for (int i=0; i<size; ++i)
    {
      Object val = values[i];
      Object key = arity1 ? f.call(val) : f.call(val, Long.valueOf(i));
      List bucket = (List)acc.get(key);
      if (bucket == null)
      {
        bucket = new List(bucketOfType, 8);
        acc.set(key, bucket);
      }
      bucket.add(val);
    }
    return acc;
  }

  public final V max() { return max(null); }
  public final V max(Func f)
  {
    if (size == 0) return null;
    Comparator c = toComparator(f);
    V max = values[0];
    for (int i=1; i<size; ++i)
      if (c.compare(values[i], max) > 0)
        max = values[i];
    return max;
  }

  public final V min() { return min(null); }
  public final V min(Func f)
  {
    if (size == 0) return null;
    Comparator c = toComparator(f);
    V min = values[0];
    for (int i=1; i<size; ++i)
      if (c.compare(values[i], min) < 0)
        min = values[i];
    return min;
  }

  public final List<V> unique()
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

  public final List<V> union(List<V> that)
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

  public final List<V> intersection(List<V> that)
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

  public final List<V> sort() { return sort((Func)null); }
  public final List<V> sort(final Func f)
  {
    modify();
    Arrays.sort(values, 0, size, toComparator(f));
    return this;
  }

  public final List<V> sortr() { return sortr(null); }
  public final List<V> sortr(final Func f)
  {
    modify();
    Arrays.sort(values, 0, size, toReverseComparator(f));
    return this;
  }

  public final long binarySearch(V key) { return binarySearch(key, null); }
  public final long binarySearch(V key, Func f)
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

  public final List<V> reverse()
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

  public final List<V> swap(long a, long b)
  {
    // modify in set()
    V temp = get(a);
    set(a, get(b));
    set(b, temp);
    return this;
  }

  public final List<V> moveTo(V item, long toIndex)
  {
    modify();
    Long curIndex = index(item);
    if (curIndex == null) return this;
    if (curIndex == toIndex) return this;
    removeAt(curIndex);
    if (toIndex == -1) return _add(item);
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

  public final V random()
  {
    if (size == 0) return null;
    int i = FanInt.random.nextInt();
    if (i < 0) i = -i;
    return values[i % size];
  }

  public final List<V> shuffle()
  {
    modify();
    for (int i=0; i<size; ++i)
    {
      int randi = FanInt.random.nextInt(i+1);
      V temp = values[i];
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

  private V[] newArray(int capacity) { return (V[])doNewArray(capacity); }
  private Object[] doNewArray(int capacity)
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

  public final List<V> rw()
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

  public final List<V> ro()
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
      V[] temp = newArray(size);
      System.arraycopy(values, 0, temp, 0, size);
      readonlyList.values = temp;
      readonlyList = null;
    }
  }

//////////////////////////////////////////////////////////////////////////
// java.util.List
//////////////////////////////////////////////////////////////////////////


  public final int size()
  {
    return size;
  }

  public final V get(int index)
  {
    if (index < 0 || index >= size) throw IndexErr.make(""+index);
    return values[index];
  }

  public final V set(int index, V value)
  {
    V old = get(index);
    set((long)index, value);
    return old;
  }

  public final int indexOf(Object value)
  {
    Long index = index((V)value);
    return index == null ? -1 : index.intValue();
  }

  public final int lastIndexOf(Object value)
  {
    Long index = indexr((V)value);
    return index == null ? -1 : index.intValue();
  }

  public final boolean containsAll(Collection<?> c)
  {
    return containsAll(new List(Sys.ObjType, c));
  }

  public final List<V> subList(int fromIndex, int toIndex)
  {
    return getRange(Range.makeExclusive(fromIndex, toIndex));
  }

  public final boolean add(V value)
  {
    _add(value);
    return true;
  }

  public final void add(int index, V value)
  {
    insert(index, value);
  }

  public final boolean addAll(Collection<? extends V> c)
  {
    return addAll(size(), c);
  }

  public final boolean addAll(int index, Collection<? extends V> c)
  {
    insertAll(index, new List(Sys.ObjType, c));
    return true;
  }

  public final boolean remove(Object value)
  {
    return _remove((V)value) == value;
  }

  public final V remove(int index)
  {
    return removeAt(index);
  }

  public final boolean removeAll(Collection<?> c)
  {
    removeAll(new List(Sys.ObjType, c));
    return true;
  }

  public final boolean retainAll(Collection<?> c)
  {
    throw new UnsupportedOperationException();
  }

  public final void clear()
  {
    _clear();
  }

  public final Iterator<V> iterator()
  {
    return new ListItr(0);
  }

  public final ListIterator<V> listIterator()
  {
    return new ListItr(0);
  }

  public final ListIterator<V> listIterator(int index)
  {
    return new ListItr(index);
  }

  private class ListItr implements ListIterator
  {
    ListItr(int index)
    {
      cursor = index;
    }

    public boolean hasNext()
    {
      return cursor != size;
    }

    public boolean hasPrevious()
    {
      return cursor != 0;
    }

    public Object next()
    {
      int i = cursor + 1;
      if (i >= size) throw new NoSuchElementException();
      cursor = i;
      return (V) values[cursor];
    }

    public int nextIndex()
    {
      return cursor;
    }

    public int previousIndex()
    {
      return cursor - 1;
    }

    public Object previous()
    {
      int i = cursor - 1;
      if (cursor < 0) throw new NoSuchElementException();
      cursor = i;
      return (V) values[cursor];
    }

    public void set(Object e)
    {
      throw new UnsupportedOperationException();
    }

    public void add(Object e)
    {
      throw new UnsupportedOperationException();
    }

    public void remove()
    {
      throw new UnsupportedOperationException();
    }

    private int cursor;
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private static final Object[] empty = new Object[0];

  private Type of;
  private V[] values;
  private int size;
  private boolean readonly;
  private boolean immutable;
  private List<V> readonlyList;

}

