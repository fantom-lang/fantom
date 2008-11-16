//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   5 Mar 08  Andy Frank  Creation
//

namespace Fan.Sys
{
  /// <summary>
  /// Namespace models a Uri to Obj map.  Namespaces provide a unified
  /// CRUD (create/read/update/delete) interface for managing objects
  /// keyed by a Uri.  The root namespace accessed via `Sys.ns` provides
  /// a thread-safe memory database.  Custom namespaces can be mounted
  /// into the system via the `Sys.mount` method.
  /// </summary>
  public abstract class Namespace : FanObj
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

    public static void make_(Namespace self) {}

    public Namespace() {}

  //////////////////////////////////////////////////////////////////////////
  // Identity
  //////////////////////////////////////////////////////////////////////////

    public override string toStr() { return type().qname() + " uri=" + m_uri; }

    public override Type type() { return Sys.NamespaceType; }

  //////////////////////////////////////////////////////////////////////////
  // Namespace
  //////////////////////////////////////////////////////////////////////////

    public Uri uri() { return m_uri; }

    public object get(Uri uri) { return get(uri, true); }
    public abstract object get(Uri uri, bool check);

    public virtual Uri create(Uri uri, object obj)
    {
      throw UnsupportedErr.make(type() + ".create").val;
    }

    public virtual void put(Uri uri, object obj)
    {
      throw UnsupportedErr.make(type() + ".put").val;
    }

    public virtual void delete(Uri uri)
    {
      throw UnsupportedErr.make(type() + ".delete").val;
    }

  //////////////////////////////////////////////////////////////////////////
  // Utils
  //////////////////////////////////////////////////////////////////////////

    /// <summary>
    /// Make a thread-safe copy of the specified object.
    /// If it is immutable, then just return it; otherwise
    /// we make a serialized copy.
    /// </summary>
    public static object safe(object obj)
    {
      if (obj == null) return null;
      if (isImmutable(obj)) return obj;
      Buf buf = new MemBuf(512);
      buf.m_out.writeObj(obj);
      buf.flip();
      return buf.m_in.readObj();
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    internal Uri m_uri;

  }
}