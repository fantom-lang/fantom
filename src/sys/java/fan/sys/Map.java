//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   17 Mar 06  Brian Frank  Creation
//
package fan.sys;

import java.lang.Thread;
import java.util.AbstractSet;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Map.Entry;
import java.util.LinkedHashMap;
import java.util.Iterator;
import java.util.Set;
import fanx.serial.*;
import fanx.util.OpUtil;

/**
 * Map is a hashmap of key value pairs.
 */
public final class Map
  extends FanObj
  implements Literal
{

//////////////////////////////////////////////////////////////////////////
// Constructors
//////////////////////////////////////////////////////////////////////////

  public static Map make(Type type)
  {
    return new Map((MapType)type, new HashMap());
  }

  public Map(Type k, Type v)
  {
    this(new MapType(k, v), new HashMap());
  }

  public Map(MapType type)
  {
    this(type, new HashMap());
  }

  public Map(MapType type, HashMap map)
  {
    if (type == null || map == null) { Thread.dumpStack(); throw NullErr.make(); }
    this.type = type;
    this.map  = map;
  }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  public final Type typeof()
  {
    return type;
  }

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  public final boolean isEmpty()
  {
    return map.size() == 0;
  }

  public final long size()
  {
    return map.size();
  }

  public final Object get(Object key)
  {
    Object val = map.get(key);
    if (val != null) return val;
    if (this.def == null) return null;
    return map.containsKey(key) ? null : this.def;
  }

  public final Object get(Object key, Object def)
  {
    Object val = map.get(key);
    if (val != null) return val;
    if (def == null) return null;
    return map.containsKey(key) ? null : def;
  }

  public final boolean containsKey(Object key)
  {
    return map.containsKey(key);
  }

  public final List keys()
  {
    Object[] keys = new Object[map.size()];
    Iterator it = pairsIterator();
    for (int i=0; it.hasNext(); ++i)
      keys[i] = ((Entry)it.next()).getKey();
    return new List(type.k, keys);
  }

  public final List vals()
  {
    return new List(type.v, map.values());
  }

  public final Map set(Object key, Object value)
  {
    modify();
    if (key == null)
      throw NullErr.make("key is null");
    if (!isImmutable(key))
      throw NotImmutableErr.make("key is not immutable: " + typeof(key));
    map.put(key, value);
    return this;
  }

  public final Map add(Object key, Object value)
  {
    modify();
    if (key == null)
      throw NullErr.make("key is null");
    if (!isImmutable(key))
      throw NotImmutableErr.make("key is not immutable: " + typeof(key));
    if (map.containsKey(key))
      throw ArgErr.make("Key already mapped: " + key);
    map.put(key, value);
    return this;
  }

  public final Object getOrAdd(Object key, Func valFunc)
  {
    if (map.containsKey(key)) return map.get(key);
    Object val = valFunc.call(key);
    add(key, val);
    return val;
  }

  public final Map setAll(Map m)
  {
    modify();
    Iterator it = m.pairsIterator();
    while (it.hasNext())
    {
      Entry e = (Entry)it.next();
      map.put(e.getKey(), e.getValue());
    }
    return this;
  }

  public final Map addAll(Map m)
  {
    modify();
    Iterator it = m.pairsIterator();
    while (it.hasNext())
    {
      Entry e = (Entry)it.next();
      add(e.getKey(), e.getValue());
    }
    return this;
  }

  public final Map setList(List list) { return setList(list, null); }
  public final Map setList(List list, Func f)
  {
    modify();
    if (f == null)
    {
      for (int i=0; i<list.sz(); ++i)
        set(list.get(i), list.get(i));
    }
    else if (f.arity() == 1)
    {
      for (int i=0; i<list.sz(); ++i)
        set(f.call(list.get(i)), list.get(i));
    }
    else
    {
      for (int i=0; i<list.sz(); ++i)
        set(f.call(list.get(i), Long.valueOf(i)), list.get(i));
    }
    return this;
  }

  public final Map addList(List list) { return addList(list, null); }
  public final Map addList(List list, Func f)
  {
    modify();
    if (f == null)
    {
      for (int i=0; i<list.sz(); ++i)
        add(list.get(i), list.get(i));
    }
    else if (f.arity() == 1)
    {
      for (int i=0; i<list.sz(); ++i)
        add(f.call(list.get(i)), list.get(i));
    }
    else
    {
      for (int i=0; i<list.sz(); ++i)
        add(f.call(list.get(i), Long.valueOf(i)), list.get(i));
    }
    return this;
  }

  public final Object remove(Object key)
  {
    modify();
    return map.remove(key);
  }

  public final Map dup()
  {
    Map dup = new Map(type);
    dup.map = (HashMap)this.map.clone();
    return dup;
  }

  public final Map clear()
  {
    modify();
    map.clear();
    return this;
  }

  public final boolean caseInsensitive()
  {
    return map instanceof CIHashMap;
  }

  public final void caseInsensitive(boolean v)
  {
    modify();

    if (type.k != Sys.StrType)
      throw UnsupportedErr.make("Map not keyed by Str: " + type);

    if (map.size() != 0)
      throw UnsupportedErr.make("Map not empty");

    if (v && ordered())
      throw UnsupportedErr.make("Map cannot be caseInsensitive and ordered");

    if (caseInsensitive() == v) return;

    if (v)
      map = new CIHashMap();
    else
      map = new HashMap();
  }

  public final boolean ordered()
  {
    return map instanceof LinkedHashMap;
  }

  public final void ordered(boolean v)
  {
    modify();

    if (map.size() != 0)
      throw UnsupportedErr.make("Map not empty");

    if (v && caseInsensitive())
      throw UnsupportedErr.make("Map cannot be caseInsensitive and ordered");

    if (ordered() == v) return;

    if (v)
      map = new LinkedHashMap();
    else
      map = new HashMap();
  }

  public final Object def() { return def; }
  public final void def(Object v)
  {
    modify();
    if (v != null && !isImmutable(v))
      throw NotImmutableErr.make("def must be immutable: " + typeof(v));
    this.def = v;
  }

  public final boolean equals(Object that)
  {
    if (that instanceof Map)
    {
      return type.equals(typeof(that)) && map.equals(((Map)that).map);
    }
    return false;
  }

  public final long hash()
  {
    return map.hashCode();
  }

  public final String toStr()
  {
    if (map.size() == 0) return "[:]";
    StringBuilder s = new StringBuilder(32+map.size()*32);
    s.append("[");
    boolean first = true;
    Iterator it = pairsIterator();
    while (it.hasNext())
    {
      Entry e = (Entry)it.next();
      if (!first) s.append(", ");
      else first = false;
      s.append(e.getKey()).append(':').append(e.getValue());
    }
    s.append("]");
    return s.toString();
  }

  public final void encode(ObjEncoder out)
  {
    // route back to obj encoder
    out.writeMap(this);
  }

//////////////////////////////////////////////////////////////////////////
// Iterators
//////////////////////////////////////////////////////////////////////////

  public final void each(Func f)
  {
    Iterator it = pairsIterator();
    while (it.hasNext())
    {
      Entry e = (Entry)it.next();
      f.call(e.getValue(), e.getKey());
    }
  }

  public final Object eachWhile(Func f)
  {
    Iterator it = pairsIterator();
    while (it.hasNext())
    {
      Entry e = (Entry)it.next();
      Object r = f.call(e.getValue(), e.getKey());
      if (r != null) return r;
    }
    return null;
  }

  public final Object find(Func f)
  {
    Iterator it = pairsIterator();
    while (it.hasNext())
    {
      Entry e = (Entry)it.next();
      Object key = e.getKey();
      Object val = e.getValue();
      if (f.callBool(val, key))
        return val;
    }
    return null;
  }

  public final Map findAll(Func f)
  {
    Map acc = new Map(type);
    Iterator it = pairsIterator();
    while (it.hasNext())
    {
      Entry e = (Entry)it.next();
      Object key = e.getKey();
      Object val = e.getValue();
      if (f.callBool(val, key))
        acc.set(key, val);
    }
    return acc;
  }

  public final Map exclude(Func f)
  {
    Map acc = new Map(type);
    Iterator it = pairsIterator();
    while (it.hasNext())
    {
      Entry e = (Entry)it.next();
      Object key = e.getKey();
      Object val = e.getValue();
      if (!f.callBool(val, key))
        acc.set(key, val);
    }
    return acc;
  }

  public final boolean any(Func f)
  {
    if (map.size() == 0) return false;
    Iterator it = pairsIterator();
    while (it.hasNext())
    {
      Entry e = (Entry)it.next();
      Object key = e.getKey();
      Object val = e.getValue();
      if (f.callBool(val, key))
        return true;
    }
    return false;
  }

  public final boolean all(Func f)
  {
    if (map.size() == 0) return true;
    Iterator it = pairsIterator();
    while (it.hasNext())
    {
      Entry e = (Entry)it.next();
      Object key = e.getKey();
      Object val = e.getValue();
      if (!f.callBool(val, key))
        return false;
    }
    return true;
  }

  public final Object reduce(Object reduction, Func f)
  {
    Iterator it = pairsIterator();
    while (it.hasNext())
    {
      Entry e = (Entry)it.next();
      Object key = e.getKey();
      Object val = e.getValue();
      reduction = f.call(reduction, val, key);
    }
    return reduction;
  }

  public final Map map(Func f)
  {
    Type r = f.returns();
    if (r == Sys.VoidType) r = Sys.ObjType.toNullable();
    Map acc = new Map(type.k, r);
    if (this.ordered()) acc.ordered(true);
    if (this.caseInsensitive()) acc.caseInsensitive(true);
    Iterator it = pairsIterator();
    while (it.hasNext())
    {
      Entry e = (Entry)it.next();
      Object key = e.getKey();
      Object val = e.getValue();
      acc.set(key, f.call(val, key));
    }
    return acc;
  }

//////////////////////////////////////////////////////////////////////////
// Conversion
//////////////////////////////////////////////////////////////////////////

  public final String join(String sep) { return join(sep, null); }
  public final String join(String sep, Func f)
  {
    int size = (int)size();
    if (size == 0) return "";
    StringBuilder s = new StringBuilder(32+size*32);
    Iterator it = pairsIterator();
    while (it.hasNext())
    {
      Entry e = (Entry)it.next();
      Object key = e.getKey();
      Object val = e.getValue();
      if (s.length() > 0) s.append(sep);
      if (f == null)
        s.append(key).append(": ").append(val);
      else
        s.append(f.call(val, key));
    }
    return s.toString();
  }

  public final String toCode()
  {
    int size = (int)size();
    StringBuilder s = new StringBuilder(32+size*32);
    s.append(type.signature());
    s.append('[');
    if (size == 0) s.append(':');
    Iterator it = pairsIterator();
    boolean first = true;
    while (it.hasNext())
    {
      Entry e = (Entry)it.next();
      Object key = e.getKey();
      Object val = e.getValue();
      if (first) first = false;
      else s.append(',').append(' ');
      s.append(FanObj.trap(key, "toCode", null))
       .append(':')
       .append(FanObj.trap(val, "toCode", null));
    }
    s.append(']');
    return s.toString();
  }

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

  public final Map rw()
  {
    if (!readonly) return this;

    Map rw = new Map(type);
    rw.map = (HashMap)map.clone();
    rw.readonly = false;
    rw.readonlyMap = this;
    rw.def = def;
    return rw;
  }

  public final Map ro()
  {
    if (readonly) return this;
    if (readonlyMap == null)
    {
      Map ro = new Map(type);
      ro.map = map;
      ro.def = def;
      ro.readonly = true;
      readonlyMap = ro;
    }
    return readonlyMap;
  }

  public final boolean isImmutable()
  {
    return immutable;
  }

  public final Object toImmutable()
  {
    if (immutable) return this;

    // allocate new map of correct type
    HashMap temp;
    if (caseInsensitive()) temp = new CIHashMap(map.size()*2+3);
    else if (ordered()) temp = new LinkedHashMap(map.size()*2+3);
    else temp = new HashMap(map.size()*2+3);

    // make safe copy
    Iterator it = pairsIterator();
    while (it.hasNext())
    {
      Entry e = (Entry)it.next();
      Object key = e.getKey();
      Object val = e.getValue();

      if (val != null)
        val = FanObj.toImmutable(val);

      temp.put(key, val);
    }

    // return new immutable map
    Map ro = new Map(type, temp);
    ro.readonly = true;
    ro.immutable = true;
    ro.def = def;
    return ro;
  }

  private void modify()
  {
    // if readonly then throw readonly exception
    if (readonly)
      throw ReadonlyErr.make("Map is readonly");

    // if we have a cached readonlyMap, then detach
    // it so it remains immutable
    if (readonlyMap != null)
    {
      readonlyMap.map = (HashMap)map.clone();
      readonlyMap = null;
    }
  }

//////////////////////////////////////////////////////////////////////////
// Java
//////////////////////////////////////////////////////////////////////////

  public int sz() { return map.size(); }

  public Iterator pairsIterator()
  {
    if (map instanceof CIHashMap)
      return ((CIHashMap)map).pairs().iterator();
    else
      return map.entrySet().iterator();
  }

  public Iterator keysIterator()
  {
    return map.keySet().iterator();
  }

  public HashMap toJava()
  {
    modify();
    return map;
  }

//////////////////////////////////////////////////////////////////////////
// CIHashMap (Case Insensitive)
//////////////////////////////////////////////////////////////////////////

  static class CIHashMap extends HashMap
  {
    public CIHashMap() {}
    public CIHashMap(int capacity) { super(capacity); }
    public Object get(Object key) { return super.get(new CIKey((String)key)); }
    public boolean containsKey(Object key) { return super.containsKey(new CIKey((String)key)); }
    public Object put(Object key, Object val) { return super.put(new CIKey((String)key), val); }
    public Object remove(Object key) { return super.remove(new CIKey((String)key)); }
    public Set keySet() { throw new UnsupportedOperationException(); }
    public Set pairs() { return new CIPairs(entrySet()); }

    public int hashCode()
    {
      int hash = 0;
      Iterator it = pairs().iterator();
      while (it.hasNext())
        hash += it.next().hashCode();
      return hash;
    }

    public boolean equals(Object obj)
    {
      if (!(obj instanceof HashMap)) return false;
      HashMap that = (HashMap)obj;
      if (size() != that.size()) return false;
      Iterator it = pairs().iterator();
      while (it.hasNext())
      {
        CIEntry entry = (CIEntry)it.next();
        Object thatVal = that.get(entry.key);
        if (!OpUtil.compareEQ(entry.val, thatVal)) return false;
      }
      return true;
    }
  }

  static final class CIPairs extends AbstractSet
  {
    CIPairs(Set set) { this.set = set; }
    public int size() { return set.size(); }
    public Iterator iterator() { return new CIPairsIterator(set.iterator()); }
    Set set;
  }

  static final class CIPairsIterator implements Iterator
  {
    CIPairsIterator(Iterator it) { this.it = it; }
    public boolean hasNext() { return it.hasNext(); }
    public Object next() { entry.set((Entry)it.next()); return entry; }
    public void remove() { it.remove(); }
    Iterator it;
    CIEntry entry = new CIEntry();
  }

  static final class CIEntry implements Entry
  {
    public void set(Entry e) { key = ((CIKey)e.getKey()).key; val = e.getValue(); }
    public Object getKey() { return key; }
    public Object getValue() { return val; }
    public int hashCode() { return key.hashCode() ^ (val == null ? 0 : val.hashCode()); }
    public boolean equals(Object o) { throw new UnsupportedOperationException(); }
    public Object setValue(Object v) { throw new UnsupportedOperationException(); }
    String key;
    Object val;
  }

  static final class CIKey
  {
    CIKey(String key) { this.key = key; this.hash = FanStr.caseInsensitiveHash(key); }
    public final int hashCode() { return hash; }
    public final boolean equals(Object obj) { return FanStr.equalsIgnoreCase(key, ((CIKey)obj).key); }
    public final String toString() { return key; }
    final String key;
    final int hash;
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private MapType type;
  private HashMap map;
  private Map readonlyMap;
  private boolean readonly;
  private boolean immutable;
  private Object def;

}