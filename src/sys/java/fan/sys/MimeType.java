//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   14 May 08  Brian Frank  Creation
//

package fan.sys;

import java.util.HashMap;
import java.util.Map.Entry;
import java.util.Iterator;

/**
 * MimeType represents the parsed value of a Content-Type
 * header per RFC 2045 section 5.1.
 */
public final class MimeType
  extends FanObj
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  public static MimeType fromStr(String s) { return fromStr(s, true); }
  public static MimeType fromStr(String s, boolean checked)
  {
    try
    {
      // common interned mime types
      switch (s.charAt(0))
      {
        case 'i':
          if (s.equals("image/png"))  return imagePng;
          if (s.equals("image/jpeg")) return imageJpeg;
          if (s.equals("image/gif"))  return imageGif;
          break;
        case 't':
          if (s.equals("text/plain")) return textPlain;
          if (s.equals("text/html"))  return textHtml;
          if (s.equals("text/xml"))   return textXml;
          if (s.equals("text/plain; charset=utf-8")) return textPlainUtf8;
          if (s.equals("text/html; charset=utf-8"))  return textHtmlUtf8;
          if (s.equals("text/xml; charset=utf-8"))   return textXmlUtf8;
          break;
        case 'x':
          if (s.equals("x-directory/normal")) return dir;
          break;
      }

      // parse
      return parse(s);
    }
    catch (ParseErr e)
    {
      if (!checked) return null;
      throw e;
    }
    catch (Exception e)
    {
      if (!checked) return null;
      throw ParseErr.make("MimeType",  s);
    }
  }

  private static MimeType parse(String s)
  {
    int slash = s.indexOf('/');
    String media = s.substring(0, slash);
    String sub = s.substring(slash+1, s.length());
    Map params = emptyParams();

    int semi = sub.indexOf(';');
    if (semi > 0)
    {
      params = doParseParams(sub, semi+1);
      sub = sub.substring(0, semi).trim();
    }

    MimeType r  = new MimeType();
    r.str       = s;
    r.mediaType = FanStr.lower(media);
    r.subType   = FanStr.lower(sub);
    r.params    = params.ro();
    return r;
  }

  public static Map parseParams(String s) { return parseParams(s, true); }
  public static Map parseParams(String s, boolean checked)
  {
    try
    {
      return doParseParams(s, 0);
    }
    catch (ParseErr e)
    {
      if (!checked) return null;
      throw e;
    }
    catch (Exception e)
    {
      if (!checked) return null;
      throw ParseErr.make("MimeType params",  s);
    }
  }

  private static Map doParseParams(String s, int offset)
  {
    Map params = new Map(Sys.StrType, Sys.StrType);
    params.caseInsensitive(true);
    boolean inQuotes = false;
    int keyStart = offset;
    int valStart = -1;
    int valEnd   = -1;
    int eq       = -1;
    boolean hasEsc = false;
    for (int i = keyStart; i<s.length(); ++i)
    {
      int c = s.charAt(i);

      if (c == '(' && !inQuotes)
        throw ParseErr.make("MimeType", s, "comments not supported");

      if (c == '=' && !inQuotes)
      {
        eq = i++;
        while (FanInt.isSpace(s.charAt(i))) ++i;
        if (s.charAt(i) == '"') { inQuotes = true; ++i; }
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
        String key = s.substring(keyStart, eq).trim();
        String val = s.substring(valStart, valEnd+1).trim();
        if (hasEsc) val = unescape(val);
        params.set(key, val);
        keyStart = i+1;
        eq = valStart = valEnd = -1;
        hasEsc = false;
      }
    }

    if (keyStart < s.length())
    {
      if (valEnd < 0) valEnd = s.length()-1;
      String key = s.substring(keyStart, eq).trim();
      String val = s.substring(valStart, valEnd+1).trim();
      if (hasEsc) val = unescape(val);
      params.set(key, val);
    }

    return params;
  }

  private static String unescape(String s)
  {
    StringBuilder buf = new StringBuilder(s.length());
    for (int i=0; i<s.length(); ++i)
    {
      int c = s.charAt(i);
      if (c != '\\') buf.append((char)c);
      else if (s.charAt(i+1) == '\\') { buf.append('\\'); i++; }
    }
    return buf.toString();
  }

//////////////////////////////////////////////////////////////////////////
// Extension
//////////////////////////////////////////////////////////////////////////

  public static MimeType forExt(String s)
  {
    if (s == null) return null;
    try
    {
      String val = (String)Sys.sysPod.props(etcUri, Duration.oneMin).get(FanStr.lower(s));
      if (val == null) return null;
      return MimeType.fromStr(val);
    }
    catch (Exception e)
    {
      System.out.println("MimeType.forExt: " + s);
      e.printStackTrace();
      return null;
    }
  }

  static final Uri etcUri = Uri.fromStr("ext2mime.props");

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  public boolean equals(Object obj)
  {
    if (!(obj instanceof MimeType)) return false;
    MimeType x = (MimeType)obj;
    return mediaType.equals(x.mediaType) &&
           subType.equals(x.subType) &&
           params.equals(x.params);
  }

  public int hashCode()
  {
    return mediaType.hashCode() ^
           subType.hashCode() ^
           params.hashCode();
  }

  public long hash()
  {
    return hashCode();
  }

  public String toStr()
  {
    return str;
  }

  public Type typeof()
  {
    return Sys.MimeTypeType;
  }

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  public String mediaType()
  {
    return mediaType;
  }

  public String subType()
  {
    return subType;
  }

  public Map params()
  {
    return params;
  }

  public Charset charset()
  {
    String s = (String)params().get("charset");
    if (s == null) return Charset.utf8;
    return Charset.fromStr(s);
  }

//////////////////////////////////////////////////////////////////////////
// Lazy Load
//////////////////////////////////////////////////////////////////////////

  static Map emptyParams()
  {
    Map q = emptyQuery;
    if (q == null)
    {
      q = new Map(Sys.StrType, Sys.StrType);
      q.caseInsensitive(true);
      q = (Map)q.toImmutable();
      emptyQuery = q;
    }
    return q;
  }
  static Map emptyQuery;

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  static final MimeType imagePng   = parse("image/png");
  static final MimeType imageGif   = parse("image/gif");
  static final MimeType imageJpeg  = parse("image/jpeg");
  static final MimeType textPlain  = parse("text/plain");
  static final MimeType textHtml   = parse("text/html");
  static final MimeType textXml    = parse("text/xml");
  static final MimeType dir        = parse("x-directory/normal");
  static final MimeType textPlainUtf8 = parse("text/plain; charset=utf-8");
  static final MimeType textHtmlUtf8  = parse("text/html; charset=utf-8");
  static final MimeType textXmlUtf8   = parse("text/xml; charset=utf-8");

  private String mediaType;
  private String subType;
  private Map params;
  private String str;

}