//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   04 Mar 08  Brian Frank  Creation
//    9 Jul 09  Brian        Rename from Namespace
//
package fan.sys;

import java.util.*;

/**
 * UriSpace models a Uri to Obj map.  UriSpaces provide a unified
 * CRUD (create/read/update/delete) interface for managing objects
 * keyed by a Uri.
 */
public abstract class UriSpace
  extends FanObj
{

//////////////////////////////////////////////////////////////////////////
// Mounting
//////////////////////////////////////////////////////////////////////////

  public static UriSpace root() { return root; }

  public static UriSpace find(Uri uri) { return root.doFind(uri); }

  public static void mount(Uri uri, UriSpace m) { root.doMount(uri, m); }

  public static void unmount(Uri uri) { root.doUnmount(uri); }

//////////////////////////////////////////////////////////////////////////
// Factory
//////////////////////////////////////////////////////////////////////////

  public static UriSpace makeDir(File dir)
  {
    return new DirUriSpace(dir);
  }

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  public static void make$(UriSpace self) {}

  public UriSpace() {}

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  public String toStr() { return typeof().qname() + " uri=" + uri; }

  public Type typeof() { return Sys.UriSpaceType; }

//////////////////////////////////////////////////////////////////////////
// UriSpace
//////////////////////////////////////////////////////////////////////////

  public final Uri uri() { return uri; }

  public Object get(Uri uri) { return get(uri, true); }
  public abstract Object get(Uri uri, boolean checked);

  public Uri create(Uri uri, Object obj)
  {
    throw UnsupportedErr.make(typeof() + ".create").val;
  }

  public void put(Uri uri, Object obj)
  {
    throw UnsupportedErr.make(typeof() + ".put").val;
  }

  public void delete(Uri uri)
  {
    throw UnsupportedErr.make(typeof() + ".delete").val;
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  /**
   * Make a thread-safe copy of the specified object.
   * If it is immutable, then just return it; otherwise
   * we make a serialized copy.
   */
  public static Object safe(Object obj)
  {
    if (obj == null) return null;
    if (isImmutable(obj)) return obj;
    Buf buf = new MemBuf(512);
    buf.out.writeObj(obj);
    buf.flip();
    return buf.in.readObj();
  }

//////////////////////////////////////////////////////////////////////////
// Root
//////////////////////////////////////////////////////////////////////////

  static final RootUriSpace root;

  static
  {
    RootUriSpace x = null;
    try
    {
      x = new RootUriSpace();
    }
    catch (Throwable e)
    {
      e.printStackTrace();
    }
    root = x;
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  Uri uri;
}