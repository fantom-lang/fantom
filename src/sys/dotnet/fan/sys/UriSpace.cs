//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   5 Mar 08  Andy Frank   Creation
//   9 Jul 09  Brian Frank  Rename from Namespace
//

namespace Fan.Sys
{
  /// <summary>
  /// UriSpace models a Uri to Obj map.
  /// </summary>
  public abstract class UriSpace : FanObj
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

    public static void make_(UriSpace self) {}

    public UriSpace() {}

  //////////////////////////////////////////////////////////////////////////
  // Identity
  //////////////////////////////////////////////////////////////////////////

    public override string toStr() { return type().qname() + " uri=" + m_uri; }

    public override Type type() { return Sys.UriSpaceType; }

  //////////////////////////////////////////////////////////////////////////
  // UriSpace
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