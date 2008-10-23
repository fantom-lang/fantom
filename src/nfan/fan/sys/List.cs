//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Sep 06  Andy Frank  Creation
//

using System;
using System.Collections;
using System.Diagnostics;
using System.Text;
using Fanx.Util;
using Fanx.Serial;

namespace Fan.Sys
{
  /// <summary>
  /// List.
  /// </summary>
  public class List : FanObj, Literal
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
      return new List(Sys.ObjType.toNullable(), capacity.intValue());
    }

    public List(Type of, object[] values)
    {
      if (of == null) { Console.WriteLine(new StackTrace(true)); throw new NullErr().val; }
      this.m_of = of;
      this.m_values = values;
      this.m_size = values.Length;
    }

    public List(Type of, object[] values, int size)
    {
      if (of == null) { Console.WriteLine(new StackTrace(true)); throw new NullErr().val; }
      this.m_of = of;
      this.m_values = values;
      this.m_size = size;
    }

    public List(Type of, int capacity)
    {
      if (of == null) { Console.WriteLine(new StackTrace(true)); throw new NullErr().val; }
      this.m_of = of;
      this.m_values = capacity == 0 ? m_empty : new object[capacity];
    }

    public List(Type of)
    {
      if (of == null) { Console.WriteLine(new StackTrace(true)); throw new NullErr().val; }
      this.m_of = of;
      this.m_values = m_empty;
    }

    public List(Type of, ICollection collection)
    {
      if (of == null) { Console.WriteLine(new StackTrace(true)); throw new NullErr().val; }
      this.m_of = of;
      this.m_size = collection.Count;
      this.m_values = new object[m_size];
      collection.CopyTo(this.m_values, 0);
    }

    public List(string[] values)
    {
      this.m_of = Sys.StrType;
      this.m_size = values.Length;
      this.m_values = values;
    }

  //////////////////////////////////////////////////////////////////////////
  // Identity
  //////////////////////////////////////////////////////////////////////////

    public override Type type()
    {
      return m_of.toListOf();
    }

    public Type of()
    {
      return m_of;
    }

  //////////////////////////////////////////////////////////////////////////
  // Access
  //////////////////////////////////////////////////////////////////////////

    public Boolean isEmpty()
    {
      return m_size == 0 ? Boolean.True : Boolean.False;
    }

    public Long size()
    {
      return Long.valueOf(m_size);
    }

    public void size(Long s)
    {
      modify();
      int newSize = s.intValue();
      if (newSize > m_size)
      {
        object[] temp = new object[newSize];
        Array.Copy(m_values, 0, temp, 0, m_size);
        m_values = temp;
        m_size = newSize;
      }
      else
      {
        object[] temp = new object[newSize];
        Array.Copy(m_values, 0, temp, 0, newSize);
        m_values = temp;
        m_size = newSize;
      }
    }

    public Long capacity()
    {
      return Long.valueOf(m_values.Length);
    }

    public void capacity(Long c)
    {
      modify();
      int newCapacity = c.intValue();
      if (newCapacity < m_size) throw ArgErr.make("capacity < m_size").val;
      object[] temp = new object[newCapacity];
      Array.Copy(m_values, 0, temp, 0, m_size);
      m_values = temp;
    }

    public object get(Long index)
    {
      try
      {
        int i = index.intValue();
        if (i < 0) i = m_size + i;
        if (i >= m_size) throw IndexErr.make(index).val;
        return m_values[i];
      }
      catch (IndexOutOfRangeException)
      {
        throw IndexErr.make(index).val;
      }
    }

    public List slice(Range r)
    {
      try
      {
        int s = r.start(m_size);
        int e = r.end(m_size);
        int n = e - s + 1;
        if (n < 0) throw IndexErr.make(r).val;

        List acc = new List(m_of, n);
        acc.m_size = n;
        Array.Copy(m_values, s, acc.m_values, 0, n);
        return acc;
      }
      catch (ArgumentOutOfRangeException)
      {
        throw IndexErr.make(r).val;
      }
    }

    public Boolean contains(object val)
    {
      return Boolean.valueOf(index(val) != null);
    }

    public Boolean containsSame(object val)
    {
      return Boolean.valueOf(indexSame(val) != null);
    }

    public Boolean containsAll(List list)
    {
      for (int i=0; i<list.sz(); i++)
        if (index(list.get(i)) == null)
          return Boolean.False;
      return Boolean.True;
    }

    public Boolean containsAllSame(List list)
    {
      for (int i=0; i<list.sz(); i++)
        if (indexSame(list.get(i)) == null)
          return Boolean.False;
      return Boolean.True;
    }

    public Long index(object val) { return index(val, FanInt.Zero); }
    public Long index(object val, Long off)
    {
      if (m_size == 0) return null;
      int start = off.intValue();
      if (start < 0) start = m_size + start;
      if (start >= m_size) throw IndexErr.make(off).val;

      try
      {
        if (val == null)
        {
          for (int i=start; i<m_size; i++)
            if (m_values[i] == null)
              return Long.valueOf(i);
        }
        else
        {
          for (int i=start; i<m_size; i++)
          {
            object obj = m_values[i];
            if (obj != null && obj.Equals(val))
              return Long.valueOf(i);
          }
        }
        return null;
      }
      catch (IndexOutOfRangeException)
      {
        throw IndexErr.make(off).val;
      }
    }

    public Long indexSame(object val) { return indexSame(val, FanInt.Zero); }
    public Long indexSame(object val, Long off)
    {
      if (m_size == 0) return null;
      int start = off.intValue();
      if (start < 0) start = m_size + start;
      if (start >= m_size) throw IndexErr.make(off).val;

      try
      {
        for (int i=start; i<m_size; i++)
          if (val == m_values[i])
            return Long.valueOf(i);
        return null;
      }
      catch (IndexOutOfRangeException)
      {
        throw IndexErr.make(off).val;
      }
    }

    public object first()
    {
      if (m_size == 0) return null;
      return m_values[0];
    }

    public object last()
    {
      if (m_size == 0) return null;
      return m_values[m_size-1];
    }

    public List dup()
    {
      object[] dup = new object[m_size];
      Array.Copy(m_values, 0, dup, 0, m_size);
      return new List(m_of, dup);
    }

    public override Long hash()
    {
      long hash = 33;
      for (int i=0; i<m_size; i++)
      {
        object obj = m_values[i];
        if (obj != null) hash ^= FanObj.hash(obj).longValue();
      }
      return Long.valueOf(hash);
    }

    public override Boolean _equals(object that)
    {
      if (that is List)
      {
        List x = (List)that;
        if (!m_of.Equals(x.m_of)) return Boolean.False;
        if (m_size != x.m_size) return Boolean.False;
        for (int i=0; i<m_size; i++)
          if (!OpUtil.compareEQ(m_values[i], x.m_values[i]).booleanValue()) return Boolean.False;
        return Boolean.True;
      }
      return Boolean.False;
    }

  //////////////////////////////////////////////////////////////////////////
  // Modification
  //////////////////////////////////////////////////////////////////////////

    public List set(Long index, object val)
    {
      modify();
      try
      {
        int i = index.intValue();
        if (i < 0) i = m_size + i;
        if (i >= m_size) throw IndexErr.make(index).val;
        m_values[i] = val;
        return this;
      }
      catch (IndexOutOfRangeException)
      {
        throw IndexErr.make(index).val;
      }
    }

    public List add(object val)
    {
      // modify in insert(int, object)
      return insert(m_size, val);
    }

    public List addAll(List list)
    {
      // modify in insertAll(int, List)
      return insertAll(m_size, list);
    }

    public List insert(Long index, object val)
    {
      // modify in insert(int, object)
      int i = index.intValue();
      if (i < 0) i = m_size + i;
      if (i > m_size) throw IndexErr.make(index).val;
      return insert(i, val);
    }

    private List insert(int i, object val)
    {
      modify();
      if (m_values.Length <= m_size)
        grow(m_size+1);
      if (i < m_size)
        Array.Copy(m_values, i, m_values, i+1, m_size-i);
      m_values[i] = val;
      m_size++;
      return this;
    }

    public List insertAll(Long index, List list)
    {
      // modify in insertAll(int, List)
      int i = index.intValue();
      if (i < 0) i = m_size + i;
      if (i > m_size) throw IndexErr.make(index).val;
      return insertAll(i, list);
    }

    private List insertAll(int i, List list)
    {
      modify();
      if (list.m_size == 0) return this;
      if (m_values.Length < m_size+list.m_size)
        grow(m_size+list.m_size);
      if (i < m_size)
        Array.Copy(m_values, i, m_values, i+list.m_size, m_size-i);
      Array.Copy(list.m_values, 0, m_values, i, list.m_size);
      m_size += list.m_size;
      return this;
    }

    public object remove(object val)
    {
      // modify in removeAt(Long)
      Long i = index(val);
      if (i == null) return null;
      return removeAt(i);
    }

    public object removeSame(object val)
    {
      // modify in removeAt(Long)
      Long i = indexSame(val);
      if (i == null) return null;
      return removeAt(i);
    }

    public object removeAt(Long index)
    {
      modify();
      int i = index.intValue();
      if (i < 0) i = m_size + i;
      if (i >= m_size) throw IndexErr.make(index).val;
      object old = m_values[i];
      if (i < m_size-1)
        Array.Copy(m_values, i+1, m_values, i, m_size-i-1);
      m_size--;
      return old;
    }

    public List removeRange(Range r)
    {
      modify();
      int s = r.start(m_size);
      int e = r.end(m_size);
      int n = e - s + 1;
      if (n < 0) throw IndexErr.make(r).val;

      int shift = m_size-s-n;
      if (shift > 0) Array.Copy(m_values, s+n, m_values, s, shift);
      m_size -= n;
      for (int i=m_size; i<m_size+n; ++i) m_values[i] = null;
      return this;
    }

    private void grow(int desiredSize)
    {
      int desired = (int)desiredSize;
      if (desired < 1) throw Err.make("desired " + desired + " < 1").val;
      int newSize = Math.Max(desired, m_size*2);
      if (newSize < 10) newSize = 10;
      object[] temp = new object[newSize];
      Array.Copy(m_values, temp, m_size);
      m_values = temp;
    }

    public List trim()
    {
      modify();
      if (m_size == 0)
      {
        m_values = m_empty;
      }
      else if (m_size != m_values.Length)
      {
        object[] temp = new object[m_size];
        Array.Copy(m_values, temp, m_size);
        m_values = temp;
      }
      return this;
    }

    public List clear()
    {
      modify();
      for (int i=0; i<m_size; i++)
        m_values[i] = null;
      m_size = 0;
      return this;
    }

  //////////////////////////////////////////////////////////////////////////
  // Stack
  //////////////////////////////////////////////////////////////////////////

    public object peek()
    {
      if (m_size == 0) return null;
      return m_values[m_size-1];
    }

    public object pop()
    {
      // modify in removeAt()
      if (m_size == 0) return null;
      return removeAt(FanInt.NegOne);
    }

    public List push(object obj)
    {
      // modify in add()
      return add(obj);
    }

  //////////////////////////////////////////////////////////////////////////
  // Iterators
  //////////////////////////////////////////////////////////////////////////

    public void each(Func f)
    {
      for (int i=0; i<m_size; i++)
        f.call2(m_values[i], Long.valueOf(i));
    }

    public void eachr(Func f)
    {
      for (int i=m_size-1; i>=0; i--)
        f.call2(m_values[i], Long.valueOf(i));
    }

    public object eachBreak(Func f)
    {
      for (int i=0; i<m_size; i++)
      {
        object r = f.call2(m_values[i], Long.valueOf(i));
        if (r != null) return r;
      }
      return null;
    }

    public object find(Func f)
    {
      for (int i=0; i<m_size; i++)
        if (f.call2(m_values[i], Long.valueOf(i)) == Boolean.True)
          return m_values[i];
      return null;
    }

    public Long findIndex(Func f)
    {
      for (int i=0; i<m_size; ++i)
      {
        Long pos = Long.valueOf(i);
        if (f.call2(m_values[i], pos) == Boolean.True)
          return pos;
      }
      return null;
    }

    public List findAll(Func f)
    {
      List acc = new List(m_of, m_size);
      for (int i=0; i<m_size; i++)
        if (f.call2(m_values[i], Long.valueOf(i)) == Boolean.True)
          acc.add(m_values[i]);
      return acc;
    }

    public List findType(Type t)
    {
      List acc = new List(t, m_size);
      for (int i=0; i<m_size; i++)
      {
        object item = m_values[i];
        if (item != null && type(item).@is(t))
          acc.add(item);
      }
      return acc;
    }

    public List exclude(Func f)
    {
      List acc = new List(m_of, m_size);
      for (int i=0; i<m_size; i++)
        if (f.call2(m_values[i], Long.valueOf(i)) != Boolean.True)
          acc.add(m_values[i]);
      return acc;
    }

    public Boolean any(Func f)
    {
      for (int i=0; i<m_size; i++)
        if (f.call2(m_values[i], Long.valueOf(i)) == Boolean.True)
          return Boolean.True;
      return Boolean.False;
    }

    public Boolean all(Func f)
    {
      for (int i=0; i<m_size; i++)
        if (f.call2(m_values[i], Long.valueOf(i)) != Boolean.True)
          return Boolean.False;
      return Boolean.True;
    }

    public object reduce(object reduction, Func f)
    {
      for (int i=0; i<m_size; i++)
        reduction = f.call3(reduction, m_values[i], Long.valueOf(i));
      return reduction;
    }

    public List map(List acc, Func f)
    {
      if (acc.m_size == 0) acc.capacity(size());
      for (int i=0; i<m_size; i++)
        acc.add(f.call2(m_values[i], Long.valueOf(i)));
      return acc;
    }

    public object max() { return max(null); }
    public object max(Func f)
    {
      if (m_size == 0) return null;
      IComparer c = toComparer(f);
      object max = m_values[0];
      for (int i=1; i<m_size; i++)
        if (c.Compare(m_values[i], max) > 0)
          max = m_values[i];
      return max;
    }

    public object min() { return min(null); }
    public object min(Func f)
    {
      if (m_size == 0) return null;
      IComparer c = toComparer(f);
      object min = m_values[0];
      for (int i=1; i<m_size; i++)
        if (c.Compare(m_values[i], min) < 0)
          min = m_values[i];
      return min;
    }

    public List unique()
    {
      Hashtable dups = new Hashtable(m_size*3);
      List acc = new List(m_of, m_size);
      bool hasNull = false;
      for (int i=0; i<m_size; i++)
      {
        object v = m_values[i];
        if (v == null && !hasNull)
        {
          hasNull = true;
          acc.add(v);
        }
        else if (v != null && dups[v] == null)
        {
          dups[v] = this;
          acc.add(v);
        }
      }
      return acc;
    }

    public List union(List that)
    {
      int capacity = m_size + that.m_size;
      Hashtable dups = new Hashtable(capacity*3);
      List acc = new List(m_of, capacity);
      bool hasNull = false;

      // first me
      for (int i=0; i<m_size; i++)
      {
        object v = m_values[i];
        if (v == null && !hasNull)
        {
          hasNull = true;
          acc.add(v);
        }
        else if (v != null && dups[v] == null)
        {
          dups[v] = this;
          acc.add(v);
        }
      }

      // then him
      for (int i=0; i<that.m_size; i++)
      {
        object v = that.m_values[i];
        if (v == null && !hasNull)
        {
          hasNull = true;
          acc.add(v);
        }
        else if (v != null && dups[v] == null)
        {
          dups[v] = this;
          acc.add(v);
        }
      }

      return acc;
    }

    public List intersection(List that)
    {
      // put other list into map
      Hashtable dups = new Hashtable(that.m_size*3);
      bool hasNull = false;
      for (int i=0; i<that.m_size; ++i)
      {
        object v = that.m_values[i];
        if (v == null) hasNull = true;
        else dups[v] = this;
      }

      // now walk this list and accumulate
      // everything found in the dups map
      List acc = new List(m_of, m_size);
      for (int i=0; i<m_size; i++)
      {
        object v = m_values[i];
        if (v == null && hasNull)
        {
          acc.add(v);
          hasNull = false;
        }
        else if (v != null && dups[v] != null)
        {
          acc.add(v);
          dups.Remove(v);
        }
      }
      return acc;
    }

  //////////////////////////////////////////////////////////////////////////
  // Utils
  //////////////////////////////////////////////////////////////////////////

    public List sort() { return sort(null); }
    public List sort(Func f)
    {
      modify();
      Array.Sort(m_values, 0, m_size, toComparer(f));
      return this;
    }

    public List sortr() { return sortr(null); }
    public List sortr(Func f)
    {
      modify();
      Array.Sort(m_values, 0, m_size, toReverseComparer(f));
      return this;
    }

    public Long binarySearch(object key) { return binarySearch(key, null); }
    public Long binarySearch(object key, Func f)
    {
      IComparer c = toComparer(f);
      object[] values = m_values;
      int low = 0, high = m_size-1;
      while (low <= high)
      {
        int probe = (low + high) >> 1;
        int cmp = c.Compare(values[probe], key);
        if (cmp < 0)
          low = probe + 1;
        else if (cmp > 0)
          high = probe - 1;
        else
          return Long.valueOf(probe);
      }
      return Long.valueOf(-(low + 1));
    }

    public List reverse()
    {
      modify();
      object[] m_values = this.m_values;
      int m_size = this.m_size;
      int mid   = m_size/2;
      for (int i=0; i<mid; i++)
      {
        object a = m_values[i];
        object b = m_values[m_size-i-1];
        m_values[i] = b;
        m_values[m_size-i-1] = a;
      }
      return this;
    }

    public List swap(Long a, Long b)
    {
      // modify in set()
      object temp = get(a);
      set(a, get(b));
      set(b, temp);
      return this;
    }

    public List flatten()
    {
      List acc = new List(Sys.ObjType.toNullable(), m_size*2);
      doFlatten(acc);
      return acc;
    }

    private void doFlatten(List acc)
    {
      for (int i=0; i<m_size; ++i)
      {
        object item = m_values[i];
        if (item is List)
          ((List)item).doFlatten(acc);
        else
          acc.add(item);
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // Conversion
  //////////////////////////////////////////////////////////////////////////

    public string join() { return join(string.Empty, null); }
    public string join(string sep) { return join(sep, null); }
    public string join(string sep, Func f)
    {
      if (m_size == 0) return "";

      if (m_size == 1)
      {
        object v = m_values[0];
        if (f != null) return (string)f.call2(v, FanInt.Zero);
        if (v == null) return "null";
        return toStr(v);
      }

      StringBuilder s = new StringBuilder(32+m_size*32);
      for (int i=0; i<m_size; i++)
      {
        if (i > 0) s.Append(sep);
        if (f == null)
        {
          if (m_values[i] == null) s.Append("null");
          else s.Append(m_values[i]);
        }
        else
        {
          s.Append(f.call2(m_values[i], Long.valueOf(i)));
        }
      }
      return s.ToString();
    }

    public override string toStr()
    {
      if (m_size == 0) return "[,]";
      StringBuilder s = new StringBuilder(32+m_size*32);
      s.Append("[");
      for (int i=0; i<m_size; i++)
      {
        if (i > 0) s.Append(", ");
        if (m_values[i] == null) s.Append("null");
        else s.Append(m_values[i]);
      }
      s.Append("]");
      return s.ToString();
    }

    public void encode(ObjEncoder @out)
    {
      // route back to obj encoder
      @out.writeList(this);
    }

  //////////////////////////////////////////////////////////////////////////
  // Runtime Utils
  //////////////////////////////////////////////////////////////////////////

    public int sz()
    {
      return m_size;
    }

    public object get(int i)
    {
      try
      {
        if (i >= m_size) throw IndexErr.make(""+i).val;
        return m_values[i];
      }
      catch (IndexOutOfRangeException)
      {
        throw IndexErr.make(""+i).val;
      }
    }

    public object[] toArray()
    {
      if (m_values.Length == m_size) return m_values;
      object[] r = new object[m_size];
      Array.Copy(m_values, 0, r, 0, m_size);
      return r;
    }

    public object[] toArray(object[] a)
    {
      try
      {
        Array.Copy(m_values, 0, a, 0, m_size);
        return a;
      }
      catch (IndexOutOfRangeException)
      {
        throw IndexErr.make().val;
      }
    }

    public object[] toArray(object[] a, int start, int len)
    {
      try
      {
        Array.Copy(m_values, start, a, 0, len);
        return a;
      }
      catch (IndexOutOfRangeException)
      {
        throw IndexErr.make().val;
      }
    }

    public object[] copyInto(object[] a, int off, int len)
    {
      try
      {
        Array.Copy(m_values, 0, a, off, len);
        return a;
      }
      catch (IndexOutOfRangeException)
      {
        throw IndexErr.make().val;
      }
    }

    public string[] toStrings()
    {
      string[] a = new string[m_size];
      for (int i=0; i<m_size; ++i)
      {
        object obj = get(i);
        if (obj == null) a[i] = "null";
        else a[i] = toStr(obj);
      }
      return a;
    }

    /*
    public int[] toInts()
    {
      int[] a = new int[size];
      for (int i=0; i<size; ++i) a[i] = ((Long)get(i)).intValue();
      return a;
    }
    */

  //////////////////////////////////////////////////////////////////////////
  // Comparators
  //////////////////////////////////////////////////////////////////////////

    // normal
    static IComparer toComparer(Func f)
    {
      if (f == null) return defaultComparer;
      return new Comparer(f);
    }
    sealed class Comparer : IComparer
    {
      public Comparer(Func f) { this.f = f; }
      public int Compare(object a, object b) { return ((Long)f.call2(a, b)).intValue(); }
      private Func f;
    }
    sealed class DefaultComparer : IComparer
    {
      public int Compare(object a, object b) { return OpUtil.compare(a, b).intValue(); }
    }
    static DefaultComparer defaultComparer = new DefaultComparer();

    // reverse
    static IComparer toReverseComparer(Func f)
    {
      if (f == null) return defaultReverseComparer;
      return new ReverseComparer(f);
    }
    sealed class ReverseComparer : IComparer
    {
      public ReverseComparer(Func f) { this.f = f; }
      public int Compare(object a, object b) { return ((Long)f.call2(b, a)).intValue(); }
      private Func f;
    }
    sealed class DefaultReverseComparer : IComparer
    {
      public int Compare(object a, object b) { return OpUtil.compare(b, a).intValue(); }
    }
    static DefaultReverseComparer defaultReverseComparer = new DefaultReverseComparer();

  //////////////////////////////////////////////////////////////////////////
  // Readonly
  //////////////////////////////////////////////////////////////////////////

    public Boolean isRW()
    {
      return m_isReadonly ? Boolean.False : Boolean.True;
    }

    public Boolean isRO()
    {
      return m_isReadonly ? Boolean.True : Boolean.False;
    }

    public List rw()
    {
      if (!m_isReadonly) return this;

      object[] temp = new object[m_size];
      Array.Copy(m_values, temp, m_size);

      List rw = new List(m_of);
      rw.m_values       = temp;
      rw.m_size         = m_size;
      rw.m_isReadonly   = false;
      rw.m_readonlyList = this;
      return rw;
    }

    public List ro()
    {
      if (m_isReadonly) return this;
      if (m_readonlyList == null)
      {
        List ro = new List(m_of);
        ro.m_values     = m_values;
        ro.m_size       = m_size;
        ro.m_isReadonly = true;
        m_readonlyList  = ro;
      }
      return m_readonlyList;
    }

    public override Boolean isImmutable()
    {
      return Boolean.valueOf(m_immutable);
    }

    public List toImmutable()
    {
      if (m_immutable) return this;

      // make safe copy
      object[] temp = new object[m_size];
      for (int i=0; i<m_size; i++)
      {
        object item = m_values[i];
        if (item != null)
        {
          if (item is List)
            item = ((List)item).toImmutable();
          else if (item is Map)
            item = ((Map)item).toImmutable();
          else if (!isImmutable(item).booleanValue())
            throw NotImmutableErr.make("Item [" + i + "] not immutable " + type(item)).val;
        }
        temp[i] = item;
      }

      // return new immutable list
      List ro = new List(m_of, temp);
      ro.m_isReadonly = true;
      ro.m_immutable = true;
      return ro;
    }

    private void modify()
    {
      // if readonly then throw readonly exception
      if (m_isReadonly)
        throw ReadonlyErr.make("List is readonly").val;

      // if we have a cached readonlyList, then detach
      // it so it remains immutable
      if (m_readonlyList != null)
      {
        object[] temp = new object[m_size];
        Array.Copy(m_values, temp, m_size);
        m_readonlyList.m_values = temp;
        m_readonlyList = null;
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    private static readonly object[] m_empty = new object[0];

    private Type m_of;
    private object[] m_values;
    private int m_size;
    private bool m_isReadonly;
    private bool m_immutable;
    private List m_readonlyList;

  }
}