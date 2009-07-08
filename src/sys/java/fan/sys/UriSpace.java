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

  public String toStr() { return type().qname() + " uri=" + uri; }

  public Type type() { return Sys.UriSpaceType; }

//////////////////////////////////////////////////////////////////////////
// UriSpace
//////////////////////////////////////////////////////////////////////////

  public final Uri uri() { return uri; }

  public Object get(Uri uri) { return get(uri, true); }
  public abstract Object get(Uri uri, boolean checked);

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