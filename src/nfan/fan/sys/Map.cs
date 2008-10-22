//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   28 Sep 06  Andy Frank  Creation
//

using System;
using System.Collections;
using System.Diagnostics;
using System.Text;
using Fanx.Serial;

namespace Fan.Sys
{
  /// <summary>
  /// Map is a hashm_map of key value pairs.
  /// </summary>
  public sealed class Map : FanObj, Literal
  {

  //////////////////////////////////////////////////////////////////////////
  // Constructors
  //////////////////////////////////////////////////////////////////////////

    public static Map make(Type type)
    {
      return new Map((MapType)type, new Hashtable());
    }

    public Map(Type k, Type v) : this(new MapType(k, v), new Hashtable())
    {
    }

    public Map(MapType type) : this(type, new Hashtable())
    {
    }

    public Map(MapType type, Hashtable map)
    {
      if (type == null || map == null)
      {
        Console.WriteLine(new StackTrace(true));
        throw new NullErr().val;
      }

      this.m_type = type;
      this.m_map  = map;
    }

  //////////////////////////////////////////////////////////////////////////
  // Identity
  //////////////////////////////////////////////////////////////////////////

    public override Type type()
    {
      return m_type;
    }

  //////////////////////////////////////////////////////////////////////////
  // Methods
  //////////////////////////////////////////////////////////////////////////

    public Boolean isEmpty()
    {
      return m_map.Count == 0 ? Boolean.True : Boolean.False;
    }

    public Long size()
    {
      return Long.valueOf(m_map.Count);
    }

    public object get(object key)
    {
      if (key == null) return m_def;
      object val = m_map[key];
      if (val != null) return val;
      return m_def;
    }

    public object get(object key, object def)
    {
      if (key == null) return def;
      object val = m_map[key];
      if (val != null) return val;
      return def;
    }

    public Boolean containsKey(object key)
    {
      return (key == null) ? Boolean.False : Boolean.valueOf(m_map.ContainsKey(key));
    }

    public List keys()
    {
      return new List(m_type.m_k, m_map.Keys);
    }

    public List values()
    {
      return new List(m_type.m_v, m_map.Values);
    }

    public Map set(object key, object val)
    {
      modify();
      if (key == null)
        throw NullErr.make("key is null").val;
      if (!isImmutable(key).booleanValue())
        throw NotImmutableErr.make("key is not immutable: " + type(key)).val;
      m_map[key] = val;
      return this;
    }

    public Map add(object key, object val)
    {
      modify();
      if (key == null)
        throw NullErr.make("key is null").val;
      if (!isImmutable(key).booleanValue())
        throw NotImmutableErr.make("key is not immutable: " + type(key)).val;
      if (m_map[key] != null)
        throw ArgErr.make("Key already mapped: " + key).val;
      m_map[key] = val;
      return this;
    }

    public Map setAll(Map m)
    {
      modify();
      IDictionaryEnumerator en = m.m_map.GetEnumerator();
      while (en.MoveNext())
      {
        object key = en.Key;
        object val = en.Value;
        m_map[key] = val;
      }
      return this;
    }

    public Map addAll(Map m)
    {
      modify();
      IDictionaryEnumerator en = m.m_map.GetEnumerator();
      while (en.MoveNext())
      {
        object key = en.Key;
        object val = en.Value;
        add(key, val);
      }
      return this;
    }

    public object remove(object key)
    {
      modify();
      object val = m_map[key];
      m_map.Remove(key);
      return val;
    }

    public Map dup()
    {
      Map dup = new Map(m_type);
      dup.m_map = (Hashtable)this.m_map.Clone();
      return dup;
    }

    public void clear()
    {
      modify();
      m_map.Clear();
    }

    public Boolean caseInsensitive() { return Boolean.valueOf(m_caseInsensitive); }
    public void caseInsensitive(Boolean v)
    {
      modify();

      if (m_type.m_k != Sys.StrType)
        throw UnsupportedErr.make("Map not keyed by string: " + m_type).val;

      if (m_map.Count != 0)
        throw UnsupportedErr.make("Map not empty").val;

      if (this.m_caseInsensitive == v.booleanValue()) return;
      this.m_caseInsensitive = v.booleanValue();

      if (m_caseInsensitive)
        m_map = new Hashtable(new CIEqualityComparer());
      else
        m_map = new Hashtable();
    }

    public object def() { return m_def; }
    public void def(object v)
    {
      modify();
      if (v != null && !isImmutable(v).booleanValue())
        throw NotImmutableErr.make("def must be immutable: " + type(v)).val;
      this.m_def = v;
    }

    public override Boolean _equals(object that)
    {
      if (that is Map)
      {
        if (!m_type.Equals(type(that)))
          return Boolean.False;

        Hashtable thatMap = ((Map)that).m_map;
        if (m_map.Count != thatMap.Count)
          return Boolean.False;

        IDictionaryEnumerator en = m_map.GetEnumerator();
        while (en.MoveNext())
        {
          object key  = en.Key;
          object val  = en.Value;
          object test = thatMap[key];

          if (val == null)
          {
            if (test != null) return Boolean.False;
          }
          else if (!val.Equals(test))
          {
            return Boolean.False;
          }
        }

        return Boolean.True;
      }
      return Boolean.False;
    }

    public override Long hash()
    {
      int hash = 0;
      IDictionaryEnumerator en = m_map.GetEnumerator();
      while (en.MoveNext())
      {
        object key = en.Key;
        object val = en.Value;
        hash += key.GetHashCode() ^ (val == null ? 0 : val.GetHashCode());
      }
      return Long.valueOf(hash);
    }

    public override string toStr()
    {
      if (m_map.Count == 0) return "[:]";
      StringBuilder s = new StringBuilder(32+m_map.Count*32);
      s.Append("[");
      bool first = true;
      IDictionaryEnumerator en = m_map.GetEnumerator();
      while (en.MoveNext())
      {
        object key = en.Key;
        object val = en.Value;
        if (!first) s.Append(", ");
        else first = false;
        s.Append(key).Append(':').Append(val);
      }
      s.Append("]");
      return s.ToString();
    }

    public void encode(ObjEncoder @out)
    {
      // route back to obj encoder
      @out.writeMap(this);
    }

  //////////////////////////////////////////////////////////////////////////
  // Iterators
  //////////////////////////////////////////////////////////////////////////

    public void each(Func f)
    {
      IDictionaryEnumerator en = m_map.GetEnumerator();
      while (en.MoveNext())
      {
        object key = en.Key;
        object val = en.Value;
        f.call2(val, key);
      }
    }

    public object eachBreak(Func f)
    {
      IDictionaryEnumerator en = m_map.GetEnumerator();
      while (en.MoveNext())
      {
        object key = en.Key;
        object val = en.Value;
        object r = f.call2(val, key);
        if (r != null) return r;
      }
      return null;
    }

    public object find(Func f)
    {
      IDictionaryEnumerator en = m_map.GetEnumerator();
      while (en.MoveNext())
      {
        object key = en.Key;
        object val = en.Value;
        if (f.call2(val, key) == Boolean.True)
          return val;
      }
      return null;
    }

    public Map findAll(Func f)
    {
      Map acc = new Map(m_type);
      IDictionaryEnumerator en = m_map.GetEnumerator();
      while (en.MoveNext())
      {
        object key = en.Key;
        object val = en.Value;
        if (f.call2(val, key) == Boolean.True)
          acc.set(key, val);
      }
      return acc;
    }

    public Map exclude(Func f)
    {
      Map acc = new Map(m_type);
      IDictionaryEnumerator en = m_map.GetEnumerator();
      while (en.MoveNext())
      {
        object key = en.Key;
        object val = en.Value;
        if (f.call2(val, key) == Boolean.False)
          acc.set(key, val);
      }
      return acc;
    }

    public object reduce(object reduction, Func f)
    {
      IDictionaryEnumerator en = m_map.GetEnumerator();
      while (en.MoveNext())
      {
        object key = en.Key;
        object val = en.Value;
        reduction = f.call3(reduction, val, key);
      }
      return reduction;
    }

    public Map map(Map acc, Func f)
    {
      IDictionaryEnumerator en = m_map.GetEnumerator();
      while (en.MoveNext())
      {
        object key = en.Key;
        object val = en.Value;
        acc.set(key, f.call2(val, key));
      }
      return acc;
    }

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

    public Map rw()
    {
      if (!m_isReadonly) return this;

      Map rw = new Map(m_type);
      rw.m_map = (Hashtable)m_map.Clone();
      rw.m_isReadonly = false;
      rw.m_readonlyMap = this;
      rw.m_caseInsensitive = m_caseInsensitive;
      rw.m_def = m_def;
      return rw;
    }

    public Map ro()
    {
      if (m_isReadonly) return this;
      if (m_readonlyMap == null)
      {
        Map ro = new Map(m_type);
        ro.m_map = m_map;
        ro.m_isReadonly  = true;
        ro.m_caseInsensitive = m_caseInsensitive;
        ro.m_def = m_def;
        m_readonlyMap = ro;
      }
      return m_readonlyMap;
    }

    public override Boolean isImmutable()
    {
      return Boolean.valueOf(m_immutable);
    }

    public Map toImmutable()
    {
      if (m_immutable) return this;

      // make safe copy
      Hashtable temp = m_caseInsensitive
        ? new Hashtable(new CIEqualityComparer()) : new Hashtable();
      IDictionaryEnumerator en = m_map.GetEnumerator();
      while (en.MoveNext())
      {
        object key = en.Key;
        object val = en.Value;

        if (val != null)
        {
          if (val is List)
            val = ((List)val).toImmutable();
          else if (val is Map)
            val = ((Map)val).toImmutable();
          else if (!isImmutable(val).booleanValue())
            throw NotImmutableErr.make("Item [" + key + "] not immutable " + type(val)).val;
        }

        temp[key] = val;
      }

      // return new m_immutable m_map
      Map ro = new Map(m_type, temp);
      ro.m_isReadonly = true;
      ro.m_immutable = true;
      ro.m_caseInsensitive = m_caseInsensitive;
      ro.m_def = m_def;
      return ro;
    }

    private void modify()
    {
      // if readonly then throw readonly exception
      if (m_isReadonly)
        throw ReadonlyErr.make("Map is readonly").val;

      // if we have a cached m_readonlyMap, then detach
      // it so it remains m_immutable
      if (m_readonlyMap != null)
      {
        m_readonlyMap.m_map = (Hashtable)m_map.Clone();
        m_readonlyMap = null;
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // C#
  //////////////////////////////////////////////////////////////////////////

    public IDictionaryEnumerator pairsIterator()
    {
      return m_map.GetEnumerator();
    }

    public IEnumerator keysEnumerator()
    {
      return m_map.Keys.GetEnumerator();
    }

  //////////////////////////////////////////////////////////////////////////
  // CIEqualityComparer (Case Insensitive)
  //////////////////////////////////////////////////////////////////////////

    class CIEqualityComparer : IEqualityComparer
    {
      public new bool Equals(object x, object y)
      {
        return FanStr.equalsIgnoreCase((string)x, (string)y).booleanValue();
      }

      public int GetHashCode(object obj)
      {
        return FanStr.caseInsensitiveHash((string)obj);
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    private MapType m_type;
    private Hashtable m_map;
    private Map m_readonlyMap;
    private bool m_isReadonly;
    private bool m_immutable;
    private bool m_caseInsensitive = false;
    private object m_def;

  }
}