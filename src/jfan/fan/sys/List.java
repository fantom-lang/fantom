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

  public static List make(Type of, Int capacity)
  {
    return new List(of, (int)capacity.val);
  }

  public static List makeObj(Int capacity)
  {
    return new List(Sys.ObjType, (int)capacity.val);
  }

  public List(Type of, Obj[] values)
  {
    if (of == null) { Thread.dumpStack(); throw new NullErr().val; }
    this.of = of;
    this.values = values;
    this.size = values.length;
  }

  public List(Type of, Obj[] values, int size)
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
    this.values = capacity == 0 ? empty : new Obj[capacity];
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
    this.values = (Obj[])collection.toArray(new Obj[size]);
  }

  public List(String[] values)
  {
    this.of = Sys.StrType;
    this.values = new Obj[values.length];
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

  public final Bool isEmpty()
  {
    return size == 0 ? Bool.True : Bool.False;
  }

  public final Int size()
  {
    return Int.pos(size);
  }

  public final void size(Int s)
  {
    modify();
    int newSize = (int)s.val;
    if (newSize > size)
    {
      Obj[] temp = new Obj[newSize];
      System.arraycopy(values, 0, temp, 0, size);
      values = temp;
      size = newSize;
    }
    else
    {
      Obj[] temp = new Obj[newSize];
      System.arraycopy(values, 0, temp, 0, newSize);
      values = temp;
      size = newSize;
    }
  }

  public final Int capacity()
  {
    return Int.pos(values.length);
  }

  public final void capacity(Int c)
  {
    modify();
    int newCapacity = (int)c.val;
    if (newCapacity < size) throw ArgErr.make("capacity < size").val;
    Obj[] temp = new Obj[newCapacity];
    System.arraycopy(values, 0, temp, 0, size);
    values = temp;
  }

  public final Obj get(Int index)
  {
    try
    {
      int i = (int)index.val;
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

  public final Bool contains(Obj value)
  {
    return Bool.make(index(value) != null);
  }

  public final Bool containsSame(Obj value)
  {
    return Bool.make(indexSame(value) != null);
  }

  public final Bool containsAll(List list)
  {
    for (int i=0; i<list.sz(); ++i)
      if (index(list.get(i)) == null)
        return Bool.False;
    return Bool.True;
  }

  public final Bool containsAllSame(List list)
  {
    for (int i=0; i<list.sz(); ++i)
      if (indexSame(list.get(i)) == null)
        return Bool.False;
    return Bool.True;
  }

  public final Int index(Obj value) { return index(value, Int.Zero); }
  public final Int index(Obj value, Int off)
  {
    if (size == 0) return null;
    int start = (int)off.val;
    if (start < 0) start = size + start;
    if (start >= size) throw IndexErr.make(off).val;

    try
    {
      if (value == null)
      {
        for (int i=start; i<size; ++i)
          if (values[i] == null)
            return Int.pos(i);
      }
      else
      {
        for (int i=start; i<size; ++i)
        {
          Obj obj = values[i];
          if (obj != null && obj.equals(value))
            return Int.pos(i);
        }
      }
      return null;
    }
    catch (ArrayIndexOutOfBoundsException e)
    {
      throw IndexErr.make(off).val;
    }
  }

  public final Int indexSame(Obj value) { return indexSame(value, Int.Zero); }
  public final Int indexSame(Obj value, Int off)
  {
    if (size == 0) return null;
    int start = (int)off.val;
    if (start < 0) start = size + start;
    if (start >= size) throw IndexErr.make(off).val;

    try
    {
      for (int i=start; i<size; ++i)
        if (value == values[i])
          return Int.pos(i);
      return null;
    }
    catch (ArrayIndexOutOfBoundsException e)
    {
      throw IndexErr.make(off).val;
    }
  }

  public final Obj first()
  {
    if (size == 0) return null;
    return values[0];
  }

  public final Obj last()
  {
    if (size == 0) return null;
    return values[size-1];
  }

  public final List dup()
  {
    Obj[] dup = new Obj[size];
    System.arraycopy(values, 0, dup, 0, size);
    return new List(of, dup);
  }

  public final Int hash()
  {
    long hash = 33;
    for (int i=0; i<size; ++i)
    {
      Obj obj = values[i];
      if (obj != null) hash ^= hash(obj).val;
    }
    return Int.make(hash);
  }

  public final Bool _equals(Obj that)
  {
    if (that instanceof List)
    {
      List x = (List)that;
      if (!of.equals(x.of)) return Bool.False;
      if (size != x.size) return Bool.False;
      for (int i=0; i<size; ++i)
        if (!OpUtil.compareEQ(values[i], x.values[i]).val) return Bool.False;
      return Bool.True;
    }
    return Bool.False;
  }

//////////////////////////////////////////////////////////////////////////
// Modification
//////////////////////////////////////////////////////////////////////////

  public final List set(Int index, Obj value)
  {
    modify();
    try
    {
      int i = (int)index.val;
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

  public final List add(Obj value)
  {
    // modify in insert(int, Obj)
    return insert(size, value);
  }

  public final List addAll(List list)
  {
    // modify in insertAll(int, List)
    return insertAll(size, list);
  }

  public final List insert(Int index, Obj value)
  {
    // modify in insert(int, Obj)
    int i = (int)index.val;
    if (i < 0) i = size + i;
    if (i > size) throw IndexErr.make(index).val;
    return insert(i, value);
  }

  private List insert(int i, Obj value)
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

  public final List insertAll(Int index, List list)
  {
    // modify in insertAll(int, List)
    int i = (int)index.val;
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

  public final Obj remove(Obj val)
  {
    // modify in removeAt(Int)
    Int index = index(val);
    if (index == null) return null;
    return removeAt(index);
  }

  public final Obj removeSame(Obj val)
  {
    // modify in removeAt(Int)
    Int index = indexSame(val);
    if (index == null) return null;
    return removeAt(index);
  }

  public final Obj removeAt(Int index)
  {
    modify();
    int i = (int)index.val;
    if (i < 0) i = size + i;
    if (i >= size) throw IndexErr.make(index).val;
    Obj old = values[i];
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
    Obj[] temp = new Obj[newSize];
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
      Obj[] temp = new Obj[size];
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

  public final Obj peek()
  {
    if (size == 0) return null;
    return values[size-1];
  }

  public final Obj pop()
  {
    // modify in removeAt()
    if (size == 0) return null;
    return removeAt(Int.NegOne);
  }

  public final List push(Obj obj)
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
      f.call2(values[i], Int.pos(i));
  }

  public final void eachr(Func f)
  {
    for (int i=size-1; i>=0; --i)
      f.call2(values[i], Int.pos(i));
  }

  public final Obj eachBreak(Func f)
  {
    for (int i=0; i<size; ++i)
    {
      Obj r = f.call2(values[i], Int.pos(i));
      if (r != null) return r;
    }
    return null;
  }

  public final Obj find(Func f)
  {
    for (int i=0; i<size; ++i)
      if (f.call2(values[i], Int.pos(i)) == Bool.True)
        return values[i];
    return null;
  }

  public final Int findIndex(Func f)
  {
    for (int i=0; i<size; ++i)
    {
      Int pos = Int.pos(i);
      if (f.call2(values[i], pos) == Bool.True)
        return pos;
    }
    return null;
  }

  public final List findAll(Func f)
  {
    List acc = new List(of, size);
    for (int i=0; i<size; ++i)
      if (f.call2(values[i], Int.pos(i)) == Bool.True)
        acc.add(values[i]);
    return acc;
  }

  public final List findType(Type t)
  {
    List acc = new List(t, size);
    for (int i=0; i<size; ++i)
    {
      Obj item = values[i];
      if (item != null && type(item).is(t))
        acc.add(item);
    }
    return acc;
  }

  public final List exclude(Func f)
  {
    List acc = new List(of, size);
    for (int i=0; i<size; ++i)
      if (f.call2(values[i], Int.pos(i)) != Bool.True)
        acc.add(values[i]);
    return acc;
  }

  public final Bool any(Func f)
  {
    for (int i=0; i<size; ++i)
      if (f.call2(values[i], Int.pos(i)) == Bool.True)
        return Bool.True;
    return Bool.False;
  }

  public final Bool all(Func f)
  {
    for (int i=0; i<size; ++i)
      if (f.call2(values[i], Int.pos(i)) != Bool.True)
        return Bool.False;
    return Bool.True;
  }

  public final Obj reduce(Obj reduction, Func f)
  {
    for (int i=0; i<size; ++i)
      reduction = f.call3(reduction, values[i], Int.pos(i));
    return reduction;
  }

  public final List map(List acc, Func f)
  {
    if (acc.size == 0) acc.capacity(size());
    for (int i=0; i<size; ++i)
      acc.add(f.call2(values[i], Int.pos(i)));
    return acc;
  }

  public final Obj max() { return max(null); }
  public final Obj max(Func f)
  {
    if (size == 0) return null;
    Comparator c = toComparator(f);
    Obj max = values[0];
    for (int i=1; i<size; ++i)
      if (c.compare(values[i], max) > 0)
        max = values[i];
    return max;
  }

  public final Obj min() { return min(null); }
  public final Obj min(Func f)
  {
    if (size == 0) return null;
    Comparator c = toComparator(f);
    Obj min = values[0];
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
      Obj v = values[i];
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
      Obj v = values[i];
      if (dups.get(v) == null)
      {
        dups.put(v, this);
        acc.add(v);
      }
    }

    // then him
    for (int i=0; i<that.size; ++i)
    {
      Obj v = that.values[i];
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
      Obj v = values[i];
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

  public final Int binarySearch(Obj key) { return binarySearch(key, null); }
  public final Int binarySearch(Obj key, Func f)
  {
    Comparator c = toComparator(f);
    Obj[] values = this.values;
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
        return Int.pos(probe);
    }
    return Int.make(-(low + 1));
  }

  public final List reverse()
  {
    modify();
    Obj[] values = this.values;
    int size = this.size;
    int mid   = size/2;
    for (int i=0; i<mid; ++i)
    {
      Obj a = values[i];
      Obj b = values[size-i-1];
      values[i] = b;
      values[size-i-1] = a;
    }
    return this;
  }

  public final List swap(Int a, Int b)
  {
    // modify in set()
    Obj temp = get(a);
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
      Obj item = values[i];
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
      Obj v = values[0];
      if (f != null) return (Str)f.call2(v, Int.Zero);
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
        s.append(f.call2(values[i], Int.pos(i)));
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

  public final Obj get(int i)
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

  public final Obj[] toArray()
  {
    if (values.length == size) return values;
    Obj[] r = new Obj[size];
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
      Obj obj = get(i);
      if (obj == null) a[i] = "null";
      else a[i] = toStr(obj).val;
    }
    return a;
  }

  public final int[] toInts()
  {
    int[] a = new int[size];
    for (int i=0; i<size; ++i) a[i] = (int)((Int)get(i)).val;
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
      public int compare(Object a, Object b) { return (int)((Int)f.call2((Obj)a, (Obj)b)).val; }
    };
  }
  static final Comparator defaultComparator = new Comparator()
  {
    public int compare(Object a, Object b) { return (int)OpUtil.compare((Obj)a, (Obj)b).val; }
  };

  static Comparator toReverseComparator(final Func f)
  {
    if (f == null) return defaultReverseComparator;
    return new Comparator()
    {
      public int compare(Object a, Object b) { return (int)((Int)f.call2((Obj)b, (Obj)a)).val; }
    };
  }
  static final Comparator defaultReverseComparator = new Comparator()
  {
    public int compare(Object a, Object b) { return (int)OpUtil.compare((Obj)b, (Obj)a).val; }
  };

//////////////////////////////////////////////////////////////////////////
// Readonly
//////////////////////////////////////////////////////////////////////////

  public final Bool isRW()
  {
    return readonly ? Bool.False : Bool.True;
  }

  public final Bool isRO()
  {
    return readonly ? Bool.True : Bool.False;
  }

  public final List rw()
  {
    if (!readonly) return this;

    Obj[] temp = new Obj[size];
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

  public final Bool isImmutable()
  {
    return Bool.make(immutable);
  }

  public final List toImmutable()
  {
    if (immutable) return this;

    // make safe copy
    Obj[] temp = new Obj[size];
    for (int i=0; i<size; ++i)
    {
      Obj item = values[i];
      if (item != null)
      {
        if (item instanceof List)
          item = ((List)item).toImmutable();
        else if (item instanceof Map)
          item = ((Map)item).toImmutable();
        else if (!isImmutable(item).val)
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
      Obj[] temp = new Obj[size];
      System.arraycopy(values, 0, temp, 0, size);
      readonlyList.values = temp;
      readonlyList = null;
    }
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private static final Obj[] empty = new Obj[0];

  private Type of;
  private Obj[] values;
  private int size;
  private boolean readonly;
  private boolean immutable;
  private List readonlyList;

}