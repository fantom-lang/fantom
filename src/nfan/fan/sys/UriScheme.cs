//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   28 Aug 08  Andy Frank  Creation
//

using System.Collections;

namespace Fan.Sys
{
  /// <summary>
  /// UriScheme
  /// </summary>
  public abstract class UriScheme : FanObj
  {

  //////////////////////////////////////////////////////////////////////////
  // Lookup
  //////////////////////////////////////////////////////////////////////////

    public static UriScheme find(Str scheme) { return find(scheme, Boolean.True); }
    public static UriScheme find(Str scheme, Boolean check)
    {
      // check cache
      lock (m_cache)
      {
        UriScheme cached = (UriScheme)m_cache[scheme];
        if (cached != null) return cached;
      }

      try
      {
        // lookup scheme type
        Type t = (Type)Type.findByFacet(Str.make("uriScheme"), scheme, Boolean.True).first();
        if (t == null) throw new System.Exception();

        // allocate instance
        UriScheme s = (UriScheme)t.make();
        s.m_scheme = scheme;

        // add to cache
        lock (m_cache)
        {
          UriScheme cached = (UriScheme)m_cache[scheme];
          if (cached != null) return cached;
          m_cache[scheme] = s;
        }

        return s;
      }
      catch (System.Exception)
      {
        if (!check.booleanValue()) return null;
        throw UnresolvedErr.make("Unknown scheme: " + scheme).val;
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // Construction
  //////////////////////////////////////////////////////////////////////////

    public static UriScheme make() { throw Err.make("UriScheme is abstract").val; }

    public static void make_(UriScheme self) {}

  //////////////////////////////////////////////////////////////////////////
  // Methods
  //////////////////////////////////////////////////////////////////////////

    public override Type type() { return Sys.UriSchemeType; }

    public override Str toStr() { return m_scheme; }

    public Str scheme() { return m_scheme; }

    public abstract object get(Uri uri, object @base);

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    internal static Hashtable m_cache = new Hashtable();

    internal Str m_scheme;
  }
}