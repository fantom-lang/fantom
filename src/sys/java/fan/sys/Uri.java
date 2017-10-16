//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   28 Jun 06  Brian Frank  Creation
//   01 Aug 07  Brian        Rewrite with our own parser/encoder
//
package fan.sys;

import fanx.serial.*;
import fanx.util.*;

/**
 * Uri is used to immutably represent a Universal Resource Identifier.
 */
public final class Uri
  extends FanObj
  implements Literal
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  public static Uri fromStr(String s) { return fromStr(s, true); }
  public static Uri fromStr(String s, boolean checked)
  {
    try
    {
      return new Uri(new Decoder(s, false).decode());
    }
    catch (ParseErr e)
    {
      if (!checked) return null;
      throw ParseErr.make("Uri", s, e.msg());
    }
    catch (Exception e)
    {
      if (!checked) return null;
      throw ParseErr.make("Uri",  s);
    }
  }

  public static Uri decode(String s) { return decode(s, true); }
  public static Uri decode(String s, boolean checked)
  {
    try
    {
      return new Uri(new Decoder(s, true).decode());
    }
    catch (ParseErr e)
    {
      if (!checked) return null;
      throw ParseErr.make("Uri",  s, e.msg());
    }
    catch (Exception e)
    {
      if (!checked) return null;
      throw ParseErr.make("Uri",  s);
    }
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  public static Map decodeQuery(String s)
  {
    try
    {
      return new Decoder(s, true).decodeQuery();
    }
    catch (ArgErr e)
    {
      throw ArgErr.make("Invalid Uri query: `" + s + "`: " + e.msg());
    }
    catch (Exception e)
    {
      throw ArgErr.make("Invalid Uri query: `" + s + "`");
    }
  }

  public static String encodeQuery(Map map)
  {
    StringBuilder buf = new StringBuilder(256);
    java.util.Iterator it = map.keysIterator();
    while (it.hasNext())
    {
      String key = (String)it.next();
      String val = (String)map.get(key);
      if (buf.length() > 0) buf.append('&');
      encodeQueryStr(buf, key);
      if (val != null)
      {
        buf.append('=');
        encodeQueryStr(buf, val);
      }
    }
    return buf.toString();
  }

  static void encodeQueryStr(StringBuilder buf, String str)
  {
    for (int i=0; i<str.length(); ++i)
    {
      int c = str.charAt(i);
      if (c < 128 && (charMap[c] & QUERY) != 0 && (delimEscMap[c] & QUERY) == 0)
        buf.append((char)c);
      else if (c == ' ')
        buf.append('+');
      else
        percentEncodeChar(buf, c);
    }
  }

//////////////////////////////////////////////////////////////////////////
// Tokens
//////////////////////////////////////////////////////////////////////////

  public static String escapeToken(String str, long section)
  {
    int mask = sectionToMask(section);
    StringBuilder buf = new StringBuilder(str.length()+4);
    for (int i=0; i<str.length(); ++i)
    {
      int c = str.charAt(i);
      if (c < delimEscMap.length && (delimEscMap[c] & mask) != 0)
        buf.append((char)'\\');
      buf.append((char)c);
    }
    return buf.toString();
  }

  public static String encodeToken(String str, long section)
  {
    int mask = sectionToMask(section);
    StringBuilder buf = new StringBuilder(str.length()+4);
    for (int i=0; i<str.length(); ++i)
    {
      int c = str.charAt(i);
      if (c < 128 && (charMap[c] & mask) != 0 && (delimEscMap[c] & mask) == 0)
        buf.append((char)c);
      else
        percentEncodeChar(buf, c);
    }
    return buf.toString();
  }

  public static String decodeToken(String str, long section)
  {
    int mask = sectionToMask(section);
    if (str.length() == 0) return "";
    return new Decoder(str, true).decodeToken(mask);
  }

  public static String unescapeToken(String str)
  {
    StringBuilder buf = new StringBuilder(str.length());
    for (int i=0; i<str.length(); ++i)
    {
      int c = str.charAt(i);
      if (c == '\\')
      {
        i++;
        if (i>=str.length()) throw ArgErr.make("Invalid esc: " + str);
        c = str.charAt(i);
      }
      buf.append((char)c);
    }
    return buf.toString();
  }

  private static int sectionToMask(long section)
  {
    switch ((int)section)
    {
      case 1:  return PATH;
      case 2:  return QUERY;
      case 3:  return FRAG;
      default: throw ArgErr.make("Invalid section flag: " + section);
    }
  }

  public static final long sectionPath  = 1;
  public static final long sectionQuery = 2;
  public static final long sectionFrag  = 3;

//////////////////////////////////////////////////////////////////////////
// Java Constructors
//////////////////////////////////////////////////////////////////////////

  private Uri(Sections x)
  {
    scheme   = x.scheme;
    userInfo = x.userInfo;
    host     = x.host;
    port     = x.port;
    pathStr  = x.pathStr;
    path     = x.path.ro();
    queryStr = x.queryStr;
    query    = x.query.ro();
    frag     = x.frag;
    str      = x.str != null ? x.str : new Encoder(this, false).encode();
  }

//////////////////////////////////////////////////////////////////////////
// Sections
//////////////////////////////////////////////////////////////////////////

  static class Sections
  {
    void setAuth(Uri x)  { userInfo = x.userInfo; host = x.host; port = x.port; }
    void setPath(Uri x)  { pathStr = x.pathStr; path = x.path; }
    void setQuery(Uri x) { queryStr = x.queryStr; query = x.query; }
    void setFrag(Uri x)  { frag = x.frag; }

    void normalize()
    {
      normalizeSchemes();
      normalizePath();
      normalizeQuery();
    }

    private void normalizeSchemes()
    {
      if (scheme == null) return;
      if (scheme.equals("http"))  { normalizeScheme(80);  return; }
      if (scheme.equals("https")) { normalizeScheme(443); return; }
      if (scheme.equals("ftp"))   { normalizeScheme(21);  return; }
    }

    private void normalizeScheme(int p)
    {
      // port  -> null
      if (port != null && port.longValue() == p) port = null;

      // if path is "" -> "/"
      if (pathStr == null || pathStr.length() == 0)
      {
        pathStr = "/";
        if (path == null) path = emptyPath();
      }
    }

    private void normalizePath()
    {
      if (path == null) return;

      boolean isAbs = pathStr.startsWith("/");
      boolean isDir = pathStr.endsWith("/");
      boolean dotLast = false;
      boolean modified = false;
      for (int i=0; i<path.sz(); ++i)
      {
        String seg = (String)path.get(i);
        if (seg.equals(".") && (path.sz() > 1 || host != null))
        {
          if (path.isRO()) path = path.rw();
          path.removeAt(i);
          modified = true;
          dotLast = true;
          i -= 1;
        }
        else if (seg.equals("..") && i > 0 && !path.get(i-1).toString().equals(".."))
        {
          if (path.isRO()) path = path.rw();
          path.removeAt(i);
          path.removeAt(i-1);
          modified = true;
          i -= 2;
          dotLast = true;
        }
        else
        {
          dotLast = false;
        }
      }

      if (modified)
      {
        if (dotLast) isDir = true;
        if (path.sz() == 0 || path.last().toString().equals("..")) isDir = false;
        pathStr = toPathStr(isAbs, path, isDir);
      }
    }

    private void normalizeQuery()
    {
      if (query == null)
        query = emptyQuery();
    }

    String scheme;
    String host;
    String userInfo;
    Long port;
    String pathStr;
    List path;
    String queryStr;
    Map query;
    String frag;
    String str;
  }

//////////////////////////////////////////////////////////////////////////
// Decoder
//////////////////////////////////////////////////////////////////////////

  static class Decoder extends Sections
  {
    Decoder(String str, boolean decoding)
    {
      this.str = str;
      this.decoding = decoding;
    }

    Decoder decode()
    {
      String str = this.str;
      int len = str.length();
      int pos = 0;

      // ==== scheme ====

      // scan the string from the beginning looking for either a
      // colon or any character which doesn't fit a valid scheme
      boolean hasUpper = false;
      for (int i=0; i<len; ++i)
      {
        int c = str.charAt(i);
        if (isScheme(c)) { hasUpper |= isUpper(c); continue; }
        if (c != ':') break;

        // at this point we have a scheme; if we detected
        // any upper case characters normalize to lowercase
        pos = i + 1;
        String scheme = str.substring(0, i);
        if (hasUpper) scheme = FanStr.lower(scheme);
        this.scheme = scheme;
        break;
      }

      // ==== authority ====

      // authority must start with //
      if (pos+1 < len && str.charAt(pos) == '/' && str.charAt(pos+1) == '/')
      {
        // find end of authority which is /, ?, #, or end of string;
        // while we're scanning look for @ and last colon which isn't
        // inside an [] IPv6 literal
        int authStart = pos+2, authEnd = len, at = -1, colon = -1;
        for (int i=authStart; i<len; ++i)
        {
          int c = str.charAt(i);
          if (c == '/' || c == '?' || c == '#') { authEnd = i; break; }
          else if (c == '@' && at < 0) { at = i; colon = -1; }
          else if (c == ':') colon = i;
          else if (c == ']') colon = -1;
        }

        // start with assumption that there is no userinfo or port
        int hostStart = authStart, hostEnd = authEnd;

        // if we found an @ symbol, parse out userinfo
        if (at > 0)
        {
          this.userInfo = substring(authStart, at, USER);
          hostStart = at+1;
        }

        // if we found an colon, parse out port
        if (colon > 0)
        {
          this.port = Long.valueOf(Integer.parseInt(str.substring(colon+1, authEnd)));
          hostEnd = colon;
        }

        // host is everything left in the authority
        this.host = substring(hostStart, hostEnd, HOST);
        pos = authEnd;
      }

      // ==== path ====

      // scan the string looking '?' or '#' which ends the path
      // section; while we're scanning count the number of slashes
      int pathStart = pos, pathEnd = len, numSegs = 1, prev = 0;
      for (int i=pathStart; i<len; ++i)
      {
        int c = str.charAt(i);
        if (prev != '\\')
        {
          if (c == '?' || c == '#') { pathEnd = i; break; }
          if (i != pathStart && c == '/') ++numSegs;
          prev = c;
        }
        else
        {
          prev = (c != '\\') ? c : 0;
        }
      }

      // we now have the complete path section
      this.pathStr = substring(pathStart, pathEnd, PATH);
      this.path = pathSegments(pathStr, numSegs);
      pos = pathEnd;

      // ==== query ====

      if (pos < len && str.charAt(pos) == '?')
      {
        // look for end of query which is # or end of string
        int queryStart = pos+1, queryEnd = len; prev = 0;
        for (int i=queryStart; i<len; ++i)
        {
          int c = str.charAt(i);
          if (prev != '\\')
          {
            if (c == '#') { queryEnd = i; break; }
            prev = c;
          }
          else
          {
            prev = (c != '\\') ? c : 0;
          }
        }

        // we now have the complete query section
        this.queryStr = substring(queryStart, queryEnd, QUERY);
        this.query = parseQuery(queryStr);
        pos = queryEnd;
      }

      // ==== frag ====

      if (pos < len  && str.charAt(pos) == '#')
      {
        this.frag = substring(pos+1, len, FRAG);
      }

      // === normalize ===
      normalize();

      // if decoding, then we don't want to use original
      // str as Uri.str, so null it out
      this.str = null;

      return this;
    }

    private List pathSegments(String pathStr, int numSegs)
    {
      // if pathStr is "/" then path is the empty list
      int len = pathStr.length();
      if (len == 0 || (len == 1 && pathStr.charAt(0) == '/'))
        return emptyPath();

      // check for trailing slash (unless backslash escaped)
      if (charAtSafe(pathStr, len-1) == '/'  && charAtSafe(pathStr, len-2) != '\\')
      {
        numSegs--;
        len--;
      }

      // parse the segments
      String[] path = new String[numSegs];
      int n = 0;
      int segStart = 0, prev = 0;
      for (int i=0; i<pathStr.length(); ++i)
      {
        int c = pathStr.charAt(i);
        if (prev != '\\')
        {
          if (c == '/')
          {
            if (i > 0) path[n++] = pathStr.substring(segStart, i);
            segStart = i+1;
          }
          prev = c;
        }
        else
        {
          prev = (c != '\\') ? c : 0;
        }
      }
      if (segStart < len)
        path[n++] = pathStr.substring(segStart, pathStr.length());

      return new List(Sys.StrType, path);
    }

    String decodeToken(int mask)
    {
      return substring(0, str.length(), mask);
    }

    Map decodeQuery()
    {
      return parseQuery(substring(0, str.length(), QUERY));
    }

    private Map parseQuery(String q)
    {
      if (q == null) return null;
      Map map = new Map(Sys.StrType, Sys.StrType);

      try
      {
        int start = 0, eq = 0, len = q.length(), prev = 0;
        boolean escaped = false;
        for (int i=0; i<len; ++i)
        {
          int ch = q.charAt(i);
          if (prev != '\\')
          {
            if (ch == '=') eq = i;
            if (ch != '&' && ch != ';') { prev = ch; continue; }
          }
          else
          {
            escaped = true;
            prev = (ch != '\\') ? ch : 0;
            continue;
          }

          if (start < i)
          {
            addQueryParam(map, q, start, eq, i, escaped);
            escaped = false;
          }

          start = eq = i+1;
        }

        if (start < len)
          addQueryParam(map, q, start, eq, len, escaped);
      }
      catch (Exception e)
      {
        // don't let internal error bring down whole uri
        e.printStackTrace();
      }

      return map;
    }

    private void addQueryParam(Map map, String q, int start, int eq, int end, boolean escaped)
    {
      String key, val;
      if (start == eq && q.charAt(start) != '=')
      {
        key = toQueryStr(q, start, end, escaped);
        val = "true";
      }
      else
      {
        key = toQueryStr(q, start, eq, escaped);
        val = toQueryStr(q, eq+1, end, escaped);
      }

      String dup = (String)map.get(key);
      if (dup != null) val = dup + "," + val;
      map.set(key, val);
    }

    private String toQueryStr(String q, int start, int end, boolean escaped)
    {
      if (!escaped) return q.substring(start, end);
      StringBuilder s = new StringBuilder(end-start);
      int prev = 0;
      for (int i=start; i<end; ++i)
      {
        int c = q.charAt(i);
        if (c != '\\')
        {
          s.append((char)c);
          prev = c;
        }
        else
        {
          if (prev == '\\') { s.append((char)c); prev = 0; }
          else prev = c;
        }
      }
      return s.toString();
    }

    private String substring(int start, int end, int section)
    {
      StringBuilder buf = new StringBuilder(end-start);
      if (!decoding)
      {
        int last = 0;
        for (int i=start; i<end; ++i)
        {
          int ch = str.charAt(i);
          if (last == '\\' && ch < delimEscMap.length && (delimEscMap[ch] & section) == 0)
          {
            buf.setLength(buf.length()-1); // don't allow backslash unless truly a delimiter
          }
          buf.append((char)ch);
          last = last == '\\' && ch == '\\' ? 0 : ch;
        }
      }
      else
      {
        dpos = start;
        while (dpos < end)
        {
          int ch = nextChar(section);
          if (nextCharWasEscaped && ch < delimEscMap.length && (delimEscMap[ch] & section) != 0)
          {
            buf.append('\\');  // if ch was an escaped delimiter
          }
          buf.append((char)ch);
        }
      }
      return buf.toString();
    }

    private int nextChar(int section)
    {
      int c = nextOctet(section);
      if (c < 0) return -1;
      int c2, c3;
      switch (c >> 4)
      {
        case 0: case 1: case 2: case 3: case 4: case 5: case 6: case 7:
          /* 0xxxxxxx*/
          return c;
        case 12: case 13:
          /* 110x xxxx   10xx xxxx*/
          c2 = nextOctet(section);
          if ((c2 & 0xC0) != 0x80)
            throw err("Invalid UTF-8 encoding");
          return ((c & 0x1F) << 6) | (c2 & 0x3F);
        case 14:
          /* 1110 xxxx  10xx xxxx  10xx xxxx */
          c2 = nextOctet(section);
          c3 = nextOctet(section);
          if (((c2 & 0xC0) != 0x80) || ((c3 & 0xC0) != 0x80))
            throw err("Invalid UTF-8 encoding");
          return (((c & 0x0F) << 12) | ((c2 & 0x3F) << 6) | ((c3 & 0x3F) << 0));
        default:
          throw err("Invalid UTF-8 encoding");
      }
    }

    private int nextOctet(int section)
    {
      int c = str.charAt(dpos++);

      // if percent encoded applied to all sections except
      // scheme which should never never use this method
      if (c == '%')
      {
        nextCharWasEscaped = true;
        return (hexNibble(str.charAt(dpos++)) << 4) | hexNibble(str.charAt(dpos++));
      }
      else
      {
        nextCharWasEscaped = false;
      }

      // + maps to space only in query
      if (c == '+' && section == QUERY)
        return ' ';

      // verify character ok
      if (c >= charMap.length || (charMap[c] & section) == 0)
        throw err("Invalid char in " + toSection(section) + " at index " + (dpos-1));

      // return character as is
      return c;
    }

    static int charAtSafe(String s, int index)
    {
      if (index < s.length()) return s.charAt(index);
      return 0;
    }

    boolean decoding;
    int dpos;
    boolean nextCharWasEscaped;
  }

//////////////////////////////////////////////////////////////////////////
// Encoder
//////////////////////////////////////////////////////////////////////////

  static class Encoder
  {
    Encoder(Uri uri, boolean encoding)
    {
      this.uri = uri;
      this.encoding = encoding;
      this.buf = new StringBuilder();
    }

    String encode()
    {
      Uri uri = this.uri;
      StringBuilder buf = this.buf;

      // scheme
      if (uri.scheme != null) buf.append(uri.scheme).append(':');

      // authority
      if (uri.userInfo != null || uri.host != null || uri.port != null)
      {
        buf.append('/').append('/');
        if (uri.userInfo != null) encode(uri.userInfo, USER).append('@');
        if (uri.host != null) encode(uri.host, HOST);
        if (uri.port != null) buf.append(':').append(uri.port.longValue());
      }

      // path
      if (uri.pathStr != null)
        encode(uri.pathStr, PATH);

      // query
      if (uri.queryStr != null)
        { buf.append('?'); encode(uri.queryStr, QUERY); }

      // frag
      if (uri.frag != null)
        { buf.append('#'); encode(uri.frag, FRAG); }

      return buf.toString();
    }

    StringBuilder encode(String s, int section)
    {
      if (!encoding) return buf.append(s);

      StringBuilder buf = this.buf;
      int len = s.length();
      int c = 0, prev;
      for (int i=0; i<len; ++i)
      {
        prev = c;
        c = s.charAt(i);

        // unreserved character
        if (c < 128 && (charMap[c] & section) != 0 && prev != '\\')
        {
          buf.append((char)c);
          continue;
        }

        // the backslash esc itself doesn't get encoded
        if (c == '\\' && prev != '\\') continue;

        // we have a reserved, escaped, or non-ASCII

        // encode
        if (c == ' ' && section == QUERY)
          buf.append('+');
        else
          percentEncodeChar(buf, c);

        // if we just encoded backslash, then it
        // doesn't escape the next char
        if (c == '\\') c = 0;
      }
      return buf;
    }

    Uri uri;
    boolean encoding;
    StringBuilder buf;
  }

  static void percentEncodeChar(StringBuilder buf, int c)
  {
    if (c <= 0x007F)
    {
      percentEncodeByte(buf, c);
    }
    else if (c > 0x07FF)
    {
      percentEncodeByte(buf, 0xE0 | ((c >> 12) & 0x0F));
      percentEncodeByte(buf, 0x80 | ((c >>  6) & 0x3F));
      percentEncodeByte(buf, 0x80 | ((c >>  0) & 0x3F));
    }
    else
    {
      percentEncodeByte(buf, 0xC0 | ((c >>  6) & 0x1F));
      percentEncodeByte(buf, 0x80 | ((c >>  0) & 0x3F));
    }
  }

  static void percentEncodeByte(StringBuilder buf, int c)
  {
    buf.append('%');
    int hi = (c >> 4) & 0xf;
    int lo = c & 0xf;
    buf.append((char)(hi < 10 ? '0'+hi : 'A'+(hi-10)));
    buf.append((char)(lo < 10 ? '0'+lo : 'A'+(lo-10)));
  }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  public final boolean equals(Object obj)
  {
    if (obj instanceof Uri)
    {
      return str.equals(((Uri)obj).str);
    }
    return false;
  }

  public int hashCode()
  {
    return str.hashCode();
  }

  public long hash()
  {
    return FanStr.hash(str);
  }

  public String toStr()
  {
    return str;
  }

  public String toLocale()
  {
    return str;
  }

  public void encode(ObjEncoder out)
  {
    out.wStrLiteral(str, '`');
  }

  public Type typeof()
  {
    return Sys.UriType;
  }

  public String encode()
  {
    String x = encoded;
    if (x != null) return x;
    return encoded = new Encoder(this, true).encode();
  }

//////////////////////////////////////////////////////////////////////////
// Components
//////////////////////////////////////////////////////////////////////////

  public boolean isAbs()
  {
    return scheme != null;
  }

  public boolean isRel()
  {
    return scheme == null;
  }

  public boolean isDir()
  {
    if (pathStr != null)
    {
      String p = pathStr;
      int len = p.length();
      if (len > 0 && p.charAt(len-1) == '/')
        return true;
    }
    return false;
  }

  public String scheme()
  {
    return scheme;
  }

  public String auth()
  {
    if (host == null) return null;
    if (port == null)
    {
      if (userInfo == null) return host;
      else return userInfo + '@' + host;
    }
    else
    {
      if (userInfo == null) return host + ':' + port;
      else return userInfo + '@' + host + ':' + port;
    }
  }

  public String host()
  {
    return host;
  }

  public String userInfo()
  {
    return userInfo;
  }

  public Long port()
  {
    return port;
  }

  public final String path(int depth) { return (String)path.get(depth); }
  public List path()
  {
    return path;
  }

  public String pathStr()
  {
    return pathStr;
  }

  public boolean isPathAbs()
  {
    if (pathStr == null || pathStr.length() == 0)
      return false;
    else
      return pathStr.charAt(0) == '/';
  }

  public boolean isPathRel()
  {
    return !isPathAbs();
  }

  public boolean isPathOnly()
  {
    return scheme == null && host == null && port == null &&
           userInfo == null && queryStr == null && frag == null;
  }

  public String name()
  {
    if (path.sz() == 0) return "";
    return (String)path.last();
  }

  public String basename()
  {
    String n = name();
    int dot = n.lastIndexOf('.');
    if (dot < 2)
    {
      if (dot < 0) return n;
      if (n.equals(".")) return n;
      if (n.equals("..")) return n;
    }
    return n.substring(0, dot);
  }

  public String ext()
  {
    String n = name();
    int dot = n.lastIndexOf('.');
    if (dot < 2)
    {
      if (dot < 0) return null;
      if (n.equals(".")) return null;
      if (n.equals("..")) return null;
    }
    return n.substring(dot+1);
  }

  public MimeType mimeType()
  {
    if (isDir()) return MimeType.dir;
    return MimeType.forExt(ext());
  }

  public Map query()
  {
    return query;
  }

  public String queryStr()
  {
    return queryStr;
  }

  public String frag()
  {
    return frag;
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  public Uri parent()
  {
    // if no path bail
    if (path.sz() == 0) return null;

    // if just a simple filename, then no parent
    if (path.sz() == 1 && !isPathAbs() && !isDir()) return null;

    // use slice
    return slice(parentRange, false);
  }

  public Uri pathOnly()
  {
    if (pathStr == null)
      throw Err.make("Uri has no path: " + this);

    if (scheme == null && userInfo == null && host == null &&
        port == null && queryStr == null && frag == null)
      return this;

    Sections t = new Sections();
    t.path     = this.path;
    t.pathStr  = this.pathStr;
    t.query    = emptyQuery();
    t.str      = this.pathStr;
    return new Uri(t);
  }

  public Uri getRange(Range range) { return slice(range, false); }

  public Uri getRangeToPathAbs(Range range) { return slice(range, true); }

  private Uri slice(Range range, boolean forcePathAbs)
  {
    if (pathStr == null)
      throw Err.make("Uri has no path: " + this);

    int size = path.sz();
    int s = range.startIndex(size);
    int e = range.endIndex(size);
    int n = e - s + 1;
    if (n < 0) throw IndexErr.make(range);

    boolean head = (s == 0);
    boolean tail = (e == size-1);
    if (head && tail && (!forcePathAbs || isPathAbs())) return this;

    Sections t = new Sections();
    t.path = path.getRange(range);

    StringBuilder sb = new StringBuilder(pathStr.length());
    if ((head && isPathAbs()) || forcePathAbs) sb.append('/');
    for (int i=0; i<t.path.sz(); ++i)
    {
      if (i > 0) sb.append('/');
      sb.append(t.path.get(i));
    }
    if (t.path.sz() > 0 && (!tail || isDir())) sb.append('/');
    t.pathStr = sb.toString();

    if (head)
    {
      t.scheme   = scheme;
      t.userInfo = userInfo;
      t.host     = host;
      t.port     = port;
    }

    if (tail)
    {
      t.queryStr = queryStr;
      t.query    = query;
      t.frag     = frag;
    }
    else
    {
      t.query    = emptyQuery();
    }

    if (!head && !tail)
    {
      t.str = t.pathStr;
    }

    return new Uri(t);
  }

//////////////////////////////////////////////////////////////////////////
// Relativize
//////////////////////////////////////////////////////////////////////////

  public Uri relTo(Uri base)
  {
    if (!OpUtil.compareEQ(this.scheme,   base.scheme) ||
        !OpUtil.compareEQ(this.userInfo, base.userInfo) ||
        !OpUtil.compareEQ(this.host,     base.host) ||
        !OpUtil.compareEQ(this.port,     base.port))
      return this;

    // at this point we know we have the same scheme and auth, and
    // we're going to create a new URI which is a subset of this one
    Sections t = new Sections();
    t.query    = this.query;
    t.queryStr = this.queryStr;
    t.frag     = this.frag;

    // find divergence
    int d=0;
    int len = Math.min(this.path.sz(), base.path.sz());
    for (; d<len; ++d)
      if (!this.path.get(d).equals(base.path.get(d)))
        break;

    // if diverenge is at root, then no commonality
    if (d == 0)
    {
      // `/a/b/c`.relTo(`/`) should be `a/b/c`
      if (base.path.isEmpty() && this.pathStr.startsWith("/"))
      {
        t.path = this.path;
        t.pathStr = this.pathStr.substring(1);
      }
      else
      {
        t.path = this.path;
        t.pathStr = this.pathStr;
      }
    }

    // if paths are exactly the same
    else if (d == this.path.sz() && d == base.path.sz())
    {
      t.path = emptyPath();
      t.pathStr = "";
    }

    // create sub-path at divergence point
    else
    {
      // slice my path
      t.path = this.path.getRange(Range.makeInclusive(d, -1));

      // insert .. backup if needed
      int backup = base.path.sz() - d;
      if (!base.isDir()) backup--;
      while (backup-- > 0) t.path.insert(0L, "..");

      // format the new path string
      t.pathStr = toPathStr(false, t.path, this.isDir());
    }

    return new Uri(t);
  }

  public Uri relToAuth()
  {
    if (scheme == null && userInfo == null &&
        host == null && port == null)
      return this;

    Sections t = new Sections();
    t.path     = this.path;
    t.pathStr  = this.pathStr;
    t.query    = this.query;
    t.queryStr = this.queryStr;
    t.frag     = this.frag;
    return new Uri(t);
  }

//////////////////////////////////////////////////////////////////////////
// Plus
//////////////////////////////////////////////////////////////////////////

  public Uri plus(Uri r)
  {
    // if r is more or equal as absolute as base, return r
    if (r.scheme != null) return r;
    if (r.host != null && this.scheme == null) return r;
    if (r.isPathAbs() && this.host == null) return r;

    // this algorthm is lifted straight from
    // RFC 3986 (5.2.2) Transform References;
    Uri base = this;
    Sections t = new Sections();
    if (r.host != null)
    {
      t.setAuth(r);
      t.setPath(r);
      t.setQuery(r);
    }
    else
    {
      if (r.pathStr == null || r.pathStr.equals(""))
      {
        t.setPath(base);
        if (r.queryStr != null)
          t.setQuery(r);
        else
          t.setQuery(base);
      }
      else
      {
        if (r.pathStr.startsWith("/"))
          t.setPath(r);
        else
          merge(t, base, r);
        t.setQuery(r);
      }
      t.setAuth(base);
    }
    t.scheme = base.scheme;
    t.frag   = r.frag;
    t.normalize();
    return new Uri(t);
  }

  static void merge(Sections t, Uri base, Uri r)
  {
    boolean baseIsAbs = base.isPathAbs();
    boolean baseIsDir = base.isDir();
    boolean rIsDir    = r.isDir();
    List rPath        = r.path;
    boolean dotLast   = false;

    // compute the target path taking into account whether
    // the base is a dir and any dot segments in relative ref
    List tPath;
    if (base.path.sz() == 0)
    {
      tPath = r.path;
    }
    else
    {
      tPath = base.path.rw();
      if (!baseIsDir) tPath.pop();
      for (int i=0; i<rPath.sz(); ++i)
      {
        String rSeg = (String)rPath.get(i);
        if (rSeg.equals(".")) { dotLast = true; continue; }
        if (rSeg.equals(".."))
        {
          if (!tPath.isEmpty()) { tPath.pop(); dotLast = true; continue; }
          if (baseIsAbs) continue;
        }
        tPath.add(rSeg); dotLast = false;
      }
    }

    t.path = tPath;
    t.pathStr = toPathStr(baseIsAbs, tPath, rIsDir || dotLast);
  }

  static String toPathStr(boolean isAbs, List path, boolean isDir)
  {
    StringBuilder buf = new StringBuilder();
    if (isAbs) buf.append('/');
    for (int i=0; i<path.sz(); ++i)
    {
      if (i > 0) buf.append('/');
      buf.append(path.get(i));
    }
    if (isDir && !(buf.length() > 0 && buf.charAt(buf.length()-1) == '/'))
      buf.append('/');
    return buf.toString();
  }

  public Uri plusName(String name) { return plusName(name, false); }
  public Uri plusName(String name, boolean asDir)
  {
    int size         = path.sz();
    boolean isDir    = isDir() || path.isEmpty();
    int newSize      = isDir ? size + 1 : size;
    String[] temp    = (String[])path.toArray(new String[newSize]);
    temp[newSize-1]  = name;

    Sections t = new Sections();
    t.scheme   = this.scheme;
    t.userInfo = this.userInfo;
    t.host     = this.host;
    t.port     = this.port;
    t.query    = emptyQuery();
    t.queryStr = null;
    t.frag     = null;
    t.path     = new List(Sys.StrType, temp);
    t.pathStr  = toPathStr(isAbs() || isPathAbs(), t.path, asDir);
    return new Uri(t);
  }

  public Uri plusSlash()
  {
    if (isDir()) return this;
    Sections t = new Sections();
    t.scheme   = this.scheme;
    t.userInfo = this.userInfo;
    t.host     = this.host;
    t.port     = this.port;
    t.query    = this.query;
    t.queryStr = this.queryStr;
    t.frag     = this.frag;
    t.path     = this.path;
    t.pathStr  = this.pathStr + "/";
    return new Uri(t);
  }

  public Uri plusQuery(Map q)
  {
    if (q == null || q.isEmpty()) return this;

    Map merge = this.query.dup().setAll(q);

    StringBuilder s = new StringBuilder(256);
    java.util.Iterator it = merge.pairsIterator();
    while (it.hasNext())
    {
      if (s.length() > 0) s.append('&');
      java.util.Map.Entry e = (java.util.Map.Entry)it.next();
      String key = (String)e.getKey();
      String val = (String)e.getValue();
      appendQueryStr(s, key);
      s.append('=');
      appendQueryStr(s, val);
    }

    Sections t = new Sections();
    t.scheme   = this.scheme;
    t.userInfo = this.userInfo;
    t.host     = this.host;
    t.port     = this.port;
    t.frag     = this.frag;
    t.pathStr  = this.pathStr;
    t.path     = this.path;
    t.query    = merge.ro();
    t.queryStr = s.toString();
    return new Uri(t);
  }

  static void appendQueryStr(StringBuilder buf, String str)
  {
    for (int i=0; i<str.length(); ++i)
    {
      int c = str.charAt(i);
      if (c < delimEscMap.length && (delimEscMap[c] & QUERY) != 0)
        buf.append('\\');
      buf.append((char)c);
    }
  }

//////////////////////////////////////////////////////////////////////////
// Resolution
//////////////////////////////////////////////////////////////////////////

  public File toFile()
  {
    if (scheme == null || scheme.equals("file")) return File.make(this);
    return (File)get();
  }

  public Object get() { return get(null, true); }
  public Object get(Object base) { return get(base, true); }
  public Object get(Object base, boolean checked)
  {
    // if we have a relative uri, we need to resolve against
    // the base object's uri
    Uri uri = this;
    if (scheme == null)
    {
      if (base == null) throw UnresolvedErr.make("Relative uri with no base: " + this);
      Uri baseUri = null;
      try
      {
        baseUri = (Uri)trap(base, "uri", null);
        if (baseUri == null)
          throw UnresolvedErr.make("Base object's uri is null: " + this);
      }
      catch (Throwable e)
      {
        throw UnresolvedErr.make("Cannot access base '" + FanObj.typeof(base) + ".uri' to normalize: " + this, e);
      }
      if (baseUri.scheme == null)
        throw UnresolvedErr.make("Base object's uri is not absolute: " + baseUri);
      uri = baseUri.plus(this);
    }

    // resolve scheme handler
    UriScheme scheme = UriScheme.find(uri.scheme);

    // route to scheme
    try
    {
      return scheme.get(uri, base);
    }
    catch (UnresolvedErr e)
    {
      if (checked) throw e;
      return null;
    }
  }

//////////////////////////////////////////////////////////////////////////
// Conversion
//////////////////////////////////////////////////////////////////////////

  public String toCode()
  {
    StringBuilder s = new StringBuilder(str.length()+4);
    s.append('`');

    int len = str.length();
    for (int i=0; i<len; ++i)
    {
      int c = str.charAt(i);
      switch (c)
      {
        case '\n': s.append('\\').append('n'); break;
        case '\r': s.append('\\').append('r'); break;
        case '\f': s.append('\\').append('f'); break;
        case '\t': s.append('\\').append('t'); break;
        case '`':  s.append('\\').append('`'); break;
        case '$':  s.append('\\').append('$'); break;
        default:   s.append((char)c);
      }
    }

    // closing quote
    return s.append('`').toString();
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  public static boolean isName(String name)
  {
    int len = name.length();

    // must be at least one character long
    if (len == 0) return false;

    // check for "." and ".."
    if (name.charAt(0) == '.' && len <= 2)
    {
      if (len == 1) return false;
      if (name.charAt(1) == '.') return false;
    }

    // check that each char is unreserved
    for (int i=0; i<len; ++i)
    {
      int c = name.charAt(i);
      if (c < 128 && nameMap[c]) continue;
      return false;
    }

    return true;
  }

  public static void checkName(String name)
  {
    if (!isName(name))
      throw NameErr.make(name);
  }

  static boolean isUpper(int c)
  {
    return 'A' <= c && c <= 'Z';
  }

  static int hexNibble(int ch)
  {
    if ((charMap[ch] & HEX) == 0) throw err("Invalid percent encoded hex: '" + (char)ch);
    if (ch <= '9') return ch - '0';
    if (ch <= 'Z') return (ch - 'A') + 10;
    return (ch - 'a') + 10;
  }

  static RuntimeException err(String msg)
  {
    return ParseErr.make(msg);
  }

//////////////////////////////////////////////////////////////////////////
// Character Map
//////////////////////////////////////////////////////////////////////////

  static String toSection(int section)
  {
    switch (section)
    {
      case SCHEME: return "scheme";
      case USER:   return "userInfo";
      case HOST:   return "host";
      case PATH:   return "path";
      case QUERY:  return "query";
      case FRAG:   return "frag";
      default:     return "uri";
    }
  }

  static boolean isScheme(int c) { return c < 128 ? (charMap[c] & SCHEME) != 0 : false; }

  static final byte[] charMap     = new byte[128];
  static final boolean[] nameMap  = new boolean[128];
  static final byte[] delimEscMap = new byte[128];
  static final int SCHEME     = 0x01;
  static final int USER       = 0x02;
  static final int HOST       = 0x04;
  static final int PATH       = 0x08;
  static final int QUERY      = 0x10;
  static final int FRAG       = 0x20;
  static final int DIGIT      = 0x40;
  static final int HEX        = 0x80;
  static
  {
    // alpha/digits characters
    byte unreserved = SCHEME | USER | HOST | PATH | QUERY | FRAG;
    for (int i='a'; i<='z'; ++i) { charMap[i] = unreserved; nameMap[i] = true; }
    for (int i='A'; i<='Z'; ++i) { charMap[i] = unreserved; nameMap[i] = true; }
    for (int i='0'; i<='9'; ++i) { charMap[i] = unreserved; nameMap[i] = true; }

    // unreserved symbols
    charMap['-'] = unreserved; nameMap['-'] = true;
    charMap['.'] = unreserved; nameMap['.'] = true;
    charMap['_'] = unreserved; nameMap['_'] = true;
    charMap['~'] = unreserved; nameMap['~'] = true;

    // hex
    for (int i='0'; i<='9'; ++i) charMap[i] |= HEX | DIGIT;
    for (int i='a'; i<='f'; ++i) charMap[i] |= HEX;
    for (int i='A'; i<='F'; ++i) charMap[i] |= HEX;

    // sub-delimiter symbols
    charMap['!']  = USER | HOST | PATH | QUERY | FRAG;
    charMap['$']  = USER | HOST | PATH | QUERY | FRAG;
    charMap['&']  = USER | HOST | PATH | QUERY | FRAG;
    charMap['\''] = USER | HOST | PATH | QUERY | FRAG;
    charMap['(']  = USER | HOST | PATH | QUERY | FRAG;
    charMap[')']  = USER | HOST | PATH | QUERY | FRAG;
    charMap['*']  = USER | HOST | PATH | QUERY | FRAG;
    charMap['+']  = SCHEME | USER | HOST | PATH | FRAG;
    charMap[',']  = USER | HOST | PATH | QUERY | FRAG;
    charMap[';']  = USER | HOST | PATH | QUERY | FRAG;
    charMap['=']  = USER | HOST | PATH | QUERY | FRAG;

    // gen-delimiter symbols
    charMap[':'] = PATH | USER | QUERY | FRAG;
    charMap['/'] = PATH | QUERY | FRAG;
    charMap['?'] = QUERY | FRAG;
    charMap['#'] = 0;
    charMap['['] = 0;
    charMap[']'] = 0;
    charMap['@'] = PATH | QUERY | FRAG;

    // delimiter escape map - which characters need to
    // be backslashed escaped in each section
    delimEscMap[':']  = PATH;
    delimEscMap['/']  = PATH;
    delimEscMap['?']  = PATH;
    delimEscMap['#']  = PATH | QUERY;
    delimEscMap['&']  = QUERY;
    delimEscMap[';']  = QUERY;
    delimEscMap['=']  = QUERY;
    delimEscMap['\\'] = SCHEME | USER | HOST | PATH | QUERY | FRAG;
  }

//////////////////////////////////////////////////////////////////////////
// Empty Path/Query
//////////////////////////////////////////////////////////////////////////

  static List emptyPath() { return Sys.StrType.emptyList(); }

  static Map emptyQuery() { return Sys.emptyStrStrMap; }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  static final Range parentRange = Range.make(0L, -2L, false);

  public static final Uri defVal = fromStr("");

  final String str;
  final String scheme;
  final String userInfo;
  final String host;
  final Long port;
  final List path;
  final String pathStr;
  final Map query;
  final String queryStr;
  final String frag;
  String encoded;

}