//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 Mar 09  Andy Frank  Creation
//   20 May 09  Andy Frank  Refactor to new OO model
//

/**
 * Uri
 */
fan.sys.Uri = fan.sys.Obj.$extend(fan.sys.Obj);
fan.sys.Uri.prototype.$ctor = function() {}

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

fan.sys.Uri.fromStr = function(s, checked)
{
  if (checked === undefined) checked = true;
  try
  {
    return fan.sys.Uri.makeSections(new fan.sys.UriDecoder(s, false).decode());
  }
  catch (err)
  {
    if (!checked) return null;
    throw fan.sys.ParseErr.make("Uri",  s);
  }
}

fan.sys.Uri.decode = function(s, checked)
{
  if (checked === undefined) checked = true;
  try
  {
    return new fan.sys.Uri.makeSections(new fan.sys.UriDecoder(s, true).decode());
  }
  catch (err)
  {
    if (!checked) return null;
    throw fan.sys.ParseErr.make("Uri", s);
  }
}

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

fan.sys.Uri.decodeQuery = function(s)
{
  try
  {
    return new fan.sys.UriDecoder(s, true).decodeQuery();
  }
  catch (err)
  {
    if (err instanceof fan.sys.ArgErr)
      throw fan.sys.ArgErr.make("Invalid Uri query: `" + s + "`: " + err.msg());

    throw fan.sys.ArgErr.make("Invalid Uri query: `" + s + "`");
  }
}

fan.sys.Uri.encodeQuery = function(map)
{
  var buf  = "";
  var keys = map.keys();
  var len  = keys.size();
  for (var i=0; i<len; i++)
  {
    var key = keys.get(i);
    var val = map.get(key);
    if (buf.length > 0) buf += '&';
    buf = fan.sys.Uri.encodeQueryStr(buf, key);
    if (val != null)
    {
      buf += '=';
      buf = fan.sys.Uri.encodeQueryStr(buf, val);
    }
  }
  return buf;
}

fan.sys.Uri.encodeQueryStr = function(buf, str)
{
  var len = str.length;
  for (var i=0; i<len; ++i)
  {
    var c = str.charCodeAt(i);
    if (c < 128 && (fan.sys.Uri.charMap[c] & fan.sys.Uri.QUERY) != 0 && (fan.sys.Uri.delimEscMap[c] & fan.sys.Uri.QUERY) == 0)
      buf += str.charAt(i);
    else
      buf = fan.sys.UriEncoder.percentEncodeChar(buf, c);
  }
  return buf;
}

//////////////////////////////////////////////////////////////////////////
// Section Constructor
//////////////////////////////////////////////////////////////////////////

fan.sys.Uri.makeSections = function(x)
{
  var uri = new fan.sys.Uri();
  uri.m_scheme   = x.scheme;
  uri.m_userInfo = x.userInfo;
  uri.m_host     = x.host;
  uri.m_port     = x.port;
  uri.m_pathStr  = x.pathStr;
  uri.m_path     = x.path.ro();
  uri.m_queryStr = x.queryStr;
  uri.m_query    = x.query.ro();
  uri.m_frag     = x.frag;
  uri.m_str      = x.str != null ? x.str : new fan.sys.UriEncoder(uri, false).encode();
  return uri;
}

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

fan.sys.Uri.prototype.m_str = null;
fan.sys.Uri.prototype.m_scheme = null;
fan.sys.Uri.prototype.m_userInfo = null;
fan.sys.Uri.prototype.m_host = null;
fan.sys.Uri.prototype.m_port = null;
fan.sys.Uri.prototype.m_path = null;
fan.sys.Uri.prototype.m_pathStr = null;
fan.sys.Uri.prototype.m_query = null;
fan.sys.Uri.prototype.m_queryStr = null;
fan.sys.Uri.prototype.m_frag = null;
fan.sys.Uri.prototype.m_encoded = null;

//////////////////////////////////////////////////////////////////////////
// Sections
//////////////////////////////////////////////////////////////////////////

fan.sys.UriSections = fan.sys.Obj.$extend(fan.sys.Obj);
fan.sys.UriSections.prototype.$ctor = function() {}

fan.sys.UriSections.prototype.setAuth = function(x)  { this.userInfo = x.m_userInfo; this.host = x.m_host; this.port = x.m_port; }
fan.sys.UriSections.prototype.setPath = function(x)  { this.pathStr = x.m_pathStr; this.path = x.m_path; }
fan.sys.UriSections.prototype.setQuery = function(x) { this.queryStr = x.m_queryStr; this.query = x.m_query; }
fan.sys.UriSections.prototype.setFrag = function(x)  { this.frag = x.m_frag; }

fan.sys.UriSections.prototype.normalize = function()
{
  this.normalizeHttp();
  this.normalizePath();
  this.normalizeQuery();
}

fan.sys.UriSections.prototype.normalizeHttp = function()
{
  if (this.scheme == null || this.scheme != "http")
    return;

  // port 80 -> null
  if (this.port != null && this.port == 80) this.port = null;

  // if path is "" -> "/"
  if (this.pathStr == null || this.pathStr.length == 0)
  {
    this.pathStr = "/";
    if (this.path == null) this.path = fan.sys.Uri.emptyPath();
  }
}

fan.sys.UriSections.prototype.normalizePath = function()
{
  if (this.path == null) return;

  var isAbs = fan.sys.Str.startsWith(this.pathStr, "/");
  var isDir = fan.sys.Str.endsWith(this.pathStr, "/");
  var dotLast = false;
  var modified = false;
  for (var i=0; i<this.path.size(); ++i)
  {
    var seg = this.path.get(i);
    if (seg == "." && (this.path.size() > 1 || this.host != null))
    {
      this.path.removeAt(i);
      modified = true;
      dotLast = true;
      i -= 1;
    }
    else if (seg == ".." && i > 0 && this.path.get(i-1).toString() != "..")
    {
      this.path.removeAt(i);
      this.path.removeAt(i-1);
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
    if (this.path.size() == 0 || this.path.last().toString() == "..") isDir = false;
    this.pathStr = fan.sys.Uri.toPathStr(isAbs, this.path, isDir);
  }
}

fan.sys.UriSections.prototype.normalizeQuery = function()
{
  if (this.query == null)
    this.query = fan.sys.Uri.emptyQuery();
}

fan.sys.UriSections.prototype.scheme = null;
fan.sys.UriSections.prototype.host = null;
fan.sys.UriSections.prototype.userInfo = null;
fan.sys.UriSections.prototype.port = null;
fan.sys.UriSections.prototype.pathStr = null;
fan.sys.UriSections.prototype.path = null;
fan.sys.UriSections.prototype.queryStr = null;
fan.sys.UriSections.prototype.query = null;
fan.sys.UriSections.prototype.frag = null;
fan.sys.UriSections.prototype.str = null;

//////////////////////////////////////////////////////////////////////////
// Decoder
//////////////////////////////////////////////////////////////////////////

fan.sys.UriDecoder = fan.sys.Obj.$extend(fan.sys.UriSections);

fan.sys.UriDecoder.prototype.$ctor = function(str, decoding)
{
  this.str = str;
  this.decoding = decoding;
}

fan.sys.UriDecoder.prototype.decode = function()
{
  var str = this.str;
  var len = str.length;
  var pos = 0;

  // ==== scheme ====

  // scan the string from the beginning looking for either a
  // colon or any character which doesn't fit a valid scheme
  var hasUpper = false;
  for (var i=0; i<len; ++i)
  {
    var c = str.charCodeAt(i);
    if (fan.sys.Uri.isScheme(c))
    {
      if (!hasUpper && fan.sys.Uri.isUpper(c)) hasUpper = true;
      continue;
    }
    if (c != 58) break;

    // at this point we have a scheme; if we detected
    // any upper case characters normalize to lowercase
    pos = i + 1;
    var scheme = str.substring(0, i);
    if (hasUpper) scheme = fan.sys.Str.lower(scheme);
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
    var authStart = pos+2;
    var authEnd = len;
    var at = -1;
    var colon = -1;
    for (var i=authStart; i<len; ++i)
    {
      var c = str.charAt(i);
      if (c == '/' || c == '?' || c == '#') { authEnd = i; break; }
      else if (c == '@' && at < 0) { at = i; colon = -1; }
      else if (c == ':') colon = i;
      else if (c == ']') colon = -1;
    }

    // start with assumption that there is no userinfo or port
    var hostStart = authStart;
    var hostEnd = authEnd;

    // if we found an @ symbol, parse out userinfo
    if (at > 0)
    {
      this.userInfo = this.substring(authStart, at, fan.sys.Uri.USER);
      hostStart = at+1;
    }

    // if we found an colon, parse out port
    if (colon > 0)
    {
      this.port = fan.sys.Int.fromStr(str.substring(colon+1, authEnd));
      hostEnd = colon;
    }

    // host is everything left in the authority
    this.host = this.substring(hostStart, hostEnd, fan.sys.Uri.HOST);
    pos = authEnd;
  }

  // ==== path ====

  // scan the string looking '?' or '#' which ends the path
  // section; while we're scanning count the number of slashes
  var pathStart = pos;
  var pathEnd = len;
  var numSegs = 1;
  var prev = 0;
  for (var i=pathStart; i<len; ++i)
  {
    var c = str.charAt(i);
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
  this.pathStr = this.substring(pathStart, pathEnd, fan.sys.Uri.PATH);
  this.path = this.pathSegments(this.pathStr, numSegs);
  pos = pathEnd;

  // ==== query ====

  if (pos < len && str.charAt(pos) == '?')
  {
    // look for end of query which is # or end of string
    var queryStart = pos+1;
    var queryEnd = len;
    prev = 0;
    for (var i=queryStart; i<len; ++i)
    {
      var c = str.charAt(i);
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
    this.queryStr = this.substring(queryStart, queryEnd, fan.sys.Uri.QUERY);
    this.query = this.parseQuery(this.queryStr);
    pos = queryEnd;
  }

  // ==== frag ====

  if (pos < len  && str.charAt(pos) == '#')
  {
    this.frag = this.substring(pos+1, len, fan.sys.Uri.FRAG);
  }

  // === normalize ===
  this.normalize();

  // if decoding, then we don't want to use original
  // str as Uri.str, so null it out
  this.str = null;

  return this;
}

fan.sys.UriDecoder.prototype.pathSegments = function(pathStr, numSegs)
{
  // if pathStr is "/" then path is the empty list
  var len = pathStr.length;
  if (len == 0 || (len == 1 && pathStr.charAt(0) == '/'))
    return fan.sys.Uri.emptyPath();

  // check for trailing slash
  if (len > 1 && pathStr.charAt(len-1) == '/')
  {
    numSegs--;
    len--;
  }

  // parse the segments
  var path = [];
  var n = 0;
  var segStart = 0;
  var prev = 0;
  for (var i=0; i<pathStr.length; ++i)
  {
    var c = pathStr.charAt(i);
    if (prev != '\\')
    {
      if (c == '/')
      {
        if (i > 0) { path.push(pathStr.substring(segStart, i)); n++ }
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
  {
    path.push(pathStr.substring(segStart, pathStr.length));
    n++;
  }

  return fan.sys.List.make(fan.sys.Str.$type, path);
}

fan.sys.UriDecoder.prototype.decodeQuery = function()
{
  return this.parseQuery(this.substring(0, this.str.length, fan.sys.Uri.QUERY));
}

fan.sys.UriDecoder.prototype.parseQuery = function(q)
{
  if (q == null) return null;
  var map = fan.sys.Map.make(fan.sys.Str.$type, fan.sys.Str.$type);

  try
  {
    var start = 0;
    var eq = 0;
    var len = q.length;
    var prev = 0;
    var escaped = false;
    for (var i=0; i<len; ++i)
    {
      var ch = q.charAt(i);
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
        this.addQueryParam(map, q, start, eq, i, escaped);
        escaped = false;
      }

      start = eq = i+1;
    }

    if (start < len)
      this.addQueryParam(map, q, start, eq, len, escaped);
  }
  catch (err)
  {
    // don't let internal error bring down whole uri
    fan.sys.Err.make(err).trace();
  }

  return map;
}

fan.sys.UriDecoder.prototype.addQueryParam = function(map, q, start, eq, end, escaped)
{
  if (start == eq && q.charAt(start) != '=')
  {
    key = this.toQueryStr(q, start, end, escaped);
    val = "true";
  }
  else
  {
    key = this.toQueryStr(q, start, eq, escaped);
    val = this.toQueryStr(q, eq+1, end, escaped);
  }

  dup = map.get(key, null)
  if (dup !== undefined) val = dup + "," + val
  map.set(key, val)
}

fan.sys.UriDecoder.prototype.toQueryStr = function(q, start, end, escaped)
{
  if (!escaped) return q.substring(start, end);
  var s = "";
  var prev = 0;
  for (var i=start; i<end; ++i)
  {
    var c = q.charAt(i);
    if (c != '\\')
    {
      s += c;
      prev = c;
    }
    else
    {
      if (prev == '\\') { s += c; prev = 0; }
      else prev = c;
    }
  }
  return s;
}

fan.sys.UriDecoder.prototype.substring = function(start, end, section)
{
  if (!this.decoding) return this.str.substring(start, end);

  var buf = "";
  this.dpos = start;
  while (this.dpos < end)
  {
    var ch = this.nextChar(section);
    if (this.nextCharWasEscaped && ch < fan.sys.Uri.delimEscMap.length && (fan.sys.Uri.delimEscMap[ch] & section) != 0)
      buf += '\\';
    buf += String.fromCharCode(ch);
  }
  return buf;
}

fan.sys.UriDecoder.prototype.nextChar = function(section)
{
  var c = this.nextOctet(section);
  if (c < 0) return -1;
  var c2, c3;
  switch (c >> 4)
  {
    case 0: case 1: case 2: case 3: case 4: case 5: case 6: case 7:
      /* 0xxxxxxx*/
      return c;
    case 12: case 13:
      /* 110x xxxx   10xx xxxx*/
      c2 = this.nextOctet(section);
      if ((c2 & 0xC0) != 0x80)
        throw fan.sys.ParseErr.make("Invalid UTF-8 encoding");
      return ((c & 0x1F) << 6) | (c2 & 0x3F);
    case 14:
      /* 1110 xxxx  10xx xxxx  10xx xxxx */
      c2 = this.nextOctet(section);
      c3 = this.nextOctet(section);
      if (((c2 & 0xC0) != 0x80) || ((c3 & 0xC0) != 0x80))
        throw fan.sys.ParseErr.make("Invalid UTF-8 encoding");
      return (((c & 0x0F) << 12) | ((c2 & 0x3F) << 6) | ((c3 & 0x3F) << 0));
    default:
      throw fan.sys.ParseErr.make("Invalid UTF-8 encoding");
  }
}

fan.sys.UriDecoder.prototype.nextOctet = function(section)
{
  var c = this.str.charCodeAt(this.dpos++);

  // if percent encoded applied to all sections except
  // scheme which should never never use this method
  if (c == 37) // %
  {
    this.nextCharWasEscaped = true;
    return (fan.sys.Uri.hexNibble(this.str.charCodeAt(this.dpos++)) << 4) | fan.sys.Uri.hexNibble(this.str.charCodeAt(this.dpos++));
    return x;
  }
  else
  {
    this.nextCharWasEscaped = false;
  }

  // + maps to space only in query
  if (c == 43 && section == fan.sys.Uri.QUERY) // +
    return 32 // ' ';

  // verify character ok
  if (c >= fan.sys.Uri.charMap.length || (fan.sys.Uri.charMap[c] & section) == 0)
    throw fan.sys.ParseErr.make("Invalid char in " + fan.sys.Uri.toSection(section) + " at index " + (this.dpos-1));

  // return character as is
  return c;
}

fan.sys.UriDecoder.prototype.decoding = false;
fan.sys.UriDecoder.prototype.dpos = null;
fan.sys.UriDecoder.prototype.nextCharWasEscaped = null;

//////////////////////////////////////////////////////////////////////////
// Encoder
//////////////////////////////////////////////////////////////////////////


fan.sys.UriEncoder = fan.sys.Obj.$extend(fan.sys.Obj);

fan.sys.UriEncoder.prototype.$ctor = function(uri, encoding)
{
  this.uri = uri;
  this.encoding = encoding;
  this.buf = '';
}

fan.sys.UriEncoder.prototype.encode = function()
{
  var uri = this.uri;

  // scheme
  if (uri.m_scheme != null) this.buf += uri.m_scheme + ':';


  // authority
  if (uri.m_userInfo != null || uri.m_host != null || uri.m_port != null)
  {
    this.buf += '/' + '/';
    if (uri.m_userInfo != null) { this.doEncode(uri.m_userInfo, fan.sys.Uri.USER); this.buf += '@'; }
    if (uri.m_host != null) this.doEncode(uri.m_host, fan.sys.Uri.HOST);
    if (uri.m_port != null) this.buf += ':' + uri.m_port;
  }

  // path
  if (uri.m_pathStr != null)
    this.doEncode(uri.m_pathStr, fan.sys.Uri.PATH);

  // query
  if (uri.m_queryStr != null)
    { this.buf += '?'; this.doEncode(uri.m_queryStr, fan.sys.Uri.QUERY); }

  // frag
  if (uri.m_frag != null)
    { this.buf += '#'; this.doEncode(uri.m_frag, fan.sys.Uri.FRAG); }

  return this.buf;
}

fan.sys.UriEncoder.prototype.doEncode = function(s, section)
{
  if (!this.encoding) { this.buf += s; return this.buf; }

  var len = s.length;
  var c = 0;
  var prev;
  for (var i=0; i<len; ++i)
  {
    prev = c;
    c = s.charCodeAt(i);

    // unreserved character
    if (c < 128 && (fan.sys.Uri.charMap[c] & section) != 0 && prev != 92)
    {
      this.buf += String.fromCharCode(c);
      continue;
    }

    // the backslash esc itself doesn't get encoded
    if (c == 92 && prev != 92) continue;

    // we have a reserved, escaped, or non-ASCII

    // encode
    if (c == 32 && section == fan.sys.Uri.QUERY)
      this.buf += '+';
    else
      this.buf = fan.sys.UriEncoder.percentEncodeChar(this.buf, c);

    // if we just encoded backslash, then it
    // doesn't escape the next char
    if (c == 92) c = 0;
  }
  return this.buf;
}

fan.sys.UriEncoder.prototype.uri = null;
fan.sys.UriEncoder.prototype.encoding = null;
fan.sys.UriEncoder.prototype.buf = null;

fan.sys.UriEncoder.percentEncodeChar = function(buf, c)
{
  if (c <= 0x007F)
  {
    buf = fan.sys.UriEncoder.percentEncodeByte(buf, c);
  }
  else if (c > 0x07FF)
  {
    buf = fan.sys.UriEncoder.percentEncodeByte(buf, 0xE0 | ((c >> 12) & 0x0F));
    buf = fan.sys.UriEncoder.percentEncodeByte(buf, 0x80 | ((c >>  6) & 0x3F));
    buf = fan.sys.UriEncoder.percentEncodeByte(buf, 0x80 | ((c >>  0) & 0x3F));
  }
  else
  {
    buf = fan.sys.UriEncoder.percentEncodeByte(buf, 0xC0 | ((c >>  6) & 0x1F));
    buf = fan.sys.UriEncoder.percentEncodeByte(buf, 0x80 | ((c >>  0) & 0x3F));
  }
  return buf;
}

fan.sys.UriEncoder.percentEncodeByte = function(buf, c)
{
  buf += '%';
  var hi = (c >> 4) & 0xf;
  var lo = c & 0xf;
  buf += (hi < 10 ? String.fromCharCode(48+hi) : String.fromCharCode(65+(hi-10)));
  buf += (lo < 10 ? String.fromCharCode(48+lo) : String.fromCharCode(65+(lo-10)));
  return buf;
}

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

fan.sys.Uri.prototype.$typeof = function()
{
  return fan.sys.Uri.$type;
}

fan.sys.Uri.prototype.equals = function(that)
{
  if (that instanceof fan.sys.Uri)
    return this.m_str === that.m_str;
  else
    return false;
}

fan.sys.Uri.prototype.toCode = function()
{
  var s = '`';
  var len = this.m_str.length;
  for (var i=0; i<len; ++i)
  {
    var c = this.m_str.charAt(i);
    switch (c)
    {
      case '\n': s += '\\' + 'n'; break;
      case '\r': s += '\\' + 'r'; break;
      case '\f': s += '\\' + 'f'; break;
      case '\t': s += '\\' + 't'; break;
      case '`':  s += '\\' + '`'; break;
      case '$':  s += '\\' + '$'; break;
      default:  s += c;
    }
  }
  s += '`';
  return s;
}

fan.sys.Uri.prototype.toStr = function()
{
  return this.m_str;
}

fan.sys.Uri.prototype.toLocale = function()
{
  return this.m_str;
}

fan.sys.Uri.prototype.$literalEncode = function(out)
{
  out.wStrLiteral(this.m_str, '`');
}

fan.sys.Uri.prototype.encode = function()
{
  var x = this.m_encoded;
  if (x != null) return x;
  return this.m_encoded = new fan.sys.UriEncoder(this, true).encode();
}

fan.sys.Uri.prototype.get = function()
{
  if (this.m_scheme == "fan")
  {
    if (this.m_path.size() == 0)
      return fan.sys.Pod.find(this.m_host);
  }

  // TODO - TEMP FIX FOR GFX::IMAGE
  return fan.sys.File.make();
}

//////////////////////////////////////////////////////////////////////////
// Components
//////////////////////////////////////////////////////////////////////////

fan.sys.Uri.prototype.isAbs = function() { return this.m_scheme != null; }
fan.sys.Uri.prototype.isRel = function() { return this.m_scheme == null; }
fan.sys.Uri.prototype.isDir = function()
{
  if (this.m_pathStr != null)
  {
    var p = this.m_pathStr;
    var len = p.length;
      if (len > 0 && p.charAt(len-1) == '/')
        return true;
  }
  return false;
}

fan.sys.Uri.prototype.scheme = function() { return this.m_scheme; }

fan.sys.Uri.prototype.auth = function()
{
  if (this.m_host == null) return null;
  if (this.m_port == null)
  {
    if (this.m_userInfo == null) return this.m_host;
    else return this.m_userInfo + '@' + this.m_host;
  }
  else
  {
    if (this.m_userInfo == null) return this.m_host + ':' + this.m_port;
    else return this.m_userInfo + '@' + this.m_host + ':' + this.m_port;
  }
}

fan.sys.Uri.prototype.host = function() { return this.m_host; }
fan.sys.Uri.prototype.userInfo = function() { return this.m_userInfo; }
fan.sys.Uri.prototype.port = function() { return this.m_port; }
fan.sys.Uri.prototype.path = function() { return this.m_path; }
fan.sys.Uri.prototype.pathStr = function() { return this.m_pathStr; }

fan.sys.Uri.prototype.isPathAbs = function()
{
  if (this.m_pathStr == null || this.m_pathStr.length == 0)
    return false;
  else
    return this.m_pathStr.charAt(0) == '/';
}

fan.sys.Uri.prototype.isPathOnly = function()
{
  return this.m_scheme == null && this.m_host == null && this.m_port == null &&
         this.m_userInfo == null && this.m_queryStr == null && this.m_frag == null;
}

fan.sys.Uri.prototype.name = function()
{
  if (this.m_path.size() == 0) return "";
  return this.m_path.last();
}

fan.sys.Uri.prototype.basename = function()
{
  var n = this.name();
  var dot = n.lastIndexOf('.');
  if (dot < 2)
  {
    if (dot < 0) return n;
    if (n == ".") return n;
    if (n == "..") return n;
  }
  return n.substring(0, dot);
}

fan.sys.Uri.prototype.ext = function()
{
  var n = this.name();
  var dot = n.lastIndexOf('.');
  if (dot < 2)
  {
    if (dot < 0) return null;
    if (n == ".") return null;
    if (n == "..") return null;
  }
  return n.substring(dot+1);
}

fan.sys.Uri.prototype.mimeType = function()
{
  if (this.isDir()) return fan.sys.MimeType.m_dir;
  return fan.sys.MimeType.forExt(this.ext());
}

fan.sys.Uri.prototype.query = function() { return this.m_query; }
fan.sys.Uri.prototype.queryStr = function() { return this.m_queryStr; }
fan.sys.Uri.prototype.frag = function() { return this.m_frag; }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

fan.sys.Uri.prototype.parent = function()
{
  // if no path bail
  if (this.m_path.size() == 0) return null;

  // if just a simple filename, then no parent
  if (this.m_path.size() == 1 && !this.isPathAbs() && !this.isDir()) return null;

  // use getRange
  return this.getRange(fan.sys.Uri.parentRange);
}

fan.sys.Uri.prototype.pathOnly = function()
{
  if (this.m_pathStr == null)
    throw fan.sys.Err.make("Uri has no path: " + this);

  if (this.m_scheme == null && this.m_userInfo == null && this.m_host == null &&
      this.m_port == null && this.m_queryStr == null && this.m_frag == null)
    return this;

  var t = new fan.sys.UriSections();
  t.path     = this.m_path;
  t.pathStr  = this.m_pathStr;
  t.query    = fan.sys.Uri.emptyQuery();
  t.str      = this.m_pathStr;
  return fan.sys.Uri.makeSections(t);
}

fan.sys.Uri.prototype.getRangeToPathAbs = function(range) { return this.getRange(range, true); }

fan.sys.Uri.prototype.getRange = function(range, forcePathAbs)
{
  if (forcePathAbs === undefined) forcePathAbs = false;

  if (this.m_pathStr == null)
    throw fan.sys.Err.make("Uri has no path: " + this);

  var size = this.m_path.size();
  var s = range.$start(size);
  var e = range.$end(size);
  var n = e - s + 1;
  if (n < 0) throw fan.sys.IndexErr.make(range);

  var head = (s == 0);
  var tail = (e == size-1);
  if (head && tail && (!forcePathAbs || this.isPathAbs())) return this;

  var t = new fan.sys.UriSections();
  t.path = this.m_path.getRange(range);

  var sb = "";
  if ((head && this.isPathAbs()) || forcePathAbs) sb += '/';
  for (var i=0; i<t.path.size(); ++i)
  {
    if (i > 0) sb += '/';
    sb += t.path.get(i);
  }
  if (t.path.size() > 0 && (!tail || this.isDir())) sb += '/';
  t.pathStr = sb;

  if (head)
  {
    t.scheme   = this.m_scheme;
    t.userInfo = this.m_userInfo;
    t.host     = this.m_host;
    t.port     = this.m_port;
  }

  if (tail)
  {
    t.queryStr = this.m_queryStr;
    t.query    = this.m_query;
    t.frag     = this.m_frag;
  }
  else
  {
    t.query    = fan.sys.Uri.emptyQuery();
  }

  if (!head && !tail)
  {
    t.str = t.pathStr;
  }

  return fan.sys.Uri.makeSections(t);
}

//////////////////////////////////////////////////////////////////////////
// Relativize
//////////////////////////////////////////////////////////////////////////

fan.sys.Uri.prototype.relTo = function(base)
{
  if ((this.m_scheme != base.m_scheme) ||
      (this.m_userInfo != base.m_userInfo) ||
      (this.m_host != base.m_host) ||
      (this.m_port != base.m_port))
    return this;

  // at this point we know we have the same scheme and auth, and
  // we're going to create a new URI which is a subset of this one
  var t = new fan.sys.UriSections();
  t.query    = this.m_query;
  t.queryStr = this.m_queryStr;
  t.frag     = this.m_frag;

  // find divergence
  var d=0;
  var len = Math.min(this.m_path.size(), base.m_path.size());
  for (; d<len; ++d)
    if (this.m_path.get(d) != base.m_path.get(d))
      break;

  // if diverenge is at root, then no commonality
  if (d == 0)
  {
    // `/a/b/c`.relTo(`/`) should be `a/b/c`
    if (base.m_path.isEmpty() && fan.sys.Str.startsWith(this.m_pathStr, "/"))
    {
      t.path = this.m_path;
      t.pathStr = this.m_pathStr.substring(1);
    }
    else
    {
      t.path = this.m_path;
      t.pathStr = this.m_pathStr;
    }
  }

  // if paths are exactly the same
  else if (d == this.m_path.size() && d == base.m_path.size())
  {
    t.path = fan.sys.Uri.emptyPath();
    t.pathStr = "";
  }

  // create sub-path at divergence point
  else
  {
    // slice my path
    t.path = this.m_path.getRange(fan.sys.Range.makeInclusive(d, -1));

    // insert .. backup if needed
    var backup = base.m_path.size() - d;
    if (!base.isDir()) backup--;
    while (backup-- > 0) t.path.insert(0, "..");

    // format the new path string
    t.pathStr = fan.sys.Uri.toPathStr(false, t.path, this.isDir());
  }

  return fan.sys.Uri.makeSections(t);
}

fan.sys.Uri.prototype.relToAuth = function()
{
  if (this.m_scheme == null && this.m_userInfo == null &&
      this.m_host == null && this.m_port == null)
    return this;

  var t = new fan.sys.UriSections();
  t.path     = this.m_path;
  t.pathStr  = this.m_pathStr;
  t.query    = this.m_query;
  t.queryStr = this.m_queryStr;
  t.frag     = this.m_frag;
  return fan.sys.Uri.makeSections(t);
}

//////////////////////////////////////////////////////////////////////////
// Plus
//////////////////////////////////////////////////////////////////////////

fan.sys.Uri.prototype.plus = function(r)
{
  // if r is more or equal as absolute as base, return r
  if (r.m_scheme != null) return r;
  if (r.m_host != null && this.m_scheme == null) return r;
  if (r.isPathAbs() && this.m_host == null) return r;

  // this algorthm is lifted straight from
  // RFC 3986 (5.2.2) Transform References;
  var base = this;
  var t = new fan.sys.UriSections();
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
      t.setPath(base);
      if (r.m_queryStr != null)
        t.setQuery(r);
      else
        t.setQuery(base);
    }
    else
    {
      if (fan.sys.Str.startsWith(r.m_pathStr, "/"))
        t.setPath(r);
      else
        fan.sys.Uri.merge(t, base, r);
      t.setQuery(r);
    }
    t.setAuth(base);
  }
  t.scheme = base.m_scheme;
  t.frag   = r.m_frag;
  t.normalize();
  return fan.sys.Uri.makeSections(t);
}

fan.sys.Uri.merge = function(t, base, r)
{
  var baseIsAbs = base.isPathAbs();
  var baseIsDir = base.isDir();
  var rIsDir    = r.isDir();
  var rPath     = r.m_path;
  var dotLast   = false;

  // compute the target path taking into account whether
  // the base is a dir and any dot segments in relative ref
  var tPath;
  if (base.m_path.size() == 0)
  {
    tPath = r.m_path;
  }
  else
  {
    tPath = base.m_path.rw();
    if (!baseIsDir) tPath.pop();
    for (var i=0; i<rPath.size(); ++i)
    {
      var rSeg = rPath.get(i);
      if (rSeg == ".") { dotLast = true; continue; }
      if (rSeg == "..")
      {
        if (tPath.size() > 0) { tPath.pop(); dotLast = true; continue; }
        if (baseIsAbs) continue;
      }
      tPath.add(rSeg); dotLast = false;
    }
  }

  t.path = tPath;
  t.pathStr = fan.sys.Uri.toPathStr(baseIsAbs, tPath, rIsDir || dotLast);
}

fan.sys.Uri.toPathStr = function(isAbs, path, isDir)
{
  var buf = '';
  if (isAbs) buf += '/';
  for (var i=0; i<path.size(); ++i)
  {
    if (i > 0) buf += '/';
    buf += path.get(i);
  }
  if (isDir && !(buf.length > 0 && buf.charAt(buf.length-1) == '/'))
    buf += '/';
  return buf;
}

fan.sys.Uri.prototype.plusName = function(name, asDir)
{
  var size        = this.m_path.size();
  var isDir       = this.isDir();
  var newSize     = isDir ? size + 1 : size;
  var temp        = this.m_path.dup().m_values;
  temp[newSize-1] = name;

  var t = new fan.sys.UriSections();
  t.scheme   = this.m_scheme;
  t.userInfo = this.m_userInfo;
  t.host     = this.m_host;
  t.port     = this.m_port;
  t.query    = fan.sys.Uri.emptyQuery();
  t.queryStr = null;
  t.frag     = null;
  t.path     = fan.sys.List.make(fan.sys.Str.$type, temp);
  t.pathStr  = fan.sys.Uri.toPathStr(this.isPathAbs(), t.path, asDir);
  return fan.sys.Uri.makeSections(t);
}

fan.sys.Uri.prototype.plusSlash = function()
{
  if (this.isDir()) return this;
  var t = new fan.sys.UriSections();
  t.scheme   = this.m_scheme;
  t.userInfo = this.m_userInfo;
  t.host     = this.m_host;
  t.port     = this.m_port;
  t.query    = this.m_query;
  t.queryStr = this.m_queryStr;
  t.frag     = this.m_frag;
  t.path     = this.m_path;
  t.pathStr  = this.m_pathStr + "/";
  return fan.sys.Uri.makeSections(t);
}

fan.sys.Uri.prototype.plusQuery = function(q)
{
  if (q == null || q.isEmpty()) return this;

  var merge = this.m_query.dup().setAll(q);

  var s = "";
  var keys = merge.keys();
  for (var i=0; i<keys.size(); i++)
  {
    if (s.length > 0) s += '&';
    var key = keys.get(i);
    var val = merge.get(key);
    s = fan.sys.Uri.appendQueryStr(s, key);
    s += '=';
    s = fan.sys.Uri.appendQueryStr(s, val);
  }

  var t = new fan.sys.UriSections();
  t.scheme   = this.m_scheme;
  t.userInfo = this.m_userInfo;
  t.host     = this.m_host;
  t.port     = this.m_port;
  t.frag     = this.m_frag;
  t.pathStr  = this.m_pathStr;
  t.path     = this.m_path;
  t.query    = merge.ro();
  t.queryStr = s;
  return fan.sys.Uri.makeSections(t);
}

fan.sys.Uri.appendQueryStr = function(buf, str)
{
  var len = str.length;
  for (var i=0; i<len; ++i)
  {
    var c = str.charCodeAt(i);
    if (c < fan.sys.Uri.delimEscMap.length && (fan.sys.Uri.delimEscMap[c] & fan.sys.Uri.QUERY) != 0)
      buf += '\\';
    buf += str.charAt(i);
  }
  return buf;
}

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

fan.sys.Uri.isName = function(name)
{
  var len = name.length;

  // must be at least one character long
  if (len == 0) return false;

  // check for "." and ".."
  if (name.charAt(0) == '.' && len <= 2)
  {
    if (len == 1) return false;
    if (name.charAt(1) == '.') return false;
  }

  // check that each char is unreserved
  for (var i=0; i<len; ++i)
  {
    var c = name.charCodeAt(i);
    if (c < 128 && fan.sys.Uri.nameMap[c]) continue;
    return false;
  }

  return true;
}

fan.sys.Uri.checkName = function(name)
{
  if (!fan.sys.Uri.isName(name))
    throw fan.sys.NameErr.make(name);
}

fan.sys.Uri.isUpper = function(c)
{
  return 65 <= c && c <= 90;
}

fan.sys.Uri.hexNibble = function(ch)
{
  if ((fan.sys.Uri.charMap[ch] & fan.sys.Uri.HEX) == 0)
    throw fan.sys.ParseErr.make("Invalid percent encoded hex: '" + String.fromCharCode(ch));

  if (ch <= 57) return ch - 48;
  if (ch <= 90) return (ch - 65) + 10;
  return (ch - 97) + 10;
}

//////////////////////////////////////////////////////////////////////////
// Character Map
//////////////////////////////////////////////////////////////////////////

fan.sys.Uri.toSection = function(section)
{
  switch (section)
  {
    case fan.sys.Uri.SCHEME: return "scheme";
    case fan.sys.Uri.USER:   return "userInfo";
    case fan.sys.Uri.HOST:   return "host";
    case fan.sys.Uri.PATH:   return "path";
    case fan.sys.Uri.QUERY:  return "query";
    case fan.sys.Uri.FRAG:   return "frag";
    default:                 return "uri";
  }
}

fan.sys.Uri.isScheme = function(c)
{
  return c < 128 ? (fan.sys.Uri.charMap[c] & fan.sys.Uri.SCHEME) != 0 : false;
}

fan.sys.Uri.charMap     = [];
fan.sys.Uri.nameMap     = [];
fan.sys.Uri.delimEscMap = [];
fan.sys.Uri.SCHEME     = 0x01;
fan.sys.Uri.USER       = 0x02;
fan.sys.Uri.HOST       = 0x04;
fan.sys.Uri.PATH       = 0x08;
fan.sys.Uri.QUERY      = 0x10;
fan.sys.Uri.FRAG       = 0x20;
fan.sys.Uri.DIGIT      = 0x40;
fan.sys.Uri.HEX        = 0x80;

// alpha/digits characters
fan.sys.Uri.unreserved = fan.sys.Uri.SCHEME | fan.sys.Uri.USER | fan.sys.Uri.HOST | fan.sys.Uri.PATH | fan.sys.Uri.QUERY | fan.sys.Uri.FRAG;
for (var i=97; i<=122; ++i) { fan.sys.Uri.charMap[i] = fan.sys.Uri.unreserved; fan.sys.Uri.nameMap[i] = true; }
for (var i=65; i<=90; ++i) { fan.sys.Uri.charMap[i] = fan.sys.Uri.unreserved; fan.sys.Uri.nameMap[i] = true; }
for (var i=48; i<=57; ++i) { fan.sys.Uri.charMap[i] = fan.sys.Uri.unreserved; fan.sys.Uri.nameMap[i] = true; }

// unreserved symbols
fan.sys.Uri.charMap[45] = fan.sys.Uri.unreserved; fan.sys.Uri.nameMap[45] = true;
fan.sys.Uri.charMap[46] = fan.sys.Uri.unreserved; fan.sys.Uri.nameMap[46] = true;
fan.sys.Uri.charMap[95] = fan.sys.Uri.unreserved; fan.sys.Uri.nameMap[95] = true;
fan.sys.Uri.charMap[126] = fan.sys.Uri.unreserved; fan.sys.Uri.nameMap[126] = true;

// hex
for (var i=48; i<=57; ++i) fan.sys.Uri.charMap[i] |= fan.sys.Uri.HEX | fan.sys.Uri.DIGIT;
for (var i=97; i<=102; ++i) fan.sys.Uri.charMap[i] |= fan.sys.Uri.HEX;
for (var i=65; i<=70; ++i) fan.sys.Uri.charMap[i] |= fan.sys.Uri.HEX;

// sub-delimiter symbols
fan.sys.Uri.charMap[33]  = fan.sys.Uri.USER | fan.sys.Uri.HOST | fan.sys.Uri.PATH | fan.sys.Uri.QUERY | fan.sys.Uri.FRAG;
fan.sys.Uri.charMap[36]  = fan.sys.Uri.USER | fan.sys.Uri.HOST | fan.sys.Uri.PATH | fan.sys.Uri.QUERY | fan.sys.Uri.FRAG;
fan.sys.Uri.charMap[38]  = fan.sys.Uri.USER | fan.sys.Uri.HOST | fan.sys.Uri.PATH | fan.sys.Uri.QUERY | fan.sys.Uri.FRAG;
fan.sys.Uri.charMap[39] = fan.sys.Uri.USER | fan.sys.Uri.HOST | fan.sys.Uri.PATH | fan.sys.Uri.QUERY | fan.sys.Uri.FRAG;
fan.sys.Uri.charMap[40]  = fan.sys.Uri.USER | fan.sys.Uri.HOST | fan.sys.Uri.PATH | fan.sys.Uri.QUERY | fan.sys.Uri.FRAG;
fan.sys.Uri.charMap[41]  = fan.sys.Uri.USER | fan.sys.Uri.HOST | fan.sys.Uri.PATH | fan.sys.Uri.QUERY | fan.sys.Uri.FRAG;
fan.sys.Uri.charMap[42]  = fan.sys.Uri.USER | fan.sys.Uri.HOST | fan.sys.Uri.PATH | fan.sys.Uri.QUERY | fan.sys.Uri.FRAG;
fan.sys.Uri.charMap[43]  = fan.sys.Uri.SCHEME | fan.sys.Uri.USER | fan.sys.Uri.HOST | fan.sys.Uri.PATH | fan.sys.Uri.FRAG;
fan.sys.Uri.charMap[44]  = fan.sys.Uri.USER | fan.sys.Uri.HOST | fan.sys.Uri.PATH | fan.sys.Uri.QUERY | fan.sys.Uri.FRAG;
fan.sys.Uri.charMap[59]  = fan.sys.Uri.USER | fan.sys.Uri.HOST | fan.sys.Uri.PATH | fan.sys.Uri.QUERY | fan.sys.Uri.FRAG;
fan.sys.Uri.charMap[61]  = fan.sys.Uri.USER | fan.sys.Uri.HOST | fan.sys.Uri.PATH | fan.sys.Uri.QUERY | fan.sys.Uri.FRAG;

// gen-delimiter symbols
fan.sys.Uri.charMap[58] = fan.sys.Uri.PATH | fan.sys.Uri.USER | fan.sys.Uri.QUERY | fan.sys.Uri.FRAG;
fan.sys.Uri.charMap[47] = fan.sys.Uri.PATH | fan.sys.Uri.QUERY | fan.sys.Uri.FRAG;
fan.sys.Uri.charMap[63] = fan.sys.Uri.QUERY | fan.sys.Uri.FRAG;
fan.sys.Uri.charMap[35] = 0;
fan.sys.Uri.charMap[91] = 0;
fan.sys.Uri.charMap[93] = 0;
fan.sys.Uri.charMap[64] = fan.sys.Uri.PATH | fan.sys.Uri.QUERY | fan.sys.Uri.FRAG;

// delimiter escape map - which characters need to
// be backslashed escaped in each section
fan.sys.Uri.delimEscMap[58]  = fan.sys.Uri.PATH;
fan.sys.Uri.delimEscMap[47]  = fan.sys.Uri.PATH;
fan.sys.Uri.delimEscMap[63]  = fan.sys.Uri.PATH;
fan.sys.Uri.delimEscMap[35]  = fan.sys.Uri.PATH | fan.sys.Uri.QUERY;
fan.sys.Uri.delimEscMap[38]  = fan.sys.Uri.QUERY;
fan.sys.Uri.delimEscMap[59]  = fan.sys.Uri.QUERY;
fan.sys.Uri.delimEscMap[61]  = fan.sys.Uri.QUERY;
fan.sys.Uri.delimEscMap[92] = fan.sys.Uri.SCHEME | fan.sys.Uri.USER | fan.sys.Uri.HOST | fan.sys.Uri.PATH | fan.sys.Uri.QUERY | fan.sys.Uri.FRAG;

//////////////////////////////////////////////////////////////////////////
// Empty Path/Query
//////////////////////////////////////////////////////////////////////////

fan.sys.Uri.emptyPath = function()
{
  var p = fan.sys.Uri.$emptyPath;
  if (p == null)
  {
    p = fan.sys.Uri.$emptyPath =
      fan.sys.List.make(fan.sys.Str.$type, []).toImmutable();
  }
  return p;
}
fan.sys.Uri.$emptyPath = null;

fan.sys.Uri.emptyQuery = function()
{
  var q = fan.sys.Uri.$emptyQuery;
  if (q == null)
  {
    q = fan.sys.Uri.$emptyQuery =
      fan.sys.Map.make(fan.sys.Str.$type, fan.sys.Str.$type).toImmutable();
  }
  return q;
}
fan.sys.Uri.$emptyQuery = null;

