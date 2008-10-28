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
      int slash = s.indexOf('/');
      String media = s.substring(0, slash);
      String sub = s.substring(slash+1, s.length());
      Map params = emptyParams();

      int semi = sub.indexOf(';');
      if (semi > 0)
      {
        params = new Map(Sys.StrType, Sys.StrType);
        params.caseInsensitive(true);
        boolean inQuotes = false;
        int keyStart = semi+1;
        int valStart = -1;
        int valEnd   = -1;
        int eq       = -1;
        for (int i = keyStart; i<sub.length(); ++i)
        {
          int c = sub.charAt(i);

          if (c == '(' && !inQuotes)
            throw ParseErr.make("MimeType", s, "comments not supported").val;

          if (c == '=' && !inQuotes)
          {
            eq = i++;
            while (FanInt.isSpace(sub.charAt(i))) ++i;
            if (sub.charAt(i) == '"') { inQuotes = true; ++i; }
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
            String key = sub.substring(keyStart, eq).trim();
            String val = sub.substring(valStart, valEnd+1).trim();
            params.set(key, val);
            keyStart = i+1;
            eq = valStart = valEnd = -1;
          }
        }

        if (keyStart < sub.length())
        {
          if (valEnd < 0) valEnd = sub.length()-1;
          String key = sub.substring(keyStart, eq).trim();
          String val = sub.substring(valStart, valEnd+1).trim();
          params.set(key, val);
        }

        sub = sub.substring(0, semi).trim();
      }

      MimeType r  = new MimeType();
      r.str       = s;
      r.mediaType = FanStr.lower(media);
      r.subType   = FanStr.lower(sub);
      r.params    = params.ro();
      return r;
    }
    catch (ParseErr.Val e)
    {
      if (!checked) return null;
      throw e;
    }
    catch (Exception e)
    {
      if (!checked) return null;
      throw ParseErr.make("MimeType",  s).val;
    }
  }

//////////////////////////////////////////////////////////////////////////
// Extension
//////////////////////////////////////////////////////////////////////////

  public static MimeType forExt(String s)
  {
    if (s == null) return null;
    synchronized (extLock)
    {
      if (extMap == null) extMap = loadExtMap();
      return (MimeType)extMap.get(FanStr.lower(s));
    }
  }

  static HashMap loadExtMap()
  {
    try
    {
      LocalFile f = new LocalFile(new java.io.File(Sys.HomeDir, "lib" + File.sep + "ext2mime.props"));
      Map props = f.readProps();
      HashMap map = new HashMap((int)props.size() * 3);
      Iterator it = props.pairsIterator();
      while (it.hasNext())
      {
        Entry entry = (Entry)it.next();
        String ext  = (String)entry.getKey();
        String mime = (String)entry.getValue();
        try
        {
          map.put(FanStr.lower(ext), fromStr(mime));
        }
        catch (Exception e)
        {
          System.out.println("WARNING: Invalid entry in lib/ext2mime.props: " + ext + ": " + mime);
        }
      }
      return map;
    }
    catch (Exception e)
    {
      System.out.println("WARNING: Cannot load lib/ext2mime.props");
      System.out.println("  " + e);
    }
    return new HashMap();
  }

  static Object extLock = new Object();
  static HashMap extMap;

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

  public Type type()
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
      q = q.toImmutable();
      emptyQuery = q;
    }
    return q;
  }
  static Map emptyQuery;

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  static final MimeType dir = fromStr("x-directory/normal");

  private String mediaType;
  private String subType;
  private Map params;
  private String str;

}