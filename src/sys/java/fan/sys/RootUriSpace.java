//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   04 Mar 08  Brian Frank  Creation
//    9 Jul 09  Brian        Rename from RootNamespace
//
package fan.sys;

import java.util.*;

/**
 * RootUriSpace is the sys internal subclass of UriSpace
 * which manages the root memory database and mounts.
 */
public final class RootUriSpace
  extends UriSpace
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  RootUriSpace()
  {
    this.uri    = Uri.fromStr("/");
    this.lock   = new Object();
    this.mem    = new HashMap(4096);
    this.mounts = new HashMap(1024);
    mount(Uri.fromStr("/sys"), new SysUriSpace());
  }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  public String toStr() { return type().toStr(); }

  public Type type() { return Sys.RootUriSpaceType; }

//////////////////////////////////////////////////////////////////////////
// UriSpace
//////////////////////////////////////////////////////////////////////////

  public Object get(Uri uri, boolean checked)
  {
    checkUri(uri);

    UriSpace sub = ns(uri);
    if (sub != this) return sub.get(uri, checked);

    Object val = null;
    synchronized (lock)
    {
      val = mem.get(uri.str);
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
      UriSpace sub = ns(uri);
      if (sub != this) return sub.create(uri, obj);
    }

    Object safe = safe(obj);
    synchronized (lock)
    {
      if (uri == null)
        uri = Uri.fromStr("/mem/" + uriCounter++);

      Object old = mem.put(uri.str, safe);
      if (old != null)
      {
        mem.put(uri.str, old);
        throw ArgErr.make("Uri already mapped: " + uri).val;
      }

      return uri;
    }
  }

  public void put(Uri uri, Object obj)
  {
    checkUri(uri);
    if (obj == null) throw ArgErr.make("obj is null").val;

    UriSpace sub = ns(uri);
    if (sub != this) { sub.put(uri, obj); return; }

    Object safe = safe(obj);
    synchronized (lock)
    {
      Object old = mem.put(uri.str, safe);
      if (old == null)
      {
        mem.remove(uri.str);
        throw UnresolvedErr.make(uri).val;
      }
    }
  }

  public void delete(Uri uri)
  {
    checkUri(uri);

    UriSpace sub = ns(uri);
    if (sub != this) { sub.delete(uri); return; }

    synchronized (lock)
    {
      Object old = mem.remove(uri.str);
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

  UriSpace ns(Uri uri)
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
        UriSpace ns = (UriSpace)mounts.get(key);
        if (ns != null) return ns;
      }
    }

    return this;
  }

  void mount(Uri uri, UriSpace ns)
  {
    if (uri.auth() != null || uri.queryStr != null ||
        uri.frag != null   || uri.path == null ||
        uri.path.sz() == 0 || !uri.isPathAbs())
      throw ArgErr.make("Invalid Uri for mount: " + uri).val;

    if (ns.uri != null)
      throw ArgErr.make("UriSpace already mounted: " + ns.uri).val;

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
      UriSpace old = (UriSpace)mounts.remove(key);
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
        String thisName = (String)this.path.get(i);
        String thatName = (String)that.path.get(i);
        if (!thisName.equals(thatName)) return false;
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
  private HashMap mounts;  // mounts: uri.str.val -> UriSpace
  private int uriCounter;  // auto-generated uris

}