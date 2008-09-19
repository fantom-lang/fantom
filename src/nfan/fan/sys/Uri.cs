//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   19 Oct 06  Andy Frank  Creation
//   21 Aug 07  Brian        Rewrite with our own parser/encoder
//

using System;
using System.Collections;
using System.Text;
using Fanx.Util;
using Fanx.Serial;

namespace Fan.Sys
{
  /// <summary>
  /// Uri is used to immutably represent a Universal Resource Identifier.
  /// </summary>
  public sealed class Uri : FanObj, Literal
  {

  //////////////////////////////////////////////////////////////////////////
  // Construction
  //////////////////////////////////////////////////////////////////////////

    public static Uri fromStr(string s) { return fromStr(Str.make(s), Bool.True); }
    public static Uri fromStr(Str s) { return fromStr(s, Bool.True); }
    public static Uri fromStr(Str s, Bool check)
    {
      try
      {
        return new Uri(new Decoder(s.val, false).decode());
      }
      catch (ParseErr.Val e)
      {
        if (!check.val) return null;
        throw ParseErr.make("Uri",  s, e.m_err.message()).val;
      }
      catch (Exception)
      {
        if (!check.val) return null;
        throw ParseErr.make("Uri",  s).val;
      }
    }

    public static Uri decode(String s) { return decode(Str.make(s), Bool.True); }
    public static Uri decode(Str s) { return decode(s, Bool.True); }
    public static Uri decode(Str s, Bool check)
    {
      try
      {
        return new Uri(new Decoder(s.val, true).decode());
      }
      catch (ParseErr.Val e)
      {
        if (!check.val) return null;
        throw ParseErr.make("Uri",  s, e.m_err.message()).val;
      }
      catch (Exception)
      {
        if (!check.val) return null;
        throw ParseErr.make("Uri",  s).val;
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // Utils
  //////////////////////////////////////////////////////////////////////////

    public static Map decodeQuery(Str s)
    {
      try
      {
        return new Decoder(s.val, true).decodeQuery();
      }
      catch (ArgErr.Val e)
      {
        throw ArgErr.make("Invalid Uri query: `" + s + "`: " + e.m_err.message()).val;
      }
      catch (Exception)
      {
        throw ArgErr.make("Invalid Uri query: `" + s + "`").val;
      }
    }

    public static Str encodeQuery(Map map)
    {
      StringBuilder buf = new StringBuilder(256);

      IEnumerator en = map.keysEnumerator();
      while (en.MoveNext())
      {
        Str key = (Str)en.Current;
        Str val = (Str)map.get(key);
        if (buf.Length > 0) buf.Append('&');
        encodeQueryStr(buf, key.val);
        if (val != null)
        {
          buf.Append('=');
          encodeQueryStr(buf, val.val);
        }
      }
      return Str.make(buf.ToString());
    }

    static void encodeQueryStr(StringBuilder buf, String str)
    {
      for (int i=0; i<str.Length; ++i)
      {
        int c = str[i];
        if (c < 128 && (charMap[c] & QUERY) != 0 && (delimEscMap[c] & QUERY) == 0)
          buf.Append((char)c);
        else
          percentEncodeChar(buf, c);
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // Java Constructors
  //////////////////////////////////////////////////////////////////////////

    private Uri(Sections x)
    {
      m_scheme   = x.scheme;
      m_userInfo = x.userInfo;
      m_host     = x.host;
      m_port     = x.port;
      m_pathStr  = x.pathStr;
      m_path     = x.path.ro();
      m_queryStr = x.queryStr;
      m_query    = x.query.ro();
      m_frag     = x.frag;
      m_str      = x.str != null ? x.str : new Encoder(this, false).encode();
    }

  //////////////////////////////////////////////////////////////////////////
  // Sections
  //////////////////////////////////////////////////////////////////////////

    class Sections
    {
      internal void setAuth(Uri x)  { userInfo = x.m_userInfo; host = x.m_host; port = x.m_port; }
      internal void setPath(Uri x)  { pathStr = x.m_pathStr; path = x.m_path; }
      internal void setQuery(Uri x) { queryStr = x.m_queryStr; query = x.m_query; }
      internal void setFrag(Uri x)  { frag = x.m_frag; }

      internal void normalize()
      {
        normalizeHttp();
        normalizePath();
        normalizeQuery();
      }

      private void normalizeHttp()
      {
        if (scheme == null || scheme.val != "http")
          return;

        // port 80 -> null
        if (port != null && port.val == 80) port = null;

        // if path is "" -> "/"
        if (pathStr == null || pathStr.val.Length == 0)
        {
          pathStr = Str.m_ascii['/'];
          if (path == null) path = emptyPath();
        }
      }

      private void normalizePath()
      {
        if (path == null) return;

        bool isAbs = pathStr.val.StartsWith("/");
        bool isDir = pathStr.val.EndsWith("/");
        bool dotLast = false;
        bool modified = false;
        for (int i=0; i<path.sz(); ++i)
        {
          Str seg = (Str)path.get(i);
          if (seg.val == "." && (path.sz() > 1 || host != null))
          {
            path.removeAt(Int.make(i));
            modified = true;
            dotLast = true;
            i -= 1;
          }
          else if (seg.val == ".." && i > 0 && path.get(i-1).ToString() != "..")
          {
            path.removeAt(Int.make(i));
            path.removeAt(Int.make(i-1));
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
          if (path.sz() == 0 || path.last().ToString() == "..") isDir = false;
          pathStr = toPathStr(isAbs, path, isDir);
        }
      }

      private void normalizeQuery()
      {
        if (query == null)
          query = emptyQuery();
      }

      internal Str scheme;
      internal Str host;
      internal Str userInfo;
      internal Int port;
      internal Str pathStr;
      internal List path;
      internal Str queryStr;
      internal Map query;
      internal Str frag;
      internal Str str;
    }

  //////////////////////////////////////////////////////////////////////////
  // Decoder
  //////////////////////////////////////////////////////////////////////////

    class Decoder : Sections
    {
      internal Decoder(string str, bool decoding)
      {
        this.str = str;
        this.decoding = decoding;
      }

      internal Decoder decode()
      {
        string str = this.str;
        int len = str.Length;
        int pos = 0;

        // ==== scheme ====

        // scan the string from the beginning looking for either a
        // colon or any character which doesn't fit a valid scheme
        bool hasUpper = false;
        for (int i=0; i<len; ++i)
        {
          int c = str[i];
          if (isScheme(c)) { hasUpper |= isUpper(c); continue; }
          if (c != ':') break;

          // at this point we have a scheme; if we detected
          // any upper case characters normalize to lowercase
          pos = i + 1;
          String scheme = str.Substring(0, i);
          if (hasUpper) scheme = Str.lower(scheme);
          this.scheme = Str.make(scheme);
        }

        // ==== authority ====

        // authority must start with //
        if (pos+1 < len && str[pos] == '/' && str[pos+1] == '/')
        {
          // find end of authority which is /, ?, #, or end of string;
          // while we're scanning look for @ and last colon which isn't
          // inside an [] IPv6 literal
          int authStart = pos+2, authEnd = len, at = -1, colon = -1;
          for (int i=authStart; i<len; ++i)
          {
            int c = str[i];
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
            this.userInfo = substr(authStart, at, USER);
            hostStart = at+1;
          }

          // if we found an colon, parse out port
          if (colon > 0)
          {
            this.port = Int.make(Convert.ToInt64(str.Substring(colon+1, authEnd-colon-1)));
            hostEnd = colon;
          }

          // host is everything left in the authority
          this.host = substr(hostStart, hostEnd, HOST);
          pos = authEnd;
        }

        // ==== path ====

        // scan the string looking '?' or '#' which ends the path
        // section; while we're scanning count the number of slashes
        int pathStart = pos, pathEnd = len, numSegs = 1, prev = 0;
        for (int i=pathStart; i<len; ++i)
        {
          int c = str[i];
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
        this.pathStr = substr(pathStart, pathEnd, PATH);
        this.path = pathSegments(pathStr.val, numSegs);
        pos = pathEnd;

        // ==== query ====

        if (pos < len && str[pos] == '?')
        {
          // look for end of query which is # or end of string
          int queryStart = pos+1, queryEnd = len;
          prev = 0;
          for (int i=queryStart; i<len; ++i)
          {
            int c = str[i];
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
          this.queryStr = substr(queryStart, queryEnd, QUERY);
          this.query = parseQuery(queryStr.val);
          pos = queryEnd;
        }

        // ==== frag ====

        if (pos < len  && str[pos] == '#')
        {
          this.frag = substr(pos+1, len, FRAG);
        }

        // === normalize ===
        normalize();
        return this;
      }

      private List pathSegments(String pathStr, int numSegs)
      {
        // if pathStr is "/" then path si the empty list
        int len = pathStr.Length;
        if (len == 0 || (len == 1 && pathStr[0] == '/'))
          return emptyPath();

        // check for trailing slash
        if (len > 1 && pathStr[len-1] == '/')
        {
          numSegs--;
          len--;
        }

        // parse the segments
        Str[] path = new Str[numSegs];
        int n = 0;
        int segStart = 0, prev = 0;
        for (int i=0; i<pathStr.Length; ++i)
        {
          int c = pathStr[i];
          if (prev != '\\')
          {
            if (c == '/')
            {
              if (i > 0) path[n++] = Str.make(pathStr.Substring(segStart, i-segStart));
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
          path[n++] = Str.make(pathStr.Substring(segStart, pathStr.Length-segStart));

        return new List(Sys.StrType, path);
      }

      internal Map decodeQuery()
      {
        return parseQuery(substring(0, str.Length, QUERY));
      }

      private Map parseQuery(String q)
      {
        if (q == null) return null;
        Map map = new Map(Sys.StrType, Sys.StrType);

        try
        {
          int start = 0, eq = 0, len = q.Length, prev = 0;
          bool escaped = false;
          for (int i=0; i<len; ++i)
          {
            int ch = q[i];
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
          Err.dumpStack(e);
        }

        return map;
      }

      private void addQueryParam(Map map, String q, int start, int eq, int end, bool escaped)
      {
        if (start == eq)
          map.set(toQueryStr(q, start, end, escaped), Bool.True.toStr());
        else
          map.set(toQueryStr(q, start, eq, escaped), toQueryStr(q, eq+1, end, escaped));
      }

      private Str toQueryStr(String q, int start, int end, bool escaped)
      {
        if (!escaped) return Str.make(q.Substring(start, end-start));
        StringBuilder s = new StringBuilder(end-start);
        int prev = 0;
        for (int i=start; i<end; ++i)
        {
          int c = q[i];
          if (c != '\\')
          {
            s.Append((char)c);
            prev = c;
          }
          else
          {
            if (prev == '\\') { s.Append((char)c); prev = 0; }
            else prev = c;
          }
        }
        return Str.make(s.ToString());
      }

      private Str substr(int start, int end, int section)
      {
        return Str.make(substring(start, end, section));
      }

      private String substring(int start, int end, int section)
      {
        if (!decoding) return str.Substring(start, end-start);

        StringBuilder buf = new StringBuilder(end-start);
        dpos = start;
        while (dpos < end)
        {
           int ch = nextChar(section);
           if (nextCharWasEscaped && ch < delimEscMap.Length && (delimEscMap[ch] & section) != 0)
             buf.Append('\\');
           buf.Append((char)ch);
        }
        return buf.ToString();
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
        int c = str[dpos++];

        // if percent encoded applied to all sections except
        // scheme which should never never use this method
        if (c == '%')
        {
          nextCharWasEscaped = true;
          return (hexNibble(str[dpos++]) << 4) | hexNibble(str[dpos++]);
        }
        else
        {
          nextCharWasEscaped = false;
        }

        // + maps to space only in query
        if (c == '+' && section == QUERY)
          return ' ';

        // verify character ok
        if (c >= charMap.Length || (charMap[c] & section) == 0)
          throw err("Invalid char in " + toSection(section) + " at index " + (dpos-1));

        // return character as is
        return c;
      }

      new string str;
      bool decoding;
      int dpos;
      bool nextCharWasEscaped;
   }

  //////////////////////////////////////////////////////////////////////////
  // Encoder
  //////////////////////////////////////////////////////////////////////////

    class Encoder
    {
      internal Encoder(Uri uri, bool encoding)
      {
        this.uri = uri;
        this.encoding = encoding;
        this.buf = new StringBuilder();
      }

      internal Str encode()
      {
        //Uri uri = this.uri;
        //StringBuilder buf = this.buf;

        // scheme
        if (uri.m_scheme != null) buf.Append(uri.m_scheme.val).Append(':');

        // authority
        if (uri.m_userInfo != null || uri.m_host != null || uri.m_port != null)
        {
          buf.Append('/').Append('/');
          if (uri.m_userInfo != null) encode(uri.m_userInfo, USER).Append('@');
          if (uri.m_host != null) encode(uri.m_host, HOST);
          if (uri.m_port != null) buf.Append(':').Append(uri.m_port.val);
        }

        // path
        if (uri.m_pathStr != null)
          encode(uri.m_pathStr, PATH);

        // query
        if (uri.m_queryStr != null)
          { buf.Append('?'); encode(uri.m_queryStr, QUERY); }

        // frag
        if (uri.m_frag != null)
          { buf.Append('#'); encode(uri.m_frag, FRAG); }

        return Str.make(buf.ToString());
      }

      internal StringBuilder encode(Str str, int section)
      {
        if (!encoding) return buf.Append(str.val);

        //StringBuilder buf = this.buf;
        String s = str.val;
        int len = s.Length;
        int c = 0, prev;
        for (int i=0; i<len; ++i)
        {
          prev = c;
          c = s[i];

          // unreserved character
          if (c < 128 && (charMap[c] & section) != 0 && prev != '\\')
          {
            buf.Append((char)c);
            continue;
          }

          // the backslash esc itself doesn't get encoded
          if (c == '\\' && prev != '\\') continue;

          // we have a reserved, escaped, or non-ASCII

          // encode
          if (c == ' ' && section == QUERY)
            buf.Append('+');
          else
            percentEncodeChar(buf, c);

          // if we just encoded backslash, then it
          // doesn't escape the next char
          if (c == '\\') c = 0;
        }
        return buf;
      }

      Uri uri;
      bool encoding;
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
      buf.Append('%');
      int hi = (c >> 4) & 0xf;
      int lo = c & 0xf;
      buf.Append((char)(hi < 10 ? '0'+hi : 'A'+(hi-10)));
      buf.Append((char)(lo < 10 ? '0'+lo : 'A'+(lo-10)));
    }

  //////////////////////////////////////////////////////////////////////////
  // Identity
  //////////////////////////////////////////////////////////////////////////

    public override Bool equals(Obj obj)
    {
      if (obj is Uri)
      {
        return m_str.equals(((Uri)obj).m_str);
      }
      return Bool.False;
    }

    public override int GetHashCode()
    {
      return m_str.GetHashCode();
    }

    public override Int hash()
    {
      return m_str.hash();
    }

    public override Str toStr()
    {
      return m_str;
    }

    public void encode(ObjEncoder @out)
    {
      @out.wStrLiteral(m_str.val, '`');
    }

    public override Type type()
    {
      return Sys.UriType;
    }

    public Str encode()
    {
      Str x = m_encoded;
      if (x != null) return x;
      return m_encoded = new Encoder(this, true).encode();
    }

  //////////////////////////////////////////////////////////////////////////
  // Components
  //////////////////////////////////////////////////////////////////////////

    public Bool isAbs()
    {
      return m_scheme != null ? Bool.True : Bool.False;
    }

    public Bool isRel()
    {
      return m_scheme == null ? Bool.True : Bool.False;
    }

    public Bool isDir()
    {
      if (m_pathStr != null)
      {
        string p = m_pathStr.val;
        int len = p.Length;
        if (len > 0 && p[len-1] == '/')
          return Bool.True;
      }
      return Bool.False;
    }

    public Str scheme()
    {
      return m_scheme;
    }

    public Str auth()
    {
      if (m_host == null) return null;
      if (m_port == null)
      {
        if (m_userInfo == null) return m_host;
        else return Str.make(m_userInfo.val + '@' + m_host.val);
      }
      else
      {
        if (m_userInfo == null) return Str.make(m_host.val + ':' + m_port);
        else return Str.make(m_userInfo.val + '@' + m_host.val + ':' + m_port);
      }
    }

    public Str host()
    {
      return m_host;
    }

    public Str userInfo()
    {
      return m_userInfo;
    }

    public Int port()
    {
      return m_port;
    }

    public string path(int depth) { return ((Str)m_path.get(depth)).val; }
    public List path()
    {
      return m_path;
    }

    public Str pathStr()
    {
      return m_pathStr;
    }

    public Bool isPathAbs()
    {
      if (m_pathStr == null || m_pathStr.val.Length == 0)
        return Bool.False;
      else
        return m_pathStr.val[0] == '/' ? Bool.True : Bool.False;
    }

    public Bool isPathOnly()
    {
      return Bool.make(m_scheme == null && m_host == null && m_port == null &&
        m_userInfo == null && m_queryStr == null && m_frag == null);
    }

    public Str name()
    {
      if (m_path.sz() == 0) return Str.Empty;
      return (Str)m_path.last();
    }

    public Str basename()
    {
      Str name = this.name();
      string n = name.val;
      int dot = n.LastIndexOf('.');
      if (dot < 2)
      {
        if (dot < 0) return name;
        if (n == ".") return name;
        if (n == "..") return name;
      }
      return Str.make(n.Substring(0, dot));
    }

    public Str ext()
    {
      Str name = this.name();
      String n = name.val;
      int dot = n.LastIndexOf('.');
      if (dot < 2)
      {
        if (dot < 0) return null;
        if (n == ".") return null;
        if (n == "..") return null;
      }
      return Str.make(n.Substring(dot+1));
    }

    public MimeType mimeType()
    {
      if (isDir().val) return MimeType.m_dir;
      return MimeType.forExt(ext());
    }

    public Map query()
    {
      return m_query;
    }

    public Str queryStr()
    {
      return m_queryStr;
    }

    public Str frag()
    {
      return m_frag;
    }

  //////////////////////////////////////////////////////////////////////////
  // Utils
  //////////////////////////////////////////////////////////////////////////

    public Uri parent()
    {
      // if no path bail
      if (m_path.sz() == 0) return null;

      // if just a simple filename, then no parent
      string p = m_pathStr.val;
      if (m_path.sz() == 1 && !isPathAbs().val && !isDir().val) return null;

      // use slice
      return slice(parentRange);
    }

    public Uri pathOnly()
    {
      if (m_pathStr == null)
        throw Err.make("Uri has no path: " + this).val;

      if (m_scheme == null && m_userInfo == null && m_host == null &&
          m_port == null && m_queryStr == null && m_frag == null)
        return this;

      Sections t = new Sections();
      t.path     = this.m_path;
      t.pathStr  = this.m_pathStr;
      t.query    = emptyQuery();
      t.str      = this.m_pathStr;
      return new Uri(t);
    }

    public Uri slice(Range range) { return slice(range, false); }

    public Uri sliceToPathAbs(Range range) { return slice(range, true); }

    private Uri slice(Range range, bool forcePathAbs)
    {
      if (m_pathStr == null)
        throw Err.make("Uri has no path: " + this).val;

      int size = m_path.sz();
      int s = range.start(size);
      int e = range.end(size);
      int n = e - s + 1;
      if (n < 0) throw IndexErr.make(range).val;

      bool head = (s == 0);
      bool tail = (e == size-1);
      if (head && tail && (!forcePathAbs || isPathAbs().val)) return this;

      Sections t = new Sections();
      t.path = m_path.slice(range);

      StringBuilder sb = new StringBuilder(m_pathStr.val.Length);
      if ((head && isPathAbs().val) || forcePathAbs) sb.Append('/');
      for (int i=0; i<t.path.sz(); ++i)
      {
        if (i > 0) sb.Append('/');
        sb.Append(t.path.get(i));
      }
      if (t.path.sz() > 0 && (!tail || isDir().val)) sb.Append('/');
      t.pathStr = Str.make(sb.ToString());

      if (head)
      {
        t.scheme   = m_scheme;
        t.userInfo = m_userInfo;
        t.host     = m_host;
        t.port     = m_port;
      }

      if (tail)
      {
        t.queryStr = m_queryStr;
        t.query    = m_query;
        t.frag     = m_frag;
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

    public Uri relTo(Uri baseUri)
    {
      if (!OpUtil.compareEQz(this.m_scheme,   baseUri.m_scheme) ||
          !OpUtil.compareEQz(this.m_userInfo, baseUri.m_userInfo) ||
          !OpUtil.compareEQz(this.m_host,     baseUri.m_host) ||
          !OpUtil.compareEQz(this.m_port,     baseUri.m_port))
        return this;

      // at this point we know we have the same scheme and auth, and
      // we're going to create a new URI which is a subset of this one
      Sections t = new Sections();
      t.query    = this.m_query;
      t.queryStr = this.m_queryStr;
      t.frag     = this.m_frag;

      // find divergence
      int d=0;
      int len = Math.Min(this.m_path.sz(), baseUri.m_path.sz());
      for (; d<len; ++d)
        if (!this.m_path.get(d).equals(baseUri.m_path.get(d)).val)
          break;

      // if diverenge is at root, then no commonality
      if (d == 0)
      {
        t.path = this.m_path;
        t.pathStr = this.m_pathStr;
      }

      // if paths are exactly the same
      else if (d == this.m_path.sz() && d == baseUri.m_path.sz())
      {
        t.path = emptyPath();
        t.pathStr = Str.Empty;
      }

      // create sub-path at divergence point
      else
      {
        // slice my path
        t.path = this.m_path.slice(Range.makeInclusive(Int.make(d), Int.NegOne));

        // insert .. backup if needed
        int backup = baseUri.m_path.sz() - d;
        if (!baseUri.isDir().val) backup--;
        while (backup-- > 0) t.path.insert(Int.Zero, dotDot);

        // format the new path string
        t.pathStr = toPathStr(false, t.path, this.isDir().val);
      }

      return new Uri(t);
    }

    public Uri relToAuth()
    {
      if (m_scheme == null && m_userInfo == null &&
          m_host == null && m_port == null)
        return this;

      Sections t = new Sections();
      t.path     = this.m_path;
      t.pathStr  = this.m_pathStr;
      t.query    = this.m_query;
      t.queryStr = this.m_queryStr;
      t.frag     = this.m_frag;
      return new Uri(t);
    }

  //////////////////////////////////////////////////////////////////////////
  // Plus
  //////////////////////////////////////////////////////////////////////////

    public Uri plus(Uri r)
    {
      // if r is more or equal as absolute as base, return r
      if (r.m_scheme != null) return r;
      if (r.m_host != null && this.m_scheme == null) return r;
      if (r.isPathAbs().val && this.m_host == null) return r;

      // this algorthm is lifted straight from
      // RFC 3986 (5.2.2) Transform References;
      Uri baseUri = this;
      Sections t = new Sections();
      if (r.m_host != null)
      {
        t.setAuth(r);
        t.setPath(r);
        t.setQuery(r);
      }
      else
      {
        if (r.m_pathStr == null || r.m_pathStr.val == "")
        {
          t.setPath(baseUri);
          if (r.m_queryStr != null)
            t.setQuery(r);
          else
            t.setQuery(baseUri);
        }
        else
        {
          if (r.m_pathStr.val.StartsWith("/"))
            t.setPath(r);
          else
            merge(t, baseUri, r);
          t.setQuery(r);
        }
        t.setAuth(baseUri);
      }
      t.scheme = baseUri.m_scheme;
      t.frag   = r.m_frag;
      t.normalize();
      return new Uri(t);
    }

    static void merge(Sections t, Uri baseUri, Uri r)
    {
      bool baseIsAbs = baseUri.isPathAbs().val;
      bool baseIsDir = baseUri.isDir().val;
      bool rIsDir    = r.isDir().val;
      List rPath     = r.m_path;
      bool dotLast   = false;

      // compute the target path taking into account whether
      // the base is a dir and any dot segments in relative ref
      List tPath;
      if (baseUri.m_path.sz() == 0)
      {
        tPath = r.m_path;
      }
      else
      {
        tPath = baseUri.m_path.rw();
        if (!baseIsDir) tPath.pop();
        for (int i=0; i<rPath.sz(); ++i)
        {
          Str rSeg = (Str)rPath.get(i);
          if (rSeg.val == ".") { dotLast = true; continue; }
          if (rSeg.val == "..")
          {
            if (!tPath.isEmpty().val) { tPath.pop(); dotLast = true; continue; }
            if (baseIsAbs) continue;
          }
          tPath.add(rSeg); dotLast = false;
        }
        //tPath = tPath;
      }

      t.path = tPath;
      t.pathStr = toPathStr(baseIsAbs, tPath, rIsDir || dotLast);
    }

    static Str toPathStr(bool isAbs, List path, bool isDir)
    {
      StringBuilder buf = new StringBuilder();
      if (isAbs) buf.Append('/');
      for (int i=0; i<path.sz(); ++i)
      {
        if (i > 0) buf.Append('/');
        buf.Append(path.get(i));
      }
      if (isDir && !(buf.Length > 0 && buf[buf.Length-1] == '/'))
        buf.Append('/');
      return Str.make(buf.ToString());
    }

    public Uri plusName(String name, bool isDir) { return plusName(Str.make(name), Bool.make(isDir)); }
    public Uri plusName(Str name) { return plusName(name, Bool.False); }
    public Uri plusName(Str name, Bool asDir)
    {
      int size         = m_path.sz();
      bool isDir       = this.isDir().val;
      int newSize      = isDir ? size + 1 : size;
      Str[] temp       = (Str[])m_path.toArray(new Str[newSize]);
      temp[newSize-1]  = name;

      Sections t = new Sections();
      t.scheme   = this.m_scheme;
      t.userInfo = this.m_userInfo;
      t.host     = this.m_host;
      t.port     = this.m_port;
      t.query    = emptyQuery();
      t.queryStr = null;
      t.frag     = null;
      t.path     = new List(Sys.StrType, temp);
      t.pathStr  = toPathStr(isPathAbs().val, t.path, asDir.val);
      return new Uri(t);
    }

    public Uri plusSlash()
    {
      if (isDir().val) return this;
      Sections t = new Sections();
      t.scheme   = this.m_scheme;
      t.userInfo = this.m_userInfo;
      t.host     = this.m_host;
      t.port     = this.m_port;
      t.query    = this.m_query;
      t.queryStr = this.m_queryStr;
      t.frag     = this.m_frag;
      t.path     = this.m_path;
      t.pathStr  = Str.make(this.m_pathStr.val + "/");
      return new Uri(t);
    }

    public Uri plusQuery(Map q)
    {
      if (q == null || q.isEmpty().val) return this;

      Map merge = m_query.dup().setAll(q);

      StringBuilder s = new StringBuilder(256);
      IDictionaryEnumerator en = merge.pairsIterator();
      while (en.MoveNext())
      {
        if (s.Length > 0) s.Append('&');
        String key = ((Str)en.Key).val;
        String val = ((Str)en.Value).val;
        appendQueryStr(s, key);
        s.Append('=');
        appendQueryStr(s, val);
      }

      Sections t = new Sections();
      t.scheme   = m_scheme;
      t.userInfo = m_userInfo;
      t.host     = m_host;
      t.port     = m_port;
      t.frag     = m_frag;
      t.pathStr  = m_pathStr;
      t.path     = m_path;
      t.query    = merge.ro();
      t.queryStr = Str.make(s.ToString());
      return new Uri(t);
    }

    static void appendQueryStr(StringBuilder buf, String str)
    {
      for (int i=0; i<str.Length; ++i)
      {
        int c = str[i];
        if (c < delimEscMap.Length && (delimEscMap[c] & QUERY) != 0)
          buf.Append('\\');
        buf.Append((char)c);
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // Resolution
  //////////////////////////////////////////////////////////////////////////

    public File toFile()
    {
      return File.make(this);
    }

    public Obj get() { return get(null, Bool.True); }
    public Obj get(Obj @base) { return get(@base, Bool.True); }
    public Obj get(Obj @base, Bool check)
    {
      // if we have a relative uri, we need to resolve against
      // the base object's uri
      Uri uri = this;
      if (m_scheme == null)
      {
        if (@base == null) throw UnresolvedErr.make("Relative uri with no base: " + this).val;
        Uri baseUri = null;
        try
        {
          baseUri = (Uri)@base.trap(Str.uriStr, null);
          if (baseUri == null)
            throw UnresolvedErr.make("Base object's uri is null: " + this).val;
        }
        catch (System.Exception e)
        {
          throw UnresolvedErr.make("Cannot access base '" + @base.type() + ".uri' to normalize: " + this, e).val;
        }
        if (baseUri.m_scheme == null)
          throw UnresolvedErr.make("Base object's uri is not absolute: " + baseUri).val;
        uri = baseUri.plus(this);
      }

      // resolve scheme handler
      UriScheme scheme = UriScheme.find(uri.m_scheme);

      // route to scheme
      try
      {
        return scheme.get(uri, @base);
      }
      catch (UnresolvedErr.Val e)
      {
        if (check.val) throw e;
        return null;
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // Utils
  //////////////////////////////////////////////////////////////////////////

    public static Bool isName(Str name)
    {
      string n = name.val;
      int len = n.Length;

      // must be at least one character long
      if (len == 0) return Bool.False;

      // check for "." and ".."
      if (n[0] == '.' && len <= 2)
      {
        if (len == 1) return Bool.False;
        if (n[1] == '.') return Bool.False;
      }

      // check that each char is unreserved
      for (int i=0; i<len; ++i)
      {
        int c = n[i];
        if (c < 128 && nameMap[c]) continue;
        return Bool.False;
      }

      return Bool.True;
    }

    public static void checkName(Str name)
    {
      if (!isName(name).val)
        throw NameErr.make(name).val;
    }

    static bool isUpper(int c)
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

    static Exception err(String msg)
    {
      return ParseErr.make(msg).val;
    }

  //////////////////////////////////////////////////////////////////////////
  // Character Map
  //////////////////////////////////////////////////////////////////////////

    static string toSection(int section)
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

    static bool isScheme(int c) { return c < 128 ? (charMap[c] & SCHEME) != 0 : false; }

    static readonly byte[] charMap = new byte[128];
    static readonly bool[] nameMap = new bool[128];
    static readonly byte[] delimEscMap = new byte[128];
    const byte SCHEME     = 0x01;
    const byte USER       = 0x02;
    const byte HOST       = 0x04;
    const byte PATH       = 0x08;
    const byte QUERY      = 0x10;
    const byte FRAG       = 0x20;
    const byte DIGIT      = 0x40;
    const byte HEX        = 0x80;
    static Uri()
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

    static List emptyPath()
    {
      List p = m_emptyPath;
      if (p == null) p = m_emptyPath = new List(Sys.StrType).toImmutable();
      return p;
    }
    static List m_emptyPath;

    static Map emptyQuery()
    {
      Map q = m_emptyQuery;
      if (q == null) q = m_emptyQuery = new Map(Sys.StrType, Sys.StrType).toImmutable();
      return q;
    }
    static Map m_emptyQuery;

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    static readonly Range parentRange = Range.make(Int.Zero, Int.NegTwo, Bool.False);
    static readonly Str dotDot = Str.make("..");

    internal readonly Str m_str;
    internal readonly Str m_scheme;
    internal readonly Str m_userInfo;
    internal readonly Str m_host;
    internal readonly Int m_port;
    internal readonly List m_path;
    internal readonly Str m_pathStr;
    internal readonly Map m_query;
    internal readonly Str m_queryStr;
    internal readonly Str m_frag;
    internal Str m_encoded;

  }
}
