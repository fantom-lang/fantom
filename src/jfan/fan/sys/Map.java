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
    return new Map((MapType)type, new FanHashMap());
  }

  public Map(Type k, Type v)
  {
    this(new MapType(k, v), new FanHashMap());
  }

  public Map(MapType type)
  {
    this(type, new FanHashMap());
  }

  public Map(MapType type, FanHashMap map)
  {
    if (type == null || map == null) { Thread.dumpStack(); throw new NullErr().val; }
    this.type = type;
    this.map  = map;
  }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  public final Type type()
  {
    return type;
  }

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  public final Bool isEmpty()
  {
    return map.size() == 0 ? Bool.True : Bool.False;
  }

  public final Int size()
  {
    return Int.pos(map.size());
  }

  public final Obj get(Obj key)
  {
    Obj val = (Obj)map.get(key);
    if (val != null) return val;
    return this.def;
  }

  public final Obj get(Obj key, Obj def)
  {
    Obj val = (Obj)map.get(key);
    if (val != null) return val;
    return def;
  }

  public final Bool containsKey(Obj key)
  {
    return Bool.make(map.containsKey(key));
  }

  public final List keys()
  {
    Obj[] keys = new Obj[map.size()];
    Iterator it = map.pairs().iterator();
    for (int i=0; it.hasNext(); ++i)
      keys[i] = (Obj)((Entry)it.next()).getKey();
    return new List(type.k, keys);
  }

  public final List values()
  {
    return new List(type.v, map.values());
  }

  public final Map set(Obj key, Obj value)
  {
    modify();
    if (key == null)
      throw NullErr.make("key is null").val;
    if (!isImmutable(key).val)
      throw NotImmutableErr.make("key is not immutable: " + type(key)).val;
    map.put(key, value);
    return this;
  }

  public final Map add(Obj key, Obj value)
  {
    modify();
    if (key == null)
      throw NullErr.make("key is null").val;
    if (!isImmutable(key).val)
      throw NotImmutableErr.make("key is not immutable: " + type(key)).val;
    Object old = map.put(key, value);
    if (old != null)
    {
      map.put(key, old);
      throw ArgErr.make("Key already mapped: " + key).val;
    }
    return this;
  }

  public final Map setAll(Map m)
  {
    modify();
    Iterator it = m.map.pairs().iterator();
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
    Iterator it = m.map.pairs().iterator();
    while (it.hasNext())
    {
      Entry e = (Entry)it.next();
      add((Obj)e.getKey(), (Obj)e.getValue());
    }
    return this;
  }

  public final Obj remove(Obj key)
  {
    modify();
    return (Obj)map.remove(key);
  }

  public final Map dup()
  {
    Map dup = new Map(type);
    dup.map = (FanHashMap)this.map.clone();
    return dup;
  }

  public final void clear()
  {
    modify();
    map.clear();
  }

  public final Bool caseInsensitive() { return Bool.make(caseInsensitive); }
  public final void caseInsensitive(Bool v)
  {
    modify();

    if (type.k != Sys.StrType)
      throw UnsupportedErr.make("Map not keyed by Str: " + type).val;

    if (map.size() != 0)
      throw UnsupportedErr.make("Map not empty").val;

    if (this.caseInsensitive == v.val) return;
    this.caseInsensitive = v.val;

    if (caseInsensitive)
      map = new CIHashMap();
    else
      map = new FanHashMap();
  }

  public final Obj def() { return def; }
  public final void def(Obj v)
  {
    modify();
    if (v != null && !isImmutable(v).val)
      throw NotImmutableErr.make("def must be immutable: " + type(v)).val;
    this.def = v;
  }

  public final Bool _equals(Obj that)
  {
    if (that instanceof Map)
    {
      return Bool.make(type.equals(type(that)) &&
                       map.equals(((Map)that).map));
    }
    return Bool.False;
  }

  public final Int hash()
  {
    return Int.make(map.hashCode());
  }

  public final Str toStr()
  {
    if (map.size() == 0) return Str.make("[:]");
    StringBuilder s = new StringBuilder(32+map.size()*32);
    s.append("[");
    boolean first = true;
    Iterator it = map.pairs().iterator();
    while (it.hasNext())
    {
      Entry e = (Entry)it.next();
      if (!first) s.append(", ");
      else first = false;
      s.append(e.getKey()).append(':').append(e.getValue());
    }
    s.append("]");
    return Str.make(s.toString());
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
    Iterator it = map.pairs().iterator();
    while (it.hasNext())
    {
      Entry e = (Entry)it.next();
      f.call2((Obj)e.getValue(), (Obj)e.getKey());
    }
  }

  public final Obj eachBreak(Func f)
  {
    Iterator it = map.pairs().iterator();
    while (it.hasNext())
    {
      Entry e = (Entry)it.next();
      Obj r = f.call2((Obj)e.getValue(), (Obj)e.getKey());
      if (r != null) return r;
    }
    return null;
  }

  public final Obj find(Func f)
  {
    Iterator it = map.pairs().iterator();
    while (it.hasNext())
    {
      Entry e = (Entry)it.next();
      Obj key = (Obj)e.getKey();
      Obj val = (Obj)e.getValue();
      if (f.call2(val, key) == Bool.True)
        return val;
    }
    return null;
  }

  public final Map findAll(Func f)
  {
    Map acc = new Map(type);
    Iterator it = map.pairs().iterator();
    while (it.hasNext())
    {
      Entry e = (Entry)it.next();
      Obj key = (Obj)e.getKey();
      Obj val = (Obj)e.getValue();
      if (f.call2(val, key) == Bool.True)
        acc.set(key, val);
    }
    return acc;
  }

  public final Map exclude(Func f)
  {
    Map acc = new Map(type);
    Iterator it = map.pairs().iterator();
    while (it.hasNext())
    {
      Entry e = (Entry)it.next();
      Obj key = (Obj)e.getKey();
      Obj val = (Obj)e.getValue();
      if (f.call2(val, key) == Bool.False)
        acc.set(key, val);
    }
    return acc;
  }

  public final Obj reduce(Obj reduction, Func f)
  {
    Iterator it = map.pairs().iterator();
    while (it.hasNext())
    {
      Entry e = (Entry)it.next();
      Obj key = (Obj)e.getKey();
      Obj val = (Obj)e.getValue();
      reduction = f.call3(reduction, val, key);
    }
    return reduction;
  }

  public final Map map(Map acc, Func f)
  {
    Iterator it = map.pairs().iterator();
    while (it.hasNext())
    {
      Entry e = (Entry)it.next();
      Obj key = (Obj)e.getKey();
      Obj val = (Obj)e.getValue();
      acc.set(key, f.call2(val, key));
    }
    return acc;
  }

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

  public final Map rw()
  {
    if (!readonly) return this;

    Map rw = new Map(type);
    rw.map = (FanHashMap)map.clone();
    rw.readonly = false;
    rw.readonlyMap = this;
    rw.caseInsensitive = caseInsensitive;
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
      ro.caseInsensitive = caseInsensitive;
      ro.def = def;
      ro.readonly = true;
      readonlyMap = ro;
    }
    return readonlyMap;
  }

  public final Bool isImmutable()
  {
    return Bool.make(immutable);
  }

  public final Map toImmutable()
  {
    if (immutable) return this;

    // make safe copy
    FanHashMap temp = caseInsensitive ? new CIHashMap() : new FanHashMap();
    Iterator it = map.pairs().iterator();
    while (it.hasNext())
    {
      Entry e = (Entry)it.next();
      Obj key = (Obj)e.getKey();
      Obj val = (Obj)e.getValue();

      if (val != null)
      {
        // TODO Obj.toImmutable
        if (val instanceof List)
          val = ((List)val).toImmutable();
        else if (val instanceof Map)
          val = ((Map)val).toImmutable();
        else if (!isImmutable(val).val)
          throw NotImmutableErr.make("Item [" + key + "] not immutable " + type(val)).val;
      }

      temp.put(key, val);
    }

    // return new immutable map
    Map ro = new Map(type, temp);
    ro.readonly = true;
    ro.immutable = true;
    ro.caseInsensitive = caseInsensitive;
    ro.def = def;
    return ro;
  }

  private void modify()
  {
    // if readonly then throw readonly exception
    if (readonly)
      throw ReadonlyErr.make("Map is readonly").val;

    // if we have a cached readonlyMap, then detach
    // it so it remains immutable
    if (readonlyMap != null)
    {
      readonlyMap.map = (FanHashMap)map.clone();
      readonlyMap = null;
    }
  }

//////////////////////////////////////////////////////////////////////////
// Java
//////////////////////////////////////////////////////////////////////////

  public Iterator pairsIterator()
  {
    return map.pairs().iterator();
  }

  public Iterator keysIterator()
  {
    return map.keySet().iterator();
  }

//////////////////////////////////////////////////////////////////////////
// FanHashMap
//////////////////////////////////////////////////////////////////////////

  public static class FanHashMap extends HashMap
  {
    public Set pairs() { return entrySet(); }
  }

//////////////////////////////////////////////////////////////////////////
// CIHashMap (Case Insensitive)
//////////////////////////////////////////////////////////////////////////

  static class CIHashMap extends FanHashMap
  {
    public Object get(Object key) { return super.get(new CIKey((Str)key)); }
    public boolean containsKey(Object key) { return super.containsKey(new CIKey((Str)key)); }
    public Object put(Object key, Object val) { return super.put(new CIKey((Str)key), val); }
    public Object remove(Object key) { return super.remove(new CIKey((Str)key)); }
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
      if (!(obj instanceof FanHashMap)) return false;
      FanHashMap that = (FanHashMap)obj;
      if (size() != that.size()) return false;
      Iterator it = pairs().iterator();
      while (it.hasNext())
      {
        CIEntry entry = (CIEntry)it.next();
        Object thatVal = that.get(entry.key);
        if (!OpUtil.compareEQz((Obj)entry.val, (Obj)thatVal)) return false;
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
    Str key;
    Object val;
  }

  static final class CIKey
  {
    CIKey(Str key) { this.key  = key; this.hash = key.caseInsensitiveHash(); }
    public final int hashCode() { return hash; }
    public final boolean equals(Object obj) { return key.equalsIgnoreCase(((CIKey)obj).key).val; }
    public final String toString() { return key.val; }
    final Str key;
    final int hash;
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private MapType type;
  private FanHashMap map;
  private Map readonlyMap;
  private boolean readonly;
  private boolean immutable;
  private boolean caseInsensitive;
  private Obj def;

}