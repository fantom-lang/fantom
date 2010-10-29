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

    public static Uri fromStr(string s) { return fromStr(s, true); }
    public static Uri fromStr(string s, bool check)
    {
      try
      {
        return new Uri(new Decoder(s, false).decode());
      }
      catch (ParseErr.Val e)
      {
        if (!check) return null;
        throw ParseErr.make("Uri",  s, e.m_err.msg()).val;
      }
      catch (Exception)
      {
        if (!check) return null;
        throw ParseErr.make("Uri",  s).val;
      }
    }

    public static Uri decode(string s) { return decode(s, true); }
    public static Uri decode(string s, bool check)
    {
      try
      {
        return new Uri(new Decoder(s, true).decode());
      }
      catch (ParseErr.Val e)
      {
        if (!check) return null;
        throw ParseErr.make("Uri",  s, e.m_err.msg()).val;
      }
      catch (Exception)
      {
        if (!check) return null;
        throw ParseErr.make("Uri",  s).val;
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // Utils
  //////////////////////////////////////////////////////////////////////////

    public static Map decodeQuery(string s)
    {
      try
      {
        return new Decoder(s, true).decodeQuery();
      }
      catch (ArgErr.Val e)
      {
        throw ArgErr.make("Invalid Uri query: `" + s + "`: " + e.m_err.msg()).val;
      }
      catch (Exception)
      {
        throw ArgErr.make("Invalid Uri query: `" + s + "`").val;
      }
    }

    public static string encodeQuery(Map map)
    {
      StringBuilder buf = new StringBuilder(256);

      IEnumerator en = map.keysEnumerator();
      while (en.MoveNext())
      {
        string key = (string)en.Current;
        string val = (string)map.get(key);
        if (buf.Length > 0) buf.Append('&');
        encodeQueryStr(buf, key);
        if (val != null)
        {
          buf.Append('=');
          encodeQueryStr(buf, val);
        }
      }
      return buf.ToString();
    }

    static void encodeQueryStr(StringBuilder buf, string str)
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
        if (scheme == null || scheme != "http")
          return;

        // port 80 -> null
        if (port != null && port.longValue() == 80) port = null;

        // if path is "" -> "/"
        if (pathStr == null || pathStr.Length == 0)
        {
          pathStr = FanStr.m_ascii['/'];
          if (path == null) path = emptyPath();
        }
      }

      private void normalizePath()
      {
        if (path == null) return;

        bool isAbs = pathStr.StartsWith("/");
        bool isDir = pathStr.EndsWith("/");
        bool dotLast = false;
        bool modified = false;
        for (int i=0; i<path.sz(); ++i)
        {
          string seg = (string)path.get(i);
          if (seg == "." && (path.sz() > 1 || host != null))
          {
            path.removeAt(i);
            modified = true;
            dotLast = true;
            i -= 1;
          }
          else if (seg == ".." && i > 0 && path.get(i-1).ToString() != "..")
          {
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
          if (path.sz() == 0 || path.last().ToString() == "..") isDir = false;
          pathStr = toPathStr(isAbs, path, isDir);
        }
      }

      private void normalizeQuery()
      {
        if (query == null)
          query = emptyQuery();
      }

      internal string scheme;
      internal string host;
      internal string userInfo;
      internal Long port;
      internal string pathStr;
      internal List path;
      internal string queryStr;
      internal Map query;
      internal string frag;
      internal string str;
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
          string scheme = str.Substring(0, i);
          if (hasUpper) scheme = FanStr.lower(scheme);
          this.scheme = scheme;
          break;
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
            this.port = Long.valueOf(Convert.ToInt64(str.Substring(colon+1, authEnd-colon-1)));
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
        this.path = pathSegments(pathStr, numSegs);
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
          this.query = parseQuery(queryStr);
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

      private List pathSegments(string pathStr, int numSegs)
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
        string[] path = new string[numSegs];
        int n = 0;
        int segStart = 0, prev = 0;
        for (int i=0; i<pathStr.Length; ++i)
        {
          int c = pathStr[i];
          if (prev != '\\')
          {
            if (c == '/')
            {
              if (i > 0) path[n++] = pathStr.Substring(segStart, i-segStart);
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
          path[n++] = pathStr.Substring(segStart, pathStr.Length-segStart);

        return new List(Sys.StrType, path);
      }

      internal Map decodeQuery()
      {
        return parseQuery(substring(0, str.Length, QUERY));
      }

      private Map parseQuery(string q)
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

      private void addQueryParam(Map map, string q, int start, int eq, int end, bool escaped)
      {
        string key, val;
        if (start == eq && q[start] != '=')
        {
          key = toQueryStr(q, start, end, escaped);
          val = "true";
        }
        else
        {
          key = toQueryStr(q, start, eq, escaped);
          val = toQueryStr(q, eq+1, end, escaped);
        }

        string dup = (string)map.get(key);
        if (dup != null) val = dup + "," + val;
        map.set(key, val);
      }

      private string toQueryStr(string q, int start, int end, bool escaped)
      {
        if (!escaped) return q.Substring(start, end-start);
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
        return s.ToString();
      }

      private string substr(int start, int end, int section)
      {
        return substring(start, end, section);
      }

      private string substring(int start, int end, int section)
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

      internal string encode()
      {
        // scheme
        if (uri.m_scheme != null) buf.Append(uri.m_scheme).Append(':');

        // authority
        if (uri.m_userInfo != null || uri.m_host != null || uri.m_port != null)
        {
          buf.Append('/').Append('/');
          if (uri.m_userInfo != null) encode(uri.m_userInfo, USER).Append('@');
          if (uri.m_host != null) encode(uri.m_host, HOST);
          if (uri.m_port != null) buf.Append(':').Append(uri.m_port);
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

        return buf.ToString();
      }

      internal StringBuilder encode(string s, int section)
      {
        if (!encoding) return buf.Append(s);

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

    public override bool Equals(object obj)
    {
      if (obj is Uri)
      {
        return m_str == ((Uri)obj).m_str;
      }
      return false;
    }

    public override int GetHashCode()
    {
      return m_str.GetHashCode();
    }

    public override long hash()
    {
      return FanStr.hash(m_str);
    }

    public override string toStr()
    {
      return m_str;
    }

    public string toLocale()
    {
      return m_str;
    }

    public void encode(ObjEncoder @out)
    {
      @out.wStrLiteral(m_str, '`');
    }

    public override Type @typeof()
    {
      return Sys.UriType;
    }

    public string encode()
    {
      string x = m_encoded;
      if (x != null) return x;
      return m_encoded = new Encoder(this, true).encode();
    }

  //////////////////////////////////////////////////////////////////////////
  // Components
  //////////////////////////////////////////////////////////////////////////

    public bool isAbs()
    {
      return m_scheme != null;
    }

    public bool isRel()
    {
      return m_scheme == null;
    }

    public bool isDir()
    {
      if (m_pathStr != null)
      {
        string p = m_pathStr;
        int len = p.Length;
        if (len > 0 && p[len-1] == '/')
          return true;
      }
      return false;
    }

    public string scheme()
    {
      return m_scheme;
    }

    public string auth()
    {
      if (m_host == null) return null;
      if (m_port == null)
      {
        if (m_userInfo == null) return m_host;
        else return m_userInfo + '@' + m_host;
      }
      else
      {
        if (m_userInfo == null) return m_host + ':' + m_port;
        else return m_userInfo + '@' + m_host + ':' + m_port;
      }
    }

    public string host()
    {
      return m_host;
    }

    public string userInfo()
    {
      return m_userInfo;
    }

    public Long port()
    {
      return m_port;
    }

    public string path(int depth) { return ((string)m_path.get(depth)); }
    public List path()
    {
      return m_path;
    }

    public string pathStr()
    {
      return m_pathStr;
    }

    public bool isPathAbs()
    {
      if (m_pathStr == null || m_pathStr.Length == 0)
        return false;
      else
        return m_pathStr[0] == '/';
    }

    public bool isPathOnly()
    {
      return m_scheme == null && m_host == null && m_port == null &&
        m_userInfo == null && m_queryStr == null && m_frag == null;
    }

    public string name()
    {
      if (m_path.sz() == 0) return string.Empty;
      return (string)m_path.last();
    }

    public string basename()
    {
      string n = this.name();
      int dot = n.LastIndexOf('.');
      if (dot < 2)
      {
        if (dot < 0) return n;
        if (n == ".") return n;
        if (n == "..") return n;
      }
      return n.Substring(0, dot);
    }

    public string ext()
    {
      string n = this.name();
      int dot = n.LastIndexOf('.');
      if (dot < 2)
      {
        if (dot < 0) return null;
        if (n == ".") return null;
        if (n == "..") return null;
      }
      return n.Substring(dot+1);
    }

    public MimeType mimeType()
    {
      if (isDir()) return MimeType.m_dir;
      return MimeType.forExt(ext());
    }

    public Map query()
    {
      return m_query;
    }

    public string queryStr()
    {
      return m_queryStr;
    }

    public string frag()
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
      string p = m_pathStr;
      if (m_path.sz() == 1 && !isPathAbs() && !isDir()) return null;

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
      if (head && tail && (!forcePathAbs || isPathAbs())) return this;

      Sections t = new Sections();
      t.path = m_path.slice(range);

      StringBuilder sb = new StringBuilder(m_pathStr.Length);
      if ((head && isPathAbs()) || forcePathAbs) sb.Append('/');
      for (int i=0; i<t.path.sz(); ++i)
      {
        if (i > 0) sb.Append('/');
        sb.Append(t.path.get(i));
      }
      if (t.path.sz() > 0 && (!tail || isDir())) sb.Append('/');
      t.pathStr = sb.ToString();

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
      if (!OpUtil.compareEQ(this.m_scheme,   baseUri.m_scheme) ||
          !OpUtil.compareEQ(this.m_userInfo, baseUri.m_userInfo) ||
          !OpUtil.compareEQ(this.m_host,     baseUri.m_host) ||
          !OpUtil.compareEQ(this.m_port,     baseUri.m_port))
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
        if (!this.m_path.get(d).Equals(baseUri.m_path.get(d)))
          break;

      // if diverenge is at root, then no commonality
      if (d == 0)
      {
        // `/a/b/c`.relTo(`/`) should be `a/b/c`
        if (baseUri.m_path.isEmpty() && this.m_pathStr.StartsWith("/"))
        {
          t.path = this.m_path;
          t.pathStr = this.m_pathStr.Substring(1);
        }
        else
        {
          t.path = this.m_path;
          t.pathStr = this.m_pathStr;
        }
      }

      // if paths are exactly the same
      else if (d == this.m_path.sz() && d == baseUri.m_path.sz())
      {
        t.path = emptyPath();
        t.pathStr = string.Empty;
      }

      // create sub-path at divergence point
      else
      {
        // slice my path
        t.path = this.m_path.slice(Range.makeInclusive(d, -1));

        // insert .. backup if needed
        int backup = baseUri.m_path.sz() - d;
        if (!baseUri.isDir()) backup--;
        while (backup-- > 0) t.path.insert(0, dotDot);

        // format the new path string
        t.pathStr = toPathStr(false, t.path, this.isDir());
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
      if (r.isPathAbs() && this.m_host == null) return r;

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
        if (r.m_pathStr == null || r.m_pathStr == "")
        {
          t.setPath(baseUri);
          if (r.m_queryStr != null)
            t.setQuery(r);
          else
            t.setQuery(baseUri);
        }
        else
        {
          if (r.m_pathStr.StartsWith("/"))
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
      bool baseIsAbs = baseUri.isPathAbs();
      bool baseIsDir = baseUri.isDir();
      bool rIsDir    = r.isDir();
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
          string rSeg = (string)rPath.get(i);
          if (rSeg == ".") { dotLast = true; continue; }
          if (rSeg == "..")
          {
            if (!tPath.isEmpty()) { tPath.pop(); dotLast = true; continue; }
            if (baseIsAbs) continue;
          }
          tPath.add(rSeg); dotLast = false;
        }
        //tPath = tPath;
      }

      t.path = tPath;
      t.pathStr = toPathStr(baseIsAbs, tPath, rIsDir || dotLast);
    }

    static string toPathStr(bool isAbs, List path, bool isDir)
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
      return buf.ToString();
    }

    public Uri plusName(string name) { return plusName(name, false); }
    public Uri plusName(string name, bool asDir)
    {
      int size        = m_path.sz();
      bool isDir      = this.isDir();
      int newSize     = isDir ? size + 1 : size;
      string[] temp   = (string[])m_path.toArray(new string[newSize]);
      temp[newSize-1] = name;

      Sections t = new Sections();
      t.scheme   = this.m_scheme;
      t.userInfo = this.m_userInfo;
      t.host     = this.m_host;
      t.port     = this.m_port;
      t.query    = emptyQuery();
      t.queryStr = null;
      t.frag     = null;
      t.path     = new List(Sys.StrType, temp);
      t.pathStr  = toPathStr(isPathAbs(), t.path, asDir);
      return new Uri(t);
    }

    public Uri plusSlash()
    {
      if (isDir()) return this;
      Sections t = new Sections();
      t.scheme   = this.m_scheme;
      t.userInfo = this.m_userInfo;
      t.host     = this.m_host;
      t.port     = this.m_port;
      t.query    = this.m_query;
      t.queryStr = this.m_queryStr;
      t.frag     = this.m_frag;
      t.path     = this.m_path;
      t.pathStr  = this.m_pathStr + "/";
      return new Uri(t);
    }

    public Uri plusQuery(Map q)
    {
      if (q == null || q.isEmpty()) return this;

      Map merge = m_query.dup().setAll(q);

      StringBuilder s = new StringBuilder(256);
      IDictionaryEnumerator en = merge.pairsIterator();
      while (en.MoveNext())
      {
        if (s.Length > 0) s.Append('&');
        string key = (string)en.Key;
        string val = (string)en.Value;
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
      t.queryStr = s.ToString();
      return new Uri(t);
    }

    static void appendQueryStr(StringBuilder buf, string str)
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

    public object get() { return get(null, true); }
    public object get(object @base) { return get(@base, true); }
    public object get(object @base, bool check)
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
          baseUri = (Uri)trap(@base, "uri", null);
          if (baseUri == null)
            throw UnresolvedErr.make("Base object's uri is null: " + this).val;
        }
        catch (System.Exception e)
        {
          throw UnresolvedErr.make("Cannot access base '" + FanObj.@typeof(@base) + ".uri' to normalize: " + this, e).val;
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
        if (check) throw e;
        return null;
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // Conversion
  //////////////////////////////////////////////////////////////////////////

    public string toCode()
    {
      StringBuilder s = new StringBuilder(m_str.Length+4);
      s.Append('`');

      int len = m_str.Length;
      for (int i=0; i<len; ++i)
      {
        int c = m_str[i];
        switch (c)
        {
          case '\n': s.Append('\\').Append('n'); break;
          case '\r': s.Append('\\').Append('r'); break;
          case '\f': s.Append('\\').Append('f'); break;
          case '\t': s.Append('\\').Append('t'); break;
          case '`':  s.Append('\\').Append('`'); break;
          case '$':  s.Append('\\').Append('$'); break;
          default:   s.Append((char)c); break;
        }
      }

      // closing quote
      return s.Append('`').ToString();
    }

  //////////////////////////////////////////////////////////////////////////
  // Utils
  //////////////////////////////////////////////////////////////////////////

    public static bool isName(string name)
    {
      int len = name.Length;

      // must be at least one character long
      if (len == 0) return false;

      // check for "." and ".."
      if (name[0] == '.' && len <= 2)
      {
        if (len == 1) return false;
        if (name[1] == '.') return false;
      }

      // check that each char is unreserved
      for (int i=0; i<len; ++i)
      {
        int c = name[i];
        if (c < 128 && nameMap[c]) continue;
        return false;
      }

      return true;
    }

    public static void checkName(string name)
    {
      if (!isName(name))
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

    static Exception err(string msg)
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
      if (p == null) p = m_emptyPath = (List)new List(Sys.StrType).toImmutable();
      return p;
    }
    static List m_emptyPath;

    static Map emptyQuery()
    {
      Map q = m_emptyQuery;
      if (q == null) q = m_emptyQuery = (Map)new Map(Sys.StrType, Sys.StrType).toImmutable();
      return q;
    }
    static Map m_emptyQuery;

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    static readonly Range parentRange = Range.make(0, -2, false);
    static readonly string dotDot = "..";

    public static readonly Uri m_defVal = fromStr("");

    internal readonly string m_str;
    internal readonly string m_scheme;
    internal readonly string m_userInfo;
    internal readonly string m_host;
    internal readonly Long m_port;
    internal readonly List m_path;
    internal readonly string m_pathStr;
    internal readonly Map m_query;
    internal readonly string m_queryStr;
    internal readonly string m_frag;
    internal string m_encoded;

  }
}