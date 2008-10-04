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

  public static MimeType fromStr(Str s) { return fromStr(s, Bool.True); }
  public static MimeType fromStr(Str s, Bool checked)
  {
    try
    {
      int slash = s.val.indexOf('/');
      String media = s.val.substring(0, slash);
      String sub = s.val.substring(slash+1, s.val.length());
      Map params = emptyParams();

      int semi = sub.indexOf(';');
      if (semi > 0)
      {
        params = new Map(Sys.StrType, Sys.StrType);
        params.caseInsensitive(Bool.True);
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
            while (Int.isSpace(sub.charAt(i))) ++i;
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
            params.set(Str.make(key), Str.make(val));
            keyStart = i+1;
            eq = valStart = valEnd = -1;
          }
        }

        if (keyStart < sub.length())
        {
          if (valEnd < 0) valEnd = sub.length()-1;
          String key = sub.substring(keyStart, eq).trim();
          String val = sub.substring(valStart, valEnd+1).trim();
          params.set(Str.make(key), Str.make(val));
        }

        sub = sub.substring(0, semi).trim();
      }

      MimeType r  = new MimeType();
      r.str       = s;
      r.mediaType = Str.make(Str.lower(media));
      r.subType   = Str.make(Str.lower(sub));
      r.params    = params.ro();
      return r;
    }
    catch (ParseErr.Val e)
    {
      if (!checked.val) return null;
      throw e;
    }
    catch (Exception e)
    {
      if (!checked.val) return null;
      throw ParseErr.make("MimeType",  s).val;
    }
  }

//////////////////////////////////////////////////////////////////////////
// Extension
//////////////////////////////////////////////////////////////////////////

  public static MimeType forExt(Str s)
  {
    if (s == null) return null;
    synchronized (extLock)
    {
      if (extMap == null) extMap = loadExtMap();
      return (MimeType)extMap.get(s.lower());
    }
  }

  static HashMap loadExtMap()
  {
    try
    {
      LocalFile f = new LocalFile(new java.io.File(Sys.HomeDir, "lib" + File.sep + "ext2mime.props"));
      Map props = f.readProps();
      HashMap map = new HashMap((int)props.size().val * 3);
      Iterator it = props.pairsIterator();
      while (it.hasNext())
      {
        Entry entry = (Entry)it.next();
        Str ext  = (Str)entry.getKey();
        Str mime = (Str)entry.getValue();
        try
        {
          map.put(ext.lower(), fromStr(mime));
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

  public Bool _equals(Object obj)
  {
    if (!(obj instanceof MimeType)) return Bool.False;
    MimeType x = (MimeType)obj;
    return Bool.make(
      mediaType.val.equals(x.mediaType.val) &&
      subType.val.equals(x.subType.val) &&
      params.equals(x.params));
  }

  public int hashCode()
  {
    return mediaType.val.hashCode() ^
           subType.val.hashCode() ^
           params.hashCode();
  }

  public Int hash()
  {
    return Int.make(hashCode());
  }

  public Str toStr()
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

  public Str mediaType()
  {
    return mediaType;
  }

  public Str subType()
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
      q.caseInsensitive(Bool.True);
      q = q.toImmutable();
      emptyQuery = q;
    }
    return q;
  }
  static Map emptyQuery;

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  static final MimeType dir = fromStr(Str.make("x-directory/normal"));

  private Str mediaType;
  private Str subType;
  private Map params;
  private Str str;

}