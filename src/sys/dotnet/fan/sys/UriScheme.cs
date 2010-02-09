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

    public static UriScheme find(string scheme) { return find(scheme, true); }
    public static UriScheme find(string scheme, bool check)
    {
      // check cache
      lock (m_cache)
      {
        UriScheme cached = (UriScheme)m_cache[scheme];
        if (cached != null) return cached;
      }

      try
      {
        // lookup scheme type (avoid building index for common types)
        Type t = null;
        if (scheme == "fan")  t = Sys.FanSchemeType;
        if (scheme == "file") t = Sys.FileSchemeType;
        if (t == null)
        {
          string qname = (string)Env.cur().index("sys.uriScheme." + scheme).first();
          if (qname == null) throw UnresolvedErr.make().val;
          t = Type.find(qname);
        }

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
      catch (UnresolvedErr.Val) {}
      catch (System.Exception e) { Err.dumpStack(e); }

      if (!check) return null;
      throw UnresolvedErr.make("Unknown scheme: " + scheme).val;
    }

  //////////////////////////////////////////////////////////////////////////
  // Construction
  //////////////////////////////////////////////////////////////////////////

    public static UriScheme make() { throw Err.make("UriScheme is abstract").val; }

    public static void make_(UriScheme self) {}

  //////////////////////////////////////////////////////////////////////////
  // Methods
  //////////////////////////////////////////////////////////////////////////

    public override Type @typeof() { return Sys.UriSchemeType; }

    public override string toStr() { return m_scheme; }

    public string scheme() { return m_scheme; }

    public abstract object get(Uri uri, object @base);

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    internal static Hashtable m_cache = new Hashtable();

    internal string m_scheme;
  }
}