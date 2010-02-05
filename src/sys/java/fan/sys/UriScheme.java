//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   26 Aug 08  Brian Frank  Creation
//
package fan.sys;

import java.util.HashMap;

/**
 * UriScheme
 */
public abstract class UriScheme
  extends FanObj
{

//////////////////////////////////////////////////////////////////////////
// Lookup
//////////////////////////////////////////////////////////////////////////

  public static UriScheme find(String scheme) { return find(scheme, true); }
  public static UriScheme find(String scheme, boolean checked)
  {
    // check cache
    synchronized (cache)
    {
      UriScheme cached = (UriScheme)cache.get(scheme);
      if (cached != null) return cached;
    }

    try
    {
      // lookup scheme type (avoid building index for common types)
      Type t = null;
      if (scheme.equals("fan"))  t = Sys.FanSchemeType;
      if (scheme.equals("file")) t = Sys.FileSchemeType;
      if (t == null)
      {
        String qname = (String)Env.cur().index("sys.uriScheme." + scheme).first();
        if (qname == null) throw UnresolvedErr.make().val;
        t = Type.find(qname);
      }

      // allocate instance
      UriScheme s = (UriScheme)t.make();
      s.scheme = scheme;

      // add to cache
      synchronized (cache)
      {
        UriScheme cached = (UriScheme)cache.get(scheme);
        if (cached != null) return cached;
        cache.put(scheme, s);
      }

      return s;
    }
    catch (UnresolvedErr.Val e) {}
    catch (Throwable e) { e.printStackTrace(); }

    if (!checked) return null;
    throw UnresolvedErr.make("Unknown scheme: " + scheme).val;
  }

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  public static UriScheme make() { throw Err.make("UriScheme is abstract").val; }

  public static void make$(UriScheme self) {}

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  public Type typeof() { return Sys.UriSchemeType; }

  public String toStr() { return scheme; }

  public String scheme() { return scheme; }

  public abstract Object get(Uri uri, Object base);

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  static HashMap cache = new HashMap();

  String scheme;
}