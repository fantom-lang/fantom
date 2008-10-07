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
 * Namespace models a Uri to Obj map.  Namespaces provide a unified
 * CRUD (create/read/update/delete) interface for managing objects
 * keyed by a Uri.  The root namespace accessed via `Sys.ns` provides
 * a thread-safe memory database.  Custom namespaces can be mounted
 * into the system via the `Sys.mount` method.
 */
public abstract class Namespace
  extends FanObj
{

//////////////////////////////////////////////////////////////////////////
// Factory
//////////////////////////////////////////////////////////////////////////

  public static Namespace makeDir(File dir)
  {
    return new DirNamespace(dir);
  }

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  public static void make$(Namespace self) {}

  public Namespace() {}

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  public String toStr() { return type().qname + " uri=" + uri; }

  public Type type() { return Sys.NamespaceType; }

//////////////////////////////////////////////////////////////////////////
// Namespace
//////////////////////////////////////////////////////////////////////////

  public final Uri uri() { return uri; }

  public Object get(Uri uri) { return get(uri, true); }
  public abstract Object get(Uri uri, Boolean checked);

  public Uri create(Uri uri, Object obj)
  {
    throw UnsupportedErr.make(type() + ".create").val;
  }

  public void put(Uri uri, Object obj)
  {
    throw UnsupportedErr.make(type() + ".put").val;
  }

  public void delete(Uri uri)
  {
    throw UnsupportedErr.make(type() + ".delete").val;
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
// Fields
//////////////////////////////////////////////////////////////////////////

  Uri uri;
}
