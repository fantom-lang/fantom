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
import java.util.Collection;
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
public final class Map<K,V>
  extends FanObj
  implements Literal, java.util.Map<K,V>
{

//////////////////////////////////////////////////////////////////////////
// Constructors
//////////////////////////////////////////////////////////////////////////

  public static Map make(Type type)
  {
    MapType t = null;
    try
    {
      t = (MapType)type;
    }
    catch (ClassCastException e)
    {
      throw ArgErr.make("Non-nullable map type required: " + type);
    }
    if (t.k.isNullable()) throw ArgErr.make("Map key type cannot be nullable: " + t.k);
    return new Map(t, new HashMap());
  }

  /** Construct map with given key and value types */
  public static Map make(Type k, Type v)
  {
    return new Map(k, v);
  }

  Map(Type k, Type v)
  {
    this(new MapType(k, v), new HashMap());
  }

  Map(MapType type)
  {
    this(type, new HashMap());
  }

  Map(MapType type, HashMap map)
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

  MapType type()
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

  public final long _size()
  {
    return map.size();
  }

  public final V get(Object key)
  {
    V val = map.get(key);
    if (val != null) return val;
    if (this.def == null) return null;
    return map.containsKey(key) ? null : this.def;
  }

  public final V get(K key, V def)
  {
    V val = map.get(key);
    if (val != null) return val;
    if (def == null) return null;
    return map.containsKey(key) ? null : def;
  }

  public final V getChecked(K key) { return getChecked(key, true); }
  public final V getChecked(K key, boolean checked)
  {
    V val = map.get(key);
    if (val != null) return val;
    if (map.containsKey(key)) return null;
    if (checked) throw UnknownKeyErr.make(String.valueOf(key));
    return null;
  }

  public final V getOrThrow(K key)
  {
    V val = map.get(key);
    if (val != null) return val;
    if (map.containsKey(key)) return null;
    throw UnknownKeyErr.make(String.valueOf(key));
  }

  public final boolean containsKey(Object key)
  {
    return map.containsKey(key);
  }

  public final List<K> keys()
  {
    Object[] keys = new Object[map.size()];
    Iterator it = pairsIterator();
    for (int i=0; it.hasNext(); ++i)
      keys[i] = ((Entry)it.next()).getKey();
    return new List(type.k, keys);
  }

  public final List<V> vals()
  {
    return new List(type.v, map.values());
  }

  public final Map<K,V> set(K key, V value)
  {
    modify();
    if (key == null)
      throw NullErr.make("key is null");
    if (!isImmutable(key))
      throw NotImmutableErr.make("key is not immutable: " + typeof(key));
    map.put(key, value);
    return this;
  }

  public final Map<K,V> setNotNull(K key, V value)
  {
    if (value == null) return this;
    return set(key, value);
  }

  public final Map<K,V> add(K key, V value)
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

  public final Map<K,V> addIfNotNull(K key, V value)
  {
    return addNotNull(key, value);
  }

  public final Map<K,V> addNotNull(K key, V value)
  {
    if (value == null) return this;
    return add(key, value);
  }

  public final V getOrAdd(K key, Func valFunc)
  {
    if (map.containsKey(key)) return map.get(key);
    V val = (V)valFunc.call(key);
    add(key, val);
    return val;
  }

  public final Map<K,V> setAll(Map<K,V> m)
  {
    modify();
    Iterator it = m.pairsIterator();
    while (it.hasNext())
    {
      Entry<K,V> e = (Entry)it.next();
      map.put(e.getKey(), e.getValue());
    }
    return this;
  }

  public final Map<K,V> addAll(Map<K,V> m)
  {
    modify();
    Iterator it = m.pairsIterator();
    while (it.hasNext())
    {
      Entry<K,V> e = (Entry)it.next();
      add(e.getKey(), e.getValue());
    }
    return this;
  }

  public final Map<K,V> setList(List<V> list) { return setList(list, null); }
  public final Map<K,V> setList(List<V> list, Func f)
  {
    modify();
    if (f == null)
    {
      for (int i=0; i<list.sz(); ++i)
        set((K)list.get(i), list.get(i));
    }
    else if (f.arity() == 1)
    {
      for (int i=0; i<list.sz(); ++i)
        set((K)f.call(list.get(i)), list.get(i));
    }
    else
    {
      for (int i=0; i<list.sz(); ++i)
        set((K)f.call(list.get(i), Long.valueOf(i)), list.get(i));
    }
    return this;
  }

  public final Map<K,V> addList(List<V> list) { return addList(list, null); }
  public final Map<K,V> addList(List<V> list, Func f)
  {
    modify();
    if (f == null)
    {
      for (int i=0; i<list.sz(); ++i)
        add((K)list.get(i), list.get(i));
    }
    else if (f.arity() == 1)
    {
      for (int i=0; i<list.sz(); ++i)
        add((K)f.call(list.get(i)), list.get(i));
    }
    else
    {
      for (int i=0; i<list.sz(); ++i)
        add((K)f.call(list.get(i), Long.valueOf(i)), list.get(i));
    }
    return this;
  }

  public final V remove(Object key)
  {
    modify();
    return map.remove(key);
  }

  public final Map<K,V> dup()
  {
    Map dup = new Map(type);
    dup.map = (HashMap)this.map.clone();
    return dup;
  }

  public final Map<K,V> _clear()
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

  public final V def() { return def; }
  public final void def(V v)
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

  public final V find(Func f)
  {
    Iterator it = pairsIterator();
    while (it.hasNext())
    {
      Entry<K,V> e = (Entry)it.next();
      K key = e.getKey();
      V val = e.getValue();
      if (f.callBool(val, key))
        return val;
    }
    return null;
  }

  public final Map<K,V> findAll(Func f)
  {
    Map acc = new Map(type);
    if (this.ordered()) acc.ordered(true);
    if (this.caseInsensitive()) acc.caseInsensitive(true);
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

  public final Map<K,V> findNotNull()
  {
    Map acc = new Map(type.k, type.v.toNonNullable());
    if (this.ordered()) acc.ordered(true);
    if (this.caseInsensitive()) acc.caseInsensitive(true);
    Iterator it = pairsIterator();
    while (it.hasNext())
    {
      Entry e = (Entry)it.next();
      Object key = e.getKey();
      Object val = e.getValue();
      if (val != null)
        acc.set(key, val);
    }
    return acc;
  }

  public final Map<K,V> exclude(Func f)
  {
    Map acc = new Map(type);
    if (this.ordered()) acc.ordered(true);
    if (this.caseInsensitive()) acc.caseInsensitive(true);
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

  public final Map mapNotNull(Func f)
  {
    Type r = f.returns();
    if (r == Sys.VoidType) r = Sys.ObjType;
    Map acc = new Map(type.k, r.toNonNullable());
    if (this.ordered()) acc.ordered(true);
    if (this.caseInsensitive()) acc.caseInsensitive(true);
    Iterator it = pairsIterator();
    while (it.hasNext())
    {
      Entry e = (Entry)it.next();
      Object key = e.getKey();
      Object val = e.getValue();
      acc.addNotNull(key, f.call(val, key));
    }
    return acc;
  }

//////////////////////////////////////////////////////////////////////////
// Conversion
//////////////////////////////////////////////////////////////////////////

  public final String join(String sep) { return join(sep, null); }
  public final String join(String sep, Func f)
  {
    int size = size();
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
    int size = size();
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

  public final Map<K,V> rw()
  {
    if (!readonly) return this;

    Map rw = new Map(type);
    rw.map = (HashMap)map.clone();
    rw.readonly = false;
    rw.readonlyMap = this;
    rw.def = def;
    return rw;
  }

  public final Map<K,V> ro()
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

  /** Direct access to underlying hashmap */
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
    public Set pairs() { return new CIPairs(entrySet()); }

    public Set keySet()
    {
      java.util.HashSet keys = new java.util.HashSet();
      Iterator it = pairs().iterator();
      while (it.hasNext())
      {
        CIEntry entry = (CIEntry)it.next();
        keys.add(entry.key);
      }
      return keys;
    }

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
// java.util.Map
//////////////////////////////////////////////////////////////////////////

  public final int size()
  {
    return map.size();
  }

  public boolean containsValue(Object val)
  {
    return map.containsValue(val);
  }

  public V put(K key, V val)
  {
    V old = get(key);
    set(key, val);
    return old;
  }

  public void putAll(java.util.Map<? extends K,? extends V> m)
  {
    for (Map.Entry<K,V> e : map.entrySet())
    {
      set(e.getKey(), e.getValue());
    }
  }

  public final void clear()
  {
    _clear();
  }

  public Collection<V> values()
  {
    return map.values();
  }

  public Set<K> keySet()
  {
    return map.keySet();
  }

  public Set<Map.Entry<K,V>> entrySet()
  {
    return map.entrySet();
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private MapType type;
  private HashMap<K,V> map;
  private Map<K,V> readonlyMap;
  private boolean readonly;
  private boolean immutable;
  private V def;

}

