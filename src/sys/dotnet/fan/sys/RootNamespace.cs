//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   5 Mar 08  Andy Frank  Creation
//

using System.Collections;

namespace Fan.Sys
{
  /// <summary>
  /// RootNamesapce is the sys internal subclass of Namespace
  /// which manages the root memory database and mounts.
  /// </summary>
  public sealed class RootNamespace : Namespace
  {

  //////////////////////////////////////////////////////////////////////////
  // Construction
  //////////////////////////////////////////////////////////////////////////

    internal RootNamespace()
    {
      this.m_uri    = Uri.fromStr("/");
      this.m_lock   = new object();
      this.m_mem    = new Hashtable(4096);
      this.m_mounts = new Hashtable(1024);
      mount(Uri.fromStr("/sys"), new SysNamespace());
    }

  //////////////////////////////////////////////////////////////////////////
  // Identity
  //////////////////////////////////////////////////////////////////////////

    public override string toStr() { return type().toStr(); }

    public override Type type() { return Sys.RootNamespaceType; }

  //////////////////////////////////////////////////////////////////////////
  // Namespace
  //////////////////////////////////////////////////////////////////////////

    public override object get(Uri uri, bool check)
    {
      checkUri(uri);

      Namespace sub = ns(uri);
      if (sub != this) return sub.get(uri, check);

      object val = null;
      lock (m_lock)
      {
        val = m_mem[uri.m_str];
        if (val == null)
        {
          if (!check) return null;
          throw UnresolvedErr.make(uri).val;
        }
      }
      return safe(val);
    }

    public override Uri create(Uri uri, object obj)
    {
      if (obj == null) throw ArgErr.make("obj is null").val;

      if (uri != null)
      {
        checkUri(uri);
        Namespace sub = ns(uri);
        if (sub != this) return sub.create(uri, obj);
      }

      object safe = Namespace.safe(obj);
      lock (m_lock)
      {
        if (uri == null)
          uri = Uri.fromStr("/mem/" + m_uriCounter++);

        object old = m_mem[uri.m_str];
        if (old != null)
        {
          throw ArgErr.make("Uri already mapped: " + uri).val;
        }
        m_mem[uri.m_str] = safe;
        return uri;
      }
    }

    public override void put(Uri uri, object obj)
    {
      checkUri(uri);
      if (obj == null) throw ArgErr.make("obj is null").val;

      Namespace sub = ns(uri);
      if (sub != this) { sub.put(uri, obj); return; }

      object safe = Namespace.safe(obj);
      lock (m_lock)
      {
        object old = m_mem[uri.m_str];
        if (old == null)
        {
          throw UnresolvedErr.make(uri).val;
        }
        m_mem[uri.m_str] = safe;
      }
    }

    public override void delete(Uri uri)
    {
      checkUri(uri);

      Namespace sub = ns(uri);
      if (sub != this) { sub.delete(uri); return; }

      lock (m_lock)
      {
        if (m_mem[uri.m_str] == null)
        {
          throw UnresolvedErr.make(uri).val;
        }
        m_mem.Remove(uri.m_str);
      }
    }

    private void checkUri(Uri uri)
    {
      if (!uri.isPathOnly())
        throw ArgErr.make("Uri not path only: " + uri).val;
    }

  //////////////////////////////////////////////////////////////////////////
  // Mounts
  //////////////////////////////////////////////////////////////////////////

    internal Namespace ns(Uri uri)
    {
      if (uri == null) return this;
      if (uri.m_path == null) throw ArgErr.make("Invalid uri for mount: " + uri).val;

      int depth = uri.m_path.sz();
      MountKey key = new MountKey(uri);
      lock (m_lock)
      {
        for (int i=depth; i>0; --i)
        {
          key.update(i);
          Namespace ns = (Namespace)m_mounts[key];
          if (ns != null) return ns;
        }
      }

      return this;
    }

    internal void mount(Uri uri, Namespace ns)
    {
      if (uri.auth() != null || uri.m_queryStr != null ||
          uri.m_frag != null   || uri.m_path == null ||
          uri.m_path.sz() == 0 || !uri.isPathAbs())
        throw ArgErr.make("Invalid Uri for mount: " + uri).val;

      if (ns.m_uri != null)
        throw ArgErr.make("Namespace already mounted: " + ns.m_uri).val;

      MountKey key = new MountKey(uri).update(uri.m_path.sz());
      lock (m_lock)
      {
        if (m_mounts[key] != null)
          throw ArgErr.make("Uri already mounted: " + uri).val;

        object old = m_mounts[key] = ns;
        ns.m_uri = uri;
      }
    }

    internal void unmount(Uri uri)
    {
      MountKey key = new MountKey(uri).update(uri.m_path.sz());
      lock (m_lock)
      {
        Namespace old = (Namespace)m_mounts[key];
        if (old == null)
        {
          throw UnresolvedErr.make(uri).val;
        }
        m_mounts.Remove(key);
        old.m_uri = null;
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // MountKey
  //////////////////////////////////////////////////////////////////////////

    internal class MountKey
    {
      internal MountKey(Uri uri)
      {
        this.path = uri.m_path;
      }

      internal MountKey update(int depth)
      {
        long h = 0xbada5572;
        for (int i=0; i<depth; ++i)
          h ^= path.get(i).GetHashCode();

        this.hash  = (int)h;
        this.depth = depth;
        return this;
      }

      public override int GetHashCode() { return hash; }

      public override bool Equals(object obj)
      {
        MountKey that = (MountKey)obj;
        if (this.depth != that.depth) return false;
        for (int i=0; i<depth; ++i)
        {
          string thisName = (string)this.path.get(i);
          string thatName = (string)that.path.get(i);
          if (thisName != thatName) return false;
        }
        return true;
      }

      List path;
      int hash;
      int depth;
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    private object m_lock;       // synchronized lock
    private Hashtable m_mem;     // memory db: uri.m_str.val -> object
    private Hashtable m_mounts;  // mounts: uri.m_str.val -> Namespace
    private int m_uriCounter;    // auto-generated uris

  }
}