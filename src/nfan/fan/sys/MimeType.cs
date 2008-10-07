//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   16 May 08  Andy Frank  Creation
//

using System.Collections;

namespace Fan.Sys
{
  /// <summary>
  /// MimeType represents the parsed value of a Content-Type
  /// header per RFC 2045 section 5.1.
  /// </summary>
  public sealed class MimeType : FanObj
  {

  //////////////////////////////////////////////////////////////////////////
  // Construction
  //////////////////////////////////////////////////////////////////////////

    public static MimeType fromStr(Str s) { return fromStr(s, Bool.True); }
    public static MimeType fromStr(Str s, Bool check)
    {
      try
      {
        int slash = s.val.IndexOf('/');
        string media = s.val.Substring(0, slash);
        string sub = s.val.Substring(slash+1); //, s.val.Length-slash+1);
        Map pars = emptyParams();

        int semi = sub.IndexOf(';');
        if (semi > 0)
        {
          pars = new Map(Sys.StrType, Sys.StrType);
          pars.caseInsensitive(Bool.True);
          bool inQuotes = false;
          int keyStart = semi+1;
          int valStart = -1;
          int valEnd   = -1;
          int eq       = -1;
          for (int i = keyStart; i<sub.Length; ++i)
          {
            int c = sub[i];

            if (c == '(' && !inQuotes)
              throw ParseErr.make("MimeType", s, "comments not supported").val;

            if (c == '=' && !inQuotes)
            {
              eq = i++;
              while (Int.isSpace(sub[i])) ++i;
              if (sub[i] == '"') { inQuotes = true; ++i; }
              else inQuotes = false;
              valStart = i;
            }

            if (eq < 0) continue;

            if (c == '"' && inQuotes)
            {
              valEnd = i-1;
              inQuotes = false;
            }

            if (c == ';' && !inQuotes)
            {
              if (valEnd < 0) valEnd = i-1;
              string key = sub.Substring(keyStart, eq-keyStart).Trim();
              string val = sub.Substring(valStart, valEnd+1-valStart).Trim();
              pars.set(Str.make(key), Str.make(val));
              keyStart = i+1;
              eq = valStart = valEnd = -1;
            }
          }

          if (keyStart < sub.Length)
          {
            if (valEnd < 0) valEnd = sub.Length-1;
            string key = sub.Substring(keyStart, eq-keyStart).Trim();
            string val = sub.Substring(valStart, valEnd+1-valStart).Trim();
            pars.set(Str.make(key), Str.make(val));
          }

          sub = sub.Substring(0, semi).Trim();
        }

        MimeType r    = new MimeType();
        r.m_str       = s;
        r.m_mediaType = Str.make(Str.lower(media));
        r.m_subType   = Str.make(Str.lower(sub));
        r.m_params    = pars.ro();
        return r;
      }
      catch (ParseErr.Val e)
      {
        if (!check.val) return null;
        throw e;
      }
      catch (System.Exception)
      {
        if (!check.val) return null;
        throw ParseErr.make("MimeType",  s).val;
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // Extension
  //////////////////////////////////////////////////////////////////////////

    public static MimeType forExt(Str s)
    {
      if (s == null) return null;
      lock (m_extLock)
      {
        if (m_extMap == null) m_extMap = loadExtMap();
        return (MimeType)m_extMap[s.lower()];
      }
    }

    internal static Hashtable loadExtMap()
    {
      try
      {
        LocalFile f = new LocalFile(new System.IO.FileInfo(Sys.HomeDir + File.m_sep + "lib" + File.m_sep + "ext2mime.props"));
        Map props = f.readProps();
        Hashtable map = new Hashtable((int)props.size().val * 3);
        IDictionaryEnumerator en = props.pairsIterator();
        while (en.MoveNext())
        {
          Str ext  = (Str)en.Key;
          Str mime = (Str)en.Value;
          try
          {
            map[ext.lower()] = fromStr(mime);
          }
          catch (System.Exception)
          {
            System.Console.WriteLine("WARNING: Invalid entry in lib/ext2mime.props: " + ext + ": " + mime);
          }
        }
        return map;
      }
      catch (System.Exception e)
      {
        System.Console.WriteLine("WARNING: Cannot load lib/ext2mime.props");
        System.Console.WriteLine("  " + e);
      }
      return new Hashtable();
    }

    internal static object m_extLock = new object();
    internal static Hashtable m_extMap;

  //////////////////////////////////////////////////////////////////////////
  // Identity
  //////////////////////////////////////////////////////////////////////////

    public override Bool _equals(object obj)
    {
      if (!(obj is MimeType)) return Bool.False;
      MimeType x = (MimeType)obj;
      return Bool.make(
        m_mediaType.val.Equals(x.m_mediaType.val) &&
        m_subType.val.Equals(x.m_subType.val) &&
        m_params.Equals(x.m_params));
    }

    public override int GetHashCode()
    {
      return m_mediaType.val.GetHashCode() ^
             m_subType.val.GetHashCode() ^
             m_params.GetHashCode();
    }

    public override Int hash()
    {
      return Int.make(GetHashCode());
    }

    public override Str toStr()
    {
      return m_str;
    }

    public override Type type()
    {
      return Sys.MimeTypeType;
    }

  //////////////////////////////////////////////////////////////////////////
  // Methods
  //////////////////////////////////////////////////////////////////////////

    public Str mediaType()
    {
      return m_mediaType;
    }

    public Str subType()
    {
      return m_subType;
    }

    public Map @params()
    {
      return m_params;
    }

  //////////////////////////////////////////////////////////////////////////
  // Lazy Load
  //////////////////////////////////////////////////////////////////////////

    internal static Map emptyParams()
    {
      Map q = m_emptyQuery;
      if (q == null)
      {
        q = new Map(Sys.StrType, Sys.StrType);
        q.caseInsensitive(Bool.True);
        q = q.toImmutable();
        m_emptyQuery = q;
      }
      return q;
    }
    static Map m_emptyQuery;

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    internal static MimeType m_dir = fromStr(Str.make("x-directory/normal"));

    private Str m_mediaType;
    private Str m_subType;
    private Map m_params;
    private Str m_str;

  }
}