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

    public static MimeType fromStr(string s) { return fromStr(s, Boolean.True); }
    public static MimeType fromStr(string s, Boolean check)
    {
      try
      {
        int slash = s.IndexOf('/');
        string media = s.Substring(0, slash);
        string sub = s.Substring(slash+1); //, s.val.Length-slash+1);
        Map pars = emptyParams();

        int semi = sub.IndexOf(';');
        if (semi > 0)
        {
          pars = new Map(Sys.StrType, Sys.StrType);
          pars.caseInsensitive(Boolean.True);
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
              while (FanInt.isSpace(sub[i])) ++i;
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
              pars.set(key, val);
              keyStart = i+1;
              eq = valStart = valEnd = -1;
            }
          }

          if (keyStart < sub.Length)
          {
            if (valEnd < 0) valEnd = sub.Length-1;
            string key = sub.Substring(keyStart, eq-keyStart).Trim();
            string val = sub.Substring(valStart, valEnd+1-valStart).Trim();
            pars.set(key, val);
          }

          sub = sub.Substring(0, semi).Trim();
        }

        MimeType r    = new MimeType();
        r.m_str       = s;
        r.m_mediaType = FanStr.lower(media);
        r.m_subType   = FanStr.lower(sub);
        r.m_params    = pars.ro();
        return r;
      }
      catch (ParseErr.Val e)
      {
        if (!check.booleanValue()) return null;
        throw e;
      }
      catch (System.Exception)
      {
        if (!check.booleanValue()) return null;
        throw ParseErr.make("MimeType",  s).val;
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // Extension
  //////////////////////////////////////////////////////////////////////////

    public static MimeType forExt(string s)
    {
      if (s == null) return null;
      lock (m_extLock)
      {
        if (m_extMap == null) m_extMap = loadExtMap();
        return (MimeType)m_extMap[FanStr.lower(s)];
      }
    }

    internal static Hashtable loadExtMap()
    {
      try
      {
        LocalFile f = new LocalFile(new System.IO.FileInfo(Sys.HomeDir + File.m_sep + "lib" + File.m_sep + "ext2mime.props"));
        Map props = f.readProps();
        Hashtable map = new Hashtable(props.size().intValue() * 3);
        IDictionaryEnumerator en = props.pairsIterator();
        while (en.MoveNext())
        {
          string ext  = (string)en.Key;
          string mime = (string)en.Value;
          try
          {
            map[FanStr.lower(ext)] = fromStr(mime);
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

    public override Boolean _equals(object obj)
    {
      if (!(obj is MimeType)) return Boolean.False;
      MimeType x = (MimeType)obj;
      return Boolean.valueOf(
        m_mediaType == x.m_mediaType &&
        m_subType == x.m_subType &&
        m_params == x.m_params);
    }

    public override int GetHashCode()
    {
      return m_mediaType.GetHashCode() ^
             m_subType.GetHashCode() ^
             m_params.GetHashCode();
    }

    public override Long hash()
    {
      return Long.valueOf(GetHashCode());
    }

    public override string toStr()
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

    public string mediaType()
    {
      return m_mediaType;
    }

    public string subType()
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
        q.caseInsensitive(Boolean.True);
        q = q.toImmutable();
        m_emptyQuery = q;
      }
      return q;
    }
    static Map m_emptyQuery;

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    internal static MimeType m_dir = fromStr("x-directory/normal");

    private string m_mediaType;
    private string m_subType;
    private Map m_params;
    private string m_str;

  }
}