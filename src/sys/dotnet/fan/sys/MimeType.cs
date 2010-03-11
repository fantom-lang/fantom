//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   16 May 08  Andy Frank  Creation
//

using System.Text;
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

    public static MimeType fromStr(string s) { return fromStr(s, true); }
    public static MimeType fromStr(string s, bool check)
    {
      try
      {
        // common interned mime types
        switch (s[0])
        {
          case 'i':
            if (s == "image/png")  return m_imagePng;
            if (s == "image/jpeg") return m_imageJpeg;
            if (s == "image/gif")  return m_imageGif;
            break;
          case 't':
            if (s == "text/plain") return m_textPlain;
            if (s == "text/html")  return m_textHtml;
            if (s == "text/xml")   return m_textXml;
            if (s == "text/plain; charset=utf-8") return m_textPlainUtf8;
            if (s == "text/html; charset=utf-8")  return m_textHtmlUtf8;
            if (s == "text/xml; charset=utf-8")   return m_textXmlUtf8;
            break;
          case 'x':
            if (s == "x-directory/normal") return m_dir;
            break;
        }

        return parse(s);
      }
      catch (ParseErr.Val e)
      {
        if (!check) return null;
        throw e;
      }
      catch (System.Exception)
      {
        if (!check) return null;
        throw ParseErr.make("MimeType",  s).val;
      }
    }

    private static MimeType parse(string s)
    {
      int slash = s.IndexOf('/');
      string media = s.Substring(0, slash);
      string sub = s.Substring(slash+1);
      Map pars = emptyParams();

      int semi = sub.IndexOf(';');
      if (semi > 0)
      {
        pars = doParseParams(sub, semi+1);
        sub = sub.Substring(0, semi).Trim();
      }

      MimeType r    = new MimeType();
      r.m_str       = s;
      r.m_mediaType = FanStr.lower(media);
      r.m_subType   = FanStr.lower(sub);
      r.m_params    = pars.ro();
      return r;
    }

    public static Map parseParams(string s) { return parseParams(s, true); }
    public static Map parseParams(string s, bool check)
    {
      try
      {
        return doParseParams(s, 0);
      }
      catch (ParseErr.Val e)
      {
        if (!check) return null;
        throw e;
      }
      catch (System.Exception)
      {
        if (!check) return null;
        throw ParseErr.make("MimeType params",  s).val;
      }
    }

    private static Map doParseParams(string s, int offset)
    {
      Map pars = new Map(Sys.StrType, Sys.StrType);
      pars.caseInsensitive(true);
      bool inQuotes = false;
      int keyStart = offset;
      int valStart = -1;
      int valEnd   = -1;
      int eq       = -1;
      bool hasEsc  = false;
      for (int i = keyStart; i<s.Length; ++i)
      {
        int c = s[i];

        if (c == '(' && !inQuotes)
          throw ParseErr.make("MimeType", s, "comments not supported").val;

        if (c == '=' && !inQuotes)
        {
          eq = i++;
          while (FanInt.isSpace(s[i])) ++i;
          if (s[i] == '"') { inQuotes = true; ++i; }
          else inQuotes = false;
          valStart = i;
        }

        if (eq < 0) continue;

        if (c == '\\' && inQuotes)
        {
          ++i;
          hasEsc = true;
          continue;
        }

        if (c == '"' && inQuotes)
        {
          valEnd = i-1;
          inQuotes = false;
        }

        if (c == ';' && !inQuotes)
        {
          if (valEnd < 0) valEnd = i-1;
          string key = s.Substring(keyStart, eq-keyStart).Trim();
          string val = s.Substring(valStart, valEnd+1-valStart).Trim();
          if (hasEsc) val = unescape(val);
          pars.set(key, val);
          keyStart = i+1;
          eq = valStart = valEnd = -1;
          hasEsc = false;
        }
      }

      if (keyStart < s.Length)
      {
        if (valEnd < 0) valEnd = s.Length-1;
        string key = s.Substring(keyStart, eq-keyStart).Trim();
        string val = s.Substring(valStart, valEnd+1-valStart).Trim();
        if (hasEsc) val = unescape(val);
        pars.set(key, val);
      }

      return pars;
    }

    private static string unescape(string s)
    {
      StringBuilder buf = new StringBuilder(s.Length);
      for (int i=0; i<s.Length; ++i)
      {
        int c = s[i];
        if (c != '\\') buf.Append((char)c);
        else if (s[i+1] == '\\') { buf.Append('\\'); i++; }
      }
      return buf.ToString();
    }

  //////////////////////////////////////////////////////////////////////////
  // Extension
  //////////////////////////////////////////////////////////////////////////

    public static MimeType forExt(string s)
    {
      if (s == null) return null;
      try
      {
        string val = (string)Sys.m_sysPod.props(m_etcUri, Duration.m_oneMin).get(FanStr.lower(s));
        if (val == null) return null;
        return MimeType.fromStr(val);
      }
      catch (System.Exception e)
      {
        System.Console.WriteLine("MimeType.forExt: " + s);
        Err.dumpStack(e);
        return null;
      }
    }

    static readonly Uri m_etcUri = Uri.fromStr("ext2mime.props");

  //////////////////////////////////////////////////////////////////////////
  // Identity
  //////////////////////////////////////////////////////////////////////////

    public override bool Equals(object obj)
    {
      if (!(obj is MimeType)) return false;
      MimeType x = (MimeType)obj;
      return
        m_mediaType == x.m_mediaType &&
        m_subType == x.m_subType &&
        m_params.Equals(x.m_params);
    }

    public override int GetHashCode()
    {
      return m_mediaType.GetHashCode() ^
             m_subType.GetHashCode() ^
             m_params.GetHashCode();
    }

    public override long hash()
    {
      return GetHashCode();
    }

    public override string toStr()
    {
      return m_str;
    }

    public override Type @typeof()
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

    public Charset charset()
    {
      string s = (string)m_params.get("charset");
      if (s == null) return Charset.utf8();
      return Charset.fromStr(s);
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
        q.caseInsensitive(true);
        q = (Map)q.toImmutable();
        m_emptyQuery = q;
      }
      return q;
    }
    static Map m_emptyQuery;

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    internal static MimeType m_imagePng   = parse("image/png");
    internal static MimeType m_imageGif   = parse("image/gif");
    internal static MimeType m_imageJpeg  = parse("image/jpeg");
    internal static MimeType m_textPlain  = parse("text/plain");
    internal static MimeType m_textHtml   = parse("text/html");
    internal static MimeType m_textXml    = parse("text/xml");
    internal static MimeType m_dir        = parse("x-directory/normal");
    internal static MimeType m_textPlainUtf8 = parse("text/plain; charset=utf-8");
    internal static MimeType m_textHtmlUtf8  = parse("text/html; charset=utf-8");
    internal static MimeType m_textXmlUtf8   = parse("text/xml; charset=utf-8");

    private string m_mediaType;
    private string m_subType;
    private Map m_params;
    private string m_str;

  }
}