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

  public static UriScheme find(Str scheme) { return find(scheme, Bool.True); }
  public static UriScheme find(Str scheme, Bool checked)
  {
    // check cache
    synchronized (cache)
    {
      UriScheme cached = (UriScheme)cache.get(scheme);
      if (cached != null) return cached;
    }

    try
    {
      // lookup scheme type
      Type t = (Type)Type.findByFacet(Str.make("uriScheme"), scheme, Bool.True).first();
      if (t == null) throw new Exception();

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
    catch (Throwable e)
    {
      if (!checked.val) return null;
      throw UnresolvedErr.make("Unknown scheme: " + scheme).val;
    }
  }

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  public static UriScheme make() { throw Err.make("UriScheme is abstract").val; }

  public static void make$(UriScheme self) {}

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  public Type type() { return Sys.UriSchemeType; }

  public Str toStr() { return scheme; }

  public Str scheme() { return scheme; }

  public abstract Obj get(Uri uri, Obj base);

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  static HashMap cache = new HashMap();

  Str scheme;
}