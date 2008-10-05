//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   04 Mar 08  Brian Frank  Creation
//
package fan.sys;

import java.util.*;

/**
 * RootNamesapce is the sys internal subclass of Namespace
 * which manages the root memory database and mounts.
 */
public final class RootNamespace
  extends Namespace
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  RootNamespace()
  {
    this.uri    = Uri.fromStr("/");
    this.lock   = new Object();
    this.mem    = new HashMap(4096);
    this.mounts = new HashMap(1024);
    mount(Uri.fromStr("/sys"), new SysNamespace());
  }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  public Str toStr() { return type().toStr(); }

  public Type type() { return Sys.RootNamespaceType; }

//////////////////////////////////////////////////////////////////////////
// Namespace
//////////////////////////////////////////////////////////////////////////

  public Object get(Uri uri, Boolean checked)
  {
    checkUri(uri);

    Namespace sub = ns(uri);
    if (sub != this) return sub.get(uri, checked);

    Object val = null;
    synchronized (lock)
    {
      val = mem.get(uri.str.val);
      if (val == null)
      {
        if (!checked) return null;
        throw UnresolvedErr.make(uri).val;
      }
    }
    return safe(val);
  }

  public Uri create(Uri uri, Object obj)
  {
    if (obj == null) throw ArgErr.make("obj is null").val;

    if (uri != null)
    {
      checkUri(uri);
      Namespace sub = ns(uri);
      if (sub != this) return sub.create(uri, obj);
    }

    Object safe = safe(obj);
    synchronized (lock)
    {
      if (uri == null)
        uri = Uri.fromStr("/mem/" + uriCounter++);

      Object old = mem.put(uri.str.val, safe);
      if (old != null)
      {
        mem.put(uri.str.val, old);
        throw ArgErr.make("Uri already mapped: " + uri).val;
      }

      return uri;
    }
  }

  public void put(Uri uri, Object obj)
  {
    checkUri(uri);
    if (obj == null) throw ArgErr.make("obj is null").val;

    Namespace sub = ns(uri);
    if (sub != this) { sub.put(uri, obj); return; }

    Object safe = safe(obj);
    synchronized (lock)
    {
      Object old = mem.put(uri.str.val, safe);
      if (old == null)
      {
        mem.remove(uri.str.val);
        throw UnresolvedErr.make(uri).val;
      }
    }
  }

  public void delete(Uri uri)
  {
    checkUri(uri);

    Namespace sub = ns(uri);
    if (sub != this) { sub.delete(uri); return; }

    synchronized (lock)
    {
      Object old = mem.remove(uri.str.val);
      if (old == null)
      {
        throw UnresolvedErr.make(uri).val;
      }
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

  Namespace ns(Uri uri)
  {
    if (uri == null) return this;
    if (uri.path == null) throw ArgErr.make("Invalid uri for mount: " + uri).val;

    int depth = uri.path.sz();
    MountKey key = new MountKey(uri);
    synchronized (lock)
    {
      for (int i=depth; i>0; --i)
      {
        key.update(i);
        Namespace ns = (Namespace)mounts.get(key);
        if (ns != null) return ns;
      }
    }

    return this;
  }

  void mount(Uri uri, Namespace ns)
  {
    if (uri.auth() != null || uri.queryStr != null ||
        uri.frag != null   || uri.path == null ||
        uri.path.sz() == 0 || !uri.isPathAbs())
      throw ArgErr.make("Invalid Uri for mount: " + uri).val;

    if (ns.uri != null)
      throw ArgErr.make("Namespace already mounted: " + ns.uri).val;

    MountKey key = new MountKey(uri).update(uri.path.sz());
    synchronized (lock)
    {
      if (mounts.get(key) != null)
        throw ArgErr.make("Uri already mounted: " + uri).val;

      Object old = mounts.put(key, ns);
      ns.uri = uri;
    }
  }

  void unmount(Uri uri)
  {
    MountKey key = new MountKey(uri).update(uri.path.sz());
    synchronized (lock)
    {
      Namespace old = (Namespace)mounts.remove(key);
      if (old == null)
      {
        throw UnresolvedErr.make(uri).val;
      }
      old.uri = null;
    }
  }

//////////////////////////////////////////////////////////////////////////
// MountKey
//////////////////////////////////////////////////////////////////////////

  static final class MountKey
  {
    MountKey(Uri uri)
    {
      this.path = uri.path;
    }

    final MountKey update(int depth)
    {
      int h = 0xbada5572;
      for (int i=0; i<depth; ++i)
        h ^= path.get(i).hashCode();

      this.hash  = h;
      this.depth = depth;
      return this;
    }

    public final int hashCode() { return hash; }

    public final boolean equals(Object obj)
    {
      MountKey that = (MountKey)obj;
      if (this.depth != that.depth) return false;
      for (int i=0; i<depth; ++i)
      {
        Str thisName = (Str)this.path.get(i);
        Str thatName = (Str)that.path.get(i);
        if (!thisName.val.equals(thatName.val)) return false;
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

  private Object lock;     // synchronized lock
  private HashMap mem;     // memory db: uri.str.val -> Obj
  private HashMap mounts;  // mounts: uri.str.val -> Namespace
  private int uriCounter;  // auto-generated uris

}