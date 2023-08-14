//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 Mar 2009  Andy Frank  Creation
//   20 May 2009  Andy Frank  Refactor to new OO model
//   20 Apr 2023  Andy Frank  Refactor for ES
//

/**
 * Uri
 */
class Uri extends Obj {

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  constructor(sections) {
    super();
    this.#scheme   = sections.scheme;
    this.#userInfo = sections.userInfo;
    this.#host     = sections.host;
    this.#port     = sections.port;
    this.#pathStr  = sections.pathStr;
    this.#path     = sections.path.toImmutable();
    this.#queryStr = sections.queryStr;
    this.#query    = sections.query.toImmutable();
    this.#frag     = sections.frag;
    this.#str      = sections.str != null ? sections.str : new UriEncoder(this, false).encode();
    this.#encoded  = null;
  }

  #scheme;
  #userInfo;
  #host;
  #port;
  #pathStr;
  #path;
  #queryStr;
  #query;
  #frag;
  #str;
  #encoded;

  static #defVal;
  static defVal() { 
    if (Uri.#defVal === undefined) Uri.#defVal = Uri.fromStr(""); 
    return Uri.#defVal;
  }

  static #_parentRange;
  static #parentRange() { 
    if (!Uri.#_parentRange) Uri.#_parentRange = Range.make(0, -2, false);
    return Uri.#_parentRange;
  }

  static fromStr(s, checked=true) {
    try {
      return new Uri(new UriDecoder(s, false).decode());
    }
    catch (err) {
      if (!checked) return null;
      throw ParseErr.makeStr("Uri", s, null, err);
    }
  }

  static decode(s, checked=true) {
    try {
      return new Uri(new UriDecoder(s, true).decode());
    }
    catch (err) {
      if (!checked) return null;
      throw ParseErr.makeStr("Uri", s, null, err);
    }
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  static decodeQuery(s) {
    try {
      return new UriDecoder(s, true).decodeQuery();
    }
    catch (err) {
      if (err instanceof ArgErr)
        throw ArgErr.make("Invalid Uri query: `" + s + "`: " + err.msg());

      throw ArgErr.make("Invalid Uri query: `" + s + "`");
    }
  }

  static encodeQuery(map) {
    let buf  = "";
    const keys = map.keys();
    const len  = keys.size();
    for (let i=0; i<len; i++) {
      const key = keys.get(i);
      const val = map.get(key);
      if (buf.length > 0) buf += '&';
      buf = Uri.#encodeQueryStr(buf, key);
      if (val != null) {
        buf += '=';
        buf = Uri.#encodeQueryStr(buf, val);
      }
    }
    return buf;
  }

  static #encodeQueryStr(buf, str) {
    const len = str.length;
    for (let i=0; i<len; ++i) {
      const c = str.charCodeAt(i);
      if (c < 128 && (Uri.__charMap[c] & Uri.__QUERY) != 0 && (Uri.__delimEscMap[c] & Uri.__QUERY) == 0)
        buf += str.charAt(i);
      else if (c == 32)
        buf += "+"
      else
        buf = UriEncoder.percentEncodeChar(buf, c);
    }
    return buf;
  }

//////////////////////////////////////////////////////////////////////////
// Tokens
//////////////////////////////////////////////////////////////////////////

  static escapeToken(str, section)
  {
    const mask = Uri.#sectionToMask(section);
    const buf = [];
    const delimEscMap = Uri.__delimEscMap;
    for (let i = 0; i< str.length; ++i) {
      const c = str.charCodeAt(i);
      if (c < delimEscMap.length && (delimEscMap[c] & mask) != 0)
        buf.push('\\');
      buf.push(String.fromCharCode(c));
    }
    return buf.join("");
  }

  static encodeToken(str, section) {
    const mask = Uri.#sectionToMask(section);
    let buf = ""
    const delimEscMap = Uri.__delimEscMap;
    const charMap = Uri.__charMap;
    for (let i = 0; i < str.length; ++i) {
      const c = str.charCodeAt(i);
      if (c < 128 && (charMap[c] & mask) != 0 && (delimEscMap[c] & mask) == 0)
        buf += String.fromCharCode(c);
      else
        buf = UriEncoder.percentEncodeChar(buf, c);
    }
    return buf;
  }

  static decodeToken(str, section) {
    const mask = Uri.#sectionToMask(section);
    if (str.length == 0) return "";
    return new UriDecoder(str, true).decodeToken(mask);
  }

  static unescapeToken(str) {
    let buf = "";
    for (let i = 0; i < str.length; ++i) {
      let c = str.charAt(i);
      if (c == '\\') {
        ++i;
        if (i >= str.length) throw ArgErr.make(`Invalid esc: ${str}`);
        c = str.charAt(i);
      }
      buf += c;
    }
    return buf;
  }

  static #sectionToMask(section) {
    switch (section) {
      case 1: return Uri.__PATH; break;
      case 2: return Uri.__QUERY; break;
      case 3: return Uri.__FRAG; break;
      default: throw ArgErr.make(`Invalid section flag: ${section}`);
    }
  }

  static #sectionPath  = 1;
  static sectionPath() { return Uri.#sectionPath; }
  static #sectionQuery = 2;
  static sectionQuery() { return Uri.#sectionQuery; }
  static #sectionFrag  = 3;
  static sectionFrag() { return Uri.#sectionFrag; }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  equals(that) {
    if (that instanceof Uri)
      return this.#str === that.#str;
    else
      return false;
  }

  toCode() {
    let s = '`';
    const len = this.#str.length;
    for (let i=0; i<len; ++i) {
      const c = this.#str.charAt(i);
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

  hash() { return Str.hash(this.#str); }

  toStr() { return this.#str; }

  toLocale() { return this.#str; }

  literalEncode$(out) { out.wStrLiteral(this.#str, '`'); }

  encode() {
    const x = this.#encoded;
    if (x != null) return x;
    return this.#encoded = new UriEncoder(this, true).encode();
  }

  get() {
    if (this.#scheme == "fan") {
      if (this.#path.size() == 0)
        return Pod.find(this.#host);
    }

    // TODO - TEMP FIX FOR GFX::IMAGE
    return File.make();
  }

//////////////////////////////////////////////////////////////////////////
// Components
//////////////////////////////////////////////////////////////////////////

  isAbs() { return this.#scheme != null; }
  isRel() { return this.#scheme == null; }
  isDir() {
    if (this.#pathStr != null) {
      const p = this.#pathStr;
      const len = p.length;
      if (len > 0 && p.charAt(len-1) == '/') return true;
    }
    return false;
  }

  scheme() { return this.#scheme; }

  auth() {
    if (this.#host == null) return null;
    if (this.#port == null) {
      if (this.#userInfo == null) return this.#host;
      else return `${this.#userInfo}@${this.#host}`;
    }
    else {
      if (this.#userInfo == null) return `${this.#host}:${this.#port}`;
      else return `${this.#userInfo}@${this.#host}:${this.#port}`;
    }
  }

  host()     { return this.#host; }
  userInfo() { return this.#userInfo; }
  port()     { return this.#port; }
  path()     { return this.#path; }
  pathStr()  { return this.#pathStr; }

  isPathAbs() {
    if (this.#pathStr == null || this.#pathStr.length == 0)
      return false;
    else
      return this.#pathStr.charAt(0) == '/';
  }

  isPathRel() { return !this.isPathAbs(); }

  isPathOnly() {
    return this.#scheme == null && this.#host == null && this.#port == null &&
           this.#userInfo == null && this.#queryStr == null && this.#frag == null;
  }

  name() {
    if (this.#path.size() == 0) return "";
    return this.#path.last();
  }

  basename() {
    const n   = this.name();
    const dot = n.lastIndexOf('.');
    if (dot < 2) {
      if (dot < 0)   return n;
      if (n == ".")  return n;
      if (n == "..") return n;
    }
    return n.slice(0, dot);
  }

  ext() {
    const n = this.name();
    const dot = n.lastIndexOf('.');
    if (dot < 2) {
      if (dot < 0)   return null;
      if (n == ".")  return null;
      if (n == "..") return null;
    }
    return n.slice(dot+1);
  }

  mimeType() {
    if (this.isDir()) return MimeType.fromStr("x-directory/normal");
    return MimeType.forExt(this.ext());
  }

  query()    { return this.#query; }
  queryStr() { return this.#queryStr; }
  frag()     { return this.#frag; }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  parent() {
    // if no path bail
    if (this.#path.size() == 0) return null;

    // if just a simple filename, then no parent
    if (this.#path.size() == 1 && !this.isPathAbs() && !this.isDir()) return null;

    // use getRange
    return this.getRange(Uri.#parentRange());
  }

  pathOnly() {
    if (this.#pathStr == null)
      throw Err.make(`Uri has no path: ${this}`);

    if (this.#scheme == null && this.#userInfo == null && this.#host == null &&
        this.#port == null && this.#queryStr == null && this.#frag == null)
      return this;

    const t    = new UriSections();
    t.path     = this.#path;
    t.pathStr  = this.#pathStr;
    t.query    = Uri.emptyQuery();
    t.str      = this.#pathStr;
    return new Uri(t);
  }

  getRangeToPathAbs(range) { return this.getRange(range, true); }

  getRange(range, forcePathAbs=false)
  {
    if (this.#pathStr == null)
      throw Err.make(`Uri has no path: ${this}`);

    const size = this.#path.size();
    const s = range.__start(size);
    const e = range.__end(size);
    const n = e - s + 1;
    if (n < 0) throw IndexErr.make(range);

    let head = (s == 0);
    let tail = (e == size-1);
    if (head && tail && (!forcePathAbs || this.isPathAbs())) return this;

    const t = new UriSections();
    t.path = this.#path.getRange(range);

    let sb = "";
    if ((head && this.isPathAbs()) || forcePathAbs) sb += '/';
    for (let i=0; i<t.path.size(); ++i)
    {
      if (i > 0) sb += '/';
      sb += t.path.get(i);
    }
    if (t.path.size() > 0 && (!tail || this.isDir())) sb += '/';
    t.pathStr = sb;

    if (head) {
      t.scheme   = this.#scheme;
      t.userInfo = this.#userInfo;
      t.host     = this.#host;
      t.port     = this.#port;
    }

    if (tail) {
      t.queryStr = this.#queryStr;
      t.query    = this.#query;
      t.frag     = this.#frag;
    }
    else {
      t.query    = Uri.emptyQuery();
    }

    if (!head && !tail) t.str = t.pathStr;

    return new Uri(t);
  }

//////////////////////////////////////////////////////////////////////////
// Relativize
//////////////////////////////////////////////////////////////////////////

  relTo(base) {
    if ((this.#scheme != base.#scheme) ||
        (this.#userInfo != base.#userInfo) ||
        (this.#host != base.#host) ||
        (this.#port != base.#port))
      return this;

    // at this point we know we have the same scheme and auth, and
    // we're going to create a new URI which is a subset of this one
    const t = new UriSections();
    t.query    = this.#query;
    t.queryStr = this.#queryStr;
    t.frag     = this.#frag;

    // find divergence
    let d=0;
    const len = Math.min(this.#path.size(), base.#path.size());
    for (; d<len; ++d)
      if (this.#path.get(d) != base.#path.get(d))
        break;

    // if diverenge is at root, then no commonality
    if (d == 0) {
      // `/a/b/c`.relTo(`/`) should be `a/b/c`
      if (base.#path.isEmpty() && Str.startsWith(this.#pathStr, "/")) {
        t.path    = this.#path;
        t.pathStr = this.#pathStr.substring(1);
      }
      else {
        t.path    = this.#path;
        t.pathStr = this.#pathStr;
      }
    }

    // if paths are exactly the same
    else if (d == this.#path.size() && d == base.#path.size()) {
      t.path    = Uri.emptyPath();
      t.pathStr = "";
    }

    // create sub-path at divergence point
    else {
      // slice my path
      t.path = this.#path.getRange(Range.makeInclusive(d, -1));

      // insert .. backup if needed
      let backup = base.#path.size() - d;
      if (!base.isDir()) backup--;
      while (backup-- > 0) t.path.insert(0, "..");

      // format the new path string
      t.pathStr = Uri.__toPathStr(false, t.path, this.isDir());
    }

    return new Uri(t);
  }

  relToAuth() {
    if (this.#scheme == null && this.#userInfo == null &&
        this.#host == null && this.#port == null)
      return this;

    const t    = new UriSections();
    t.path     = this.#path;
    t.pathStr  = this.#pathStr;
    t.query    = this.#query;
    t.queryStr = this.#queryStr;
    t.frag     = this.#frag;
    return new Uri(t);
  }

//////////////////////////////////////////////////////////////////////////
// Plus
//////////////////////////////////////////////////////////////////////////

  plus(r) {
    // if r is more or equal as absolute as base, return r
    if (r.#scheme != null) return r;
    if (r.#host != null && this.#scheme == null) return r;
    if (r.isPathAbs() && this.#host == null) return r;

    // this algorthm is lifted straight from
    // RFC 3986 (5.2.2) Transform References;
    const base = this;
    const t = new UriSections();
    if (r.#host != null) {
      t.setAuth(r);
      t.setPath(r);
      t.setQuery(r);
    }
    else {
      if (r.#pathStr == null || r.#pathStr == "") {
        t.setPath(base);
        if (r.#queryStr != null)
          t.setQuery(r);
        else
          t.setQuery(base);
      }
      else {
        if (Str.startsWith(r.#pathStr, "/"))
          t.setPath(r);
        else
          Uri.#merge(t, base, r);
        t.setQuery(r);
      }
      t.setAuth(base);
    }
    t.scheme = base.#scheme;
    t.frag   = r.#frag;
    t.normalize();
    return new Uri(t);
  }

  static #merge(t, base, r) {
    const baseIsAbs = base.isPathAbs();
    const baseIsDir = base.isDir();
    const rIsDir    = r.isDir();
    const rPath     = r.#path;
    let dotLast     = false;

    // compute the target path taking into account whether
    // the base is a dir and any dot segments in relative ref
    let tPath;
    if (base.#path.size() == 0) {
      tPath = r.#path;
    }
    else {
      tPath = base.#path.rw();
      if (!baseIsDir) tPath.pop();
      for (let i=0; i<rPath.size(); ++i) {
        const rSeg = rPath.get(i);
        if (rSeg == ".") { dotLast = true; continue; }
        if (rSeg == "..")
        {
          if (tPath.size() > 0) { tPath.pop(); dotLast = true; continue; }
          if (baseIsAbs) continue;
        }
        tPath.add(rSeg); dotLast = false;
      }
    }

    t.path    = tPath;
    t.pathStr = Uri.__toPathStr(baseIsAbs, tPath, rIsDir || dotLast);
  }

  static __toPathStr(isAbs, path, isDir) {
    let buf = '';
    if (isAbs) buf += '/';
    for (let i=0; i<path.size(); ++i) {
      if (i > 0) buf += '/';
      buf += path.get(i);
    }
    if (isDir && !(buf.length > 0 && buf.charAt(buf.length-1) == '/'))
      buf += '/';
    return buf;
  }

  plusName(name, asDir=false) {
    const size        = this.#path.size();
    const isDir       = this.isDir() || this.#path.isEmpty();
    const newSize     = isDir ? size + 1 : size;
    const temp        = this.#path.dup().__values();
    temp[newSize-1] = name;

    const t = new UriSections();
    t.scheme   = this.#scheme;
    t.userInfo = this.#userInfo;
    t.host     = this.#host;
    t.port     = this.#port;
    t.query    = Uri.emptyQuery();
    t.queryStr = null;
    t.frag     = null;
    t.path     = List.make(Str.type$, temp);
    t.pathStr  = Uri.__toPathStr(this.isAbs() || this.isPathAbs(), t.path, asDir);
    return new Uri(t);
  }

  plusSlash() {
    if (this.isDir()) return this;
    const t = new UriSections();
    t.scheme   = this.#scheme;
    t.userInfo = this.#userInfo;
    t.host     = this.#host;
    t.port     = this.#port;
    t.query    = this.#query;
    t.queryStr = this.#queryStr;
    t.frag     = this.#frag;
    t.path     = this.#path;
    t.pathStr  = this.#pathStr + "/";
    return new Uri(t);
  }

  plusQuery(q) {
    if (q == null || q.isEmpty()) return this;

    const merge = this.#query.dup().setAll(q);

    let s = "";
    const keys = merge.keys();
    for (let i=0; i<keys.size(); i++)
    {
      if (s.length > 0) s += '&';
      const key = keys.get(i);
      const val = merge.get(key);
      s = Uri.#appendQueryStr(s, key);
      s += '=';
      s = Uri.#appendQueryStr(s, val);
    }

    const t = new UriSections();
    t.scheme   = this.#scheme;
    t.userInfo = this.#userInfo;
    t.host     = this.#host;
    t.port     = this.#port;
    t.frag     = this.#frag;
    t.pathStr  = this.#pathStr;
    t.path     = this.#path;
    t.query    = merge.ro();
    t.queryStr = s;
    return new Uri(t);
  }

  static #appendQueryStr(buf, str) {
    const len = str.length;
    for (let i=0; i<len; ++i) {
      const c = str.charCodeAt(i);
      if (c < Uri.__delimEscMap.length && (Uri.__delimEscMap[c] & Uri.__QUERY) != 0)
        buf += '\\';
      buf += str.charAt(i);
    }
    return buf;
  }

  toFile() { return File.make(this); }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

static isName(name) {
  const len = name.length;

  // must be at least one character long
  if (len == 0) return false;

  // check for "." and ".."
  if (name.charAt(0) == '.' && len <= 2) {
    if (len == 1) return false;
    if (name.charAt(1) == '.') return false;
  }

  // check that each char is unreserved
  for (let i=0; i<len; ++i) {
    const c = name.charCodeAt(i);
    if (c < 128 && Uri.#nameMap[c]) continue;
    return false;
  }

  return true;
}

  static checkName(name) {
    if (!Uri.isName(name))
      throw NameErr.make(name);
  }

  static __isUpper(c) { return 65 <= c && c <= 90; }


  static __hexNibble(ch) {
    if ((Uri.__charMap[ch] & Uri.__HEX) == 0)
      throw ParseErr.make(`Invalid percent encoded hex: '${String.fromCharCode(ch)}'`);

    if (ch <= 57) return ch - 48;
    if (ch <= 90) return (ch - 65) + 10;
    return (ch - 97) + 10;
  }

//////////////////////////////////////////////////////////////////////////
// Character Map
//////////////////////////////////////////////////////////////////////////

  static __toSection(section) {
    switch (section) {
      case Uri.__SCHEME: return "scheme";
      case Uri.__USER:   return "userInfo";
      case Uri.__HOST:   return "host";
      case Uri.__PATH:   return "path";
      case Uri.__QUERY:  return "query";
      case Uri.__FRAG:   return "frag";
      default:          return "uri";
    }
  }

  static __isScheme(c) {
    return c < 128 ? (Uri.__charMap[c] & Uri.__SCHEME) != 0 : false;
  }

  static __charMap     = new Array(128);
  static #nameMap      = new Array(128);
  static __delimEscMap = new Array(128);
  static __SCHEME     = 0x01;
  static __USER       = 0x02;
  static __HOST       = 0x04;
  static __PATH       = 0x08;
  static __QUERY      = 0x10;
  static __FRAG       = 0x20;
  static __DIGIT      = 0x40;
  static __HEX        = 0x80;

  static #unreserved = Uri.__SCHEME | Uri.__USER | Uri.__HOST | Uri.__PATH | Uri.__QUERY | Uri.__FRAG;

  static
  {
    // initialize flags for all character maps to 0
    Uri.__charMap.fill(0);
    Uri.#nameMap.fill(0);
    Uri.__delimEscMap.fill(0);

    // alpha/digits characters
    for (let i=97; i<=122; ++i) { Uri.__charMap[i] = Uri.#unreserved; Uri.#nameMap[i] = true; }
    for (let i=65; i<=90; ++i) { Uri.__charMap[i] = Uri.#unreserved; Uri.#nameMap[i] = true; }
    for (let i=48; i<=57; ++i) { Uri.__charMap[i] = Uri.#unreserved; Uri.#nameMap[i] = true; }

    // unreserved symbols
    Uri.__charMap[45] = Uri.#unreserved; Uri.#nameMap[45] = true;
    Uri.__charMap[46] = Uri.#unreserved; Uri.#nameMap[46] = true;
    Uri.__charMap[95] = Uri.#unreserved; Uri.#nameMap[95] = true;
    Uri.__charMap[126] = Uri.#unreserved; Uri.#nameMap[126] = true;

    // hex
    for (let i=48; i<=57; ++i)  Uri.__charMap[i] |= Uri.__HEX | Uri.__DIGIT;
    for (let i=97; i<=102; ++i) Uri.__charMap[i] |= Uri.__HEX;
    for (let i=65; i<=70; ++i)  Uri.__charMap[i] |= Uri.__HEX;

    // sub-delimiter symbols
    Uri.__charMap[33]  = Uri.__USER | Uri.__HOST | Uri.__PATH | Uri.__QUERY | Uri.__FRAG;
    Uri.__charMap[36]  = Uri.__USER | Uri.__HOST | Uri.__PATH | Uri.__QUERY | Uri.__FRAG;
    Uri.__charMap[38]  = Uri.__USER | Uri.__HOST | Uri.__PATH | Uri.__QUERY | Uri.__FRAG;
    Uri.__charMap[39]  = Uri.__USER | Uri.__HOST | Uri.__PATH | Uri.__QUERY | Uri.__FRAG;
    Uri.__charMap[40]  = Uri.__USER | Uri.__HOST | Uri.__PATH | Uri.__QUERY | Uri.__FRAG;
    Uri.__charMap[41]  = Uri.__USER | Uri.__HOST | Uri.__PATH | Uri.__QUERY | Uri.__FRAG;
    Uri.__charMap[42]  = Uri.__USER | Uri.__HOST | Uri.__PATH | Uri.__QUERY | Uri.__FRAG;
    Uri.__charMap[43]  = Uri.__SCHEME | Uri.__USER | Uri.__HOST | Uri.__PATH | Uri.__FRAG;
    Uri.__charMap[44]  = Uri.__USER | Uri.__HOST | Uri.__PATH | Uri.__QUERY | Uri.__FRAG;
    Uri.__charMap[59]  = Uri.__USER | Uri.__HOST | Uri.__PATH | Uri.__QUERY | Uri.__FRAG;
    Uri.__charMap[61]  = Uri.__USER | Uri.__HOST | Uri.__PATH | Uri.__QUERY | Uri.__FRAG;

    // gen-delimiter symbols
    Uri.__charMap[58] = Uri.__HOST | Uri.__PATH  | Uri.__USER  | Uri.__QUERY | Uri.__FRAG;
    Uri.__charMap[47] = Uri.__PATH  | Uri.__QUERY | Uri.__FRAG;
    Uri.__charMap[63] = Uri.__QUERY | Uri.__FRAG;
    Uri.__charMap[35] = 0;
    Uri.__charMap[91] = Uri.__HOST;
    Uri.__charMap[93] = Uri.__HOST;
    Uri.__charMap[64] = Uri.__PATH | Uri.__QUERY | Uri.__FRAG;

    // delimiter escape map - which characters need to
    // be backslashed escaped in each section
    Uri.__delimEscMap[58]  = Uri.__PATH;
    Uri.__delimEscMap[47]  = Uri.__PATH;
    Uri.__delimEscMap[63]  = Uri.__PATH;
    Uri.__delimEscMap[35]  = Uri.__PATH | Uri.__QUERY;
    Uri.__delimEscMap[38]  = Uri.__QUERY;
    Uri.__delimEscMap[59]  = Uri.__QUERY;
    Uri.__delimEscMap[61]  = Uri.__QUERY;
    Uri.__delimEscMap[92]  = Uri.__SCHEME | Uri.__USER | Uri.__HOST | Uri.__PATH | Uri.__QUERY | Uri.__FRAG;
  }

//////////////////////////////////////////////////////////////////////////
// Empty Path/Query
//////////////////////////////////////////////////////////////////////////

  static emptyPath() {
    if (Uri.emptyPath$ === undefined) {
      Uri.emptyPath$ = List.make(Str.type$, []).toImmutable();
    }
    return Uri.emptyPath$;
  }

  static emptyQuery() {
    if (Uri.emptyQuery$ === undefined) {
      Uri.emptyQuery$ = Map.make(Str.type$, Str.type$).toImmutable();
    }
    return Uri.emptyQuery$;
  }

}

/**
 * UriSections
 */

class UriSections {
  constructor() { }

  scheme = null;
  host = null;
  userInfo = null;
  port = null;
  pathStr = null;
  #path = null;
  get path() { return this.#path;}
  set path(it) { this.#path = it.rw(); }
  queryStr = null;
  #query = null;
  get query() { return this.#query; }
  set query(it) { this.#query = it.rw(); }
  frag = null;
  str = null;

  setAuth(x)  { this.userInfo = x.userInfo(); this.host = x.host(); this.port = x.port(); }
  setPath(x)  { this.pathStr = x.pathStr(); this.path = x.path(); }
  setQuery(x) { this.queryStr = x.queryStr(); this.query = x.query(); }
  setFrag(x)  { this.frag = x.frag(); }

  normalize() {
    this.normalizeSchemes();
    this.normalizePath();
    this.normalizeQuery();
  }

  normalizeSchemes() {
    if (this.scheme == null) return;
    if (this.scheme == "http")  { this.normalizeScheme(80);  return; }
    if (this.scheme == "https") { this.normalizeScheme(443); return; }
    if (this.scheme == "ftp")   { this.normalizeScheme(21);  return; }
  }

  normalizeScheme(p) {
    // port 80 -> null
    if (this.port != null && this.port == p) this.port = null;

    // if path is "" -> "/"
    if (this.pathStr == null || this.pathStr.length == 0) {
      this.pathStr = "/";
      if (this.path == null) this.path = Uri.emptyPath();
    }
  }

  normalizePath() {
    if (this.path == null) return;

    let isAbs = Str.startsWith(this.pathStr, "/");
    let isDir = Str.endsWith(this.pathStr, "/");
    let dotLast = false;
    let modified = false;
    for (let i=0; i<this.path.size(); ++i) {
      const seg = this.path.get(i);
      if (seg == "." && (this.path.size() > 1 || this.host != null)) {
        this.path.removeAt(i);
        modified = true;
        dotLast = true;
        i -= 1;
      }
      else if (seg == ".." && i > 0 && this.path.get(i-1).toString() != "..") {
        this.path.removeAt(i);
        this.path.removeAt(i-1);
        modified = true;
        i -= 2;
        dotLast = true;
      }
      else {
        dotLast = false;
      }
    }

    if (modified) {
      if (dotLast) isDir = true;
      if (this.path.size() == 0 || this.path.last().toString() == "..") isDir = false;
      this.pathStr = Uri.__toPathStr(isAbs, this.path, isDir);
    }
  }

  normalizeQuery() {
    if (this.query == null)
      this.query = Uri.emptyQuery();
  }

}

/**
 * UriDecoder
 */
class UriDecoder extends UriSections {
  constructor(str, decoding=false) {
    super();
    this.str = str;
    this.decoding = decoding;
  }

  str;
  decoding;
  dpos = null;
  nextCharWasEscaped = null;

  decode() {
    const str = this.str;
    const len = str.length;
    let pos = 0;

    // ==== scheme ====

    // scan the string from the beginning looking for either a
    // colon or any character which doesn't fit a valid scheme
    let hasUpper = false;
    for (let i=0; i<len; ++i) {
      let c = str.charCodeAt(i);
      if (Uri.__isScheme(c)) {
        if (!hasUpper && Uri.__isUpper(c)) hasUpper = true;
        continue;
      }
      if (c != 58) break;

      // at this point we have a scheme; if we detected
      // any upper case characters normalize to lowercase
      pos = i + 1;
      let scheme = str.substring(0, i);
      if (hasUpper) scheme = Str.lower(scheme);
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
      let authStart = pos+2;
      let authEnd = len;
      let at = -1;
      let colon = -1;
      for (let i=authStart; i<len; ++i) {
        const c = str.charAt(i);
        if (c == '/' || c == '?' || c == '#') { authEnd = i; break; }
        else if (c == '@' && at < 0) { at = i; colon = -1; }
        else if (c == ':') colon = i;
        else if (c == ']') colon = -1;
      }

      // start with assumption that there is no userinfo or port
      let hostStart = authStart;
      let hostEnd = authEnd;

      // if we found an @ symbol, parse out userinfo
      if (at > 0) {
        this.userInfo = this.substring(authStart, at, Uri.__USER);
        hostStart = at+1;
      }

      // if we found an colon, parse out port
      if (colon > 0) {
        this.port = Int.fromStr(str.substring(colon+1, authEnd));
        hostEnd = colon;
      }

      // host is everything left in the authority
      this.host = this.substring(hostStart, hostEnd, Uri.__HOST);
      pos = authEnd;
    }

    // ==== path ====

    // scan the string looking '?' or '#' which ends the path
    // section; while we're scanning count the number of slashes
    let pathStart = pos;
    let pathEnd = len;
    let numSegs = 1;
    let prev = 0;
    for (let i=pathStart; i<len; ++i) {
      const c = str.charAt(i);
      if (prev != '\\') {
        if (c == '?' || c == '#') { pathEnd = i; break; }
        if (i != pathStart && c == '/') ++numSegs;
        prev = c;
      }
      else {
        prev = (c != '\\') ? c : 0;
      }
    }

    // we now have the complete path section
    this.pathStr = this.substring(pathStart, pathEnd, Uri.__PATH);
    this.path = this.pathSegments(this.pathStr, numSegs);
    pos = pathEnd;

    // ==== query ====

    if (pos < len && str.charAt(pos) == '?') {
      // look for end of query which is # or end of string
      let queryStart = pos+1;
      let queryEnd = len;
      prev = 0;
      for (let i=queryStart; i<len; ++i) {
        const c = str.charAt(i);
        if (prev != '\\') {
          if (c == '#') { queryEnd = i; break; }
          prev = c;
        }
        else {
          prev = (c != '\\') ? c : 0;
        }
      }

      // we now have the complete query section
      this.queryStr = this.substring(queryStart, queryEnd, Uri.__QUERY);
      this.query = this.parseQuery(this.queryStr);
      pos = queryEnd;
    }

    // ==== frag ====

    if (pos < len  && str.charAt(pos) == '#') {
      this.frag = this.substring(pos+1, len, Uri.__FRAG);
    }

    // === normalize ===
    this.normalize();

    // if decoding, then we don't want to use original
    // str as Uri.str, so null it out
    this.str = null;

    return this;
  }

  pathSegments(pathStr, numSegs) {
    // if pathStr is "/" then path is the empty list
    let len = pathStr.length;
    if (len == 0 || (len == 1 && pathStr.charAt(0) == '/'))
      return Uri.emptyPath();

    // check for trailing slash (unless backslash escaped)
    if (len > 1 && pathStr.charAt(len-1) == '/' && pathStr.charAt(len-2) != '\\') {
      numSegs--;
      len--;
    }

    // parse the segments
    let path = [];
    let n = 0;
    let segStart = 0;
    let prev = 0;
    for (let i=0; i<pathStr.length; ++i) {
      const c = pathStr.charAt(i);
      if (prev != '\\') {
        if (c == '/')
        {
          if (i > 0) { path.push(pathStr.substring(segStart, i)); n++ }
          segStart = i+1;
        }
        prev = c;
      }
      else {
        prev = (c != '\\') ? c : 0;
      }
    }
    if (segStart < len) {
      path.push(pathStr.substring(segStart, pathStr.length));
      n++;
    }

    return List.make(Str.type$, path);
  }

  decodeQuery() {
    return this.parseQuery(this.substring(0, this.str.length, Uri.__QUERY));
  }

  parseQuery(q) {
    if (q == null) return null;
    const map = Map.make(Str.type$, Str.type$);

    try {
      let start = 0;
      let eq = 0;
      let len = q.length;
      let prev = 0;
      let escaped = false;
      for (let i=0; i<len; ++i) {
        const ch = q.charAt(i);
        if (prev != '\\') {
          if (ch == '=') eq = i;
          if (ch != '&' && ch != ';') { prev = ch; continue; }
        }
        else {
          escaped = true;
          prev = (ch != '\\') ? ch : 0;
          continue;
        }

        if (start < i) {
          this.addQueryParam(map, q, start, eq, i, escaped);
          escaped = false;
        }

        start = eq = i+1;
      }

      if (start < len)
        this.addQueryParam(map, q, start, eq, len, escaped);
    }
    catch (err) {
      // don't let internal error bring down whole uri
      Err.make(err).trace();
    }

    return map;
  }

  addQueryParam(map, q, start, eq, end, escaped) {
    let key,val;
    if (start == eq && q.charAt(start) != '=') {
      key = this.toQueryStr(q, start, end, escaped);
      val = "true";
    }
    else {
      key = this.toQueryStr(q, start, eq, escaped);
      val = this.toQueryStr(q, eq+1, end, escaped);
    }

    const dup = map.get(key, null);
    if (dup != null) val = dup + "," + val;
    map.set(key, val);
  }

  toQueryStr(q, start, end, escaped) {
    if (!escaped) return q.substring(start, end);
    let s = "";
    let prev = 0;
    for (let i=start; i<end; ++i) {
      const c = q.charAt(i);
      if (c != '\\') {
        s += c;
        prev = c;
      }
      else {
        if (prev == '\\') { s += c; prev = 0; }
        else prev = c;
      }
    }
    return s;
  }

  decodeToken(mask) {
    return this.substring(0, this.str.length, mask);
  }

  substring(start, end, section) {
    let buf = [];
    const delimEscMap = Uri.__delimEscMap;
    if (!this.decoding) {
      let last = 0;
      let backslash = 92; // code for backslash
      for (let i = start; i < end; ++i) {
        const ch = this.str.charCodeAt(i);
        if (last == backslash && ch < delimEscMap.length && (delimEscMap[ch] & section) == 0) {
          // don't allow backslash unless truly a delimiter
          buf.pop();
        }
        buf.push(String.fromCharCode(ch));
        last = ((last == backslash && ch == backslash) ? 0 : ch);
      }
    }
    else {
      this.dpos = start;
      while (this.dpos < end) {
        const ch = this.nextChar(section);
        if (this.nextCharWasEscaped && ch < delimEscMap.length && (delimEscMap[ch] & section) != 0) {
          // if ch was an escaped delimiter
          buf.push('\\');
        }
        buf.push(String.fromCharCode(ch));
      }
    }
    return buf.join("");
  }

  nextChar(section) {
    const c = this.nextOctet(section);
    if (c < 0) return -1;
    let c2, c3;
    switch (c >> 4)
    {
      case 0: case 1: case 2: case 3: case 4: case 5: case 6: case 7:
        /* 0xxxxxxx*/
        return c;
      case 12: case 13:
        /* 110x xxxx   10xx xxxx*/
        c2 = this.nextOctet(section);
        if ((c2 & 0xC0) != 0x80)
          throw ParseErr.make("Invalid UTF-8 encoding");
        return ((c & 0x1F) << 6) | (c2 & 0x3F);
      case 14:
        /* 1110 xxxx  10xx xxxx  10xx xxxx */
        c2 = this.nextOctet(section);
        c3 = this.nextOctet(section);
        if (((c2 & 0xC0) != 0x80) || ((c3 & 0xC0) != 0x80))
          throw ParseErr.make("Invalid UTF-8 encoding");
        return (((c & 0x0F) << 12) | ((c2 & 0x3F) << 6) | ((c3 & 0x3F) << 0));
      default:
        throw ParseErr.make("Invalid UTF-8 encoding");
    }
  }

  nextOctet(section) {
    const c = this.str.charCodeAt(this.dpos++);

    // if percent encoded applied to all sections except
    // scheme which should never never use this method
    if (c == 37) // %
    {
      this.nextCharWasEscaped = true;
      return (Uri.__hexNibble(this.str.charCodeAt(this.dpos++)) << 4) | Uri.__hexNibble(this.str.charCodeAt(this.dpos++));
    }
    else
    {
      this.nextCharWasEscaped = false;
    }

    // + maps to space only in query
    if (c == 43 && section == Uri.__QUERY) // +
      return 32 // ' ';

    // verify character ok
    if (c >= Uri.__charMap.length || (Uri.__charMap[c] & section) == 0)
      throw ParseErr.make("Invalid char in " + Uri.__toSection(section) + " at index " + (this.dpos-1));

    // return character as is
    return c;
  }
}

/**
 * UriEncoder
 */
class UriEncoder {
  constructor(uri, encoding) {
    this.uri = uri;
    this.encoding = encoding;
    this.buf = '';
  }

  uri;
  encoding;
  buf;

  encode() {
    let uri = this.uri;

    // scheme
    if (uri.scheme() != null) this.buf += uri.scheme() + ':';


    // authority
    if (uri.userInfo() != null || uri.host() != null || uri.port() != null) {
      this.buf += '/' + '/';
      if (uri.userInfo() != null) { this.doEncode(uri.userInfo(), Uri.__USER); this.buf += '@'; }
      if (uri.host() != null) this.doEncode(uri.host(), Uri.__HOST);
      if (uri.port() != null) this.buf += ':' + uri.port();
    }

    // path
    if (uri.pathStr() != null)
      this.doEncode(uri.pathStr(), Uri.__PATH);

    // query
    if (uri.queryStr() != null)
      { this.buf += '?'; this.doEncode(uri.queryStr(), Uri.__QUERY); }

    // frag
    if (uri.frag() != null)
      { this.buf += '#'; this.doEncode(uri.frag(), Uri.__FRAG); }

    return this.buf;
  }

  doEncode(s, section) {
    if (!this.encoding) { this.buf += s; return this.buf; }

    const len = s.length;
    let c = 0;
    let prev;
    for (let i=0; i<len; ++i) {
      prev = c;
      c = s.charCodeAt(i);

      // unreserved character
      const charMap = Uri.__charMap;
      if (c < 128 && (charMap[c] & section) != 0 && prev != 92) {
        this.buf += String.fromCharCode(c);
        continue;
      }

      // the backslash esc itself doesn't get encoded
      if (c == 92 && prev != 92) continue;

      // we have a reserved, escaped, or non-ASCII

      // encode
      if (c == 32 && section == Uri.__QUERY)
        this.buf += '+';
      else
        this.buf = UriEncoder.percentEncodeChar(this.buf, c);

      // if we just encoded backslash, then it
      // doesn't escape the next char
      if (c == 92) c = 0;
    }
    return this.buf;
  }

  static percentEncodeChar = function(buf, c) {
    if (c <= 0x007F) {
      buf = UriEncoder.percentEncodeByte(buf, c);
    }
    else if (c > 0x07FF) {
      buf = UriEncoder.percentEncodeByte(buf, 0xE0 | ((c >> 12) & 0x0F));
      buf = UriEncoder.percentEncodeByte(buf, 0x80 | ((c >>  6) & 0x3F));
      buf = UriEncoder.percentEncodeByte(buf, 0x80 | ((c >>  0) & 0x3F));
    }
    else {
      buf = UriEncoder.percentEncodeByte(buf, 0xC0 | ((c >>  6) & 0x1F));
      buf = UriEncoder.percentEncodeByte(buf, 0x80 | ((c >>  0) & 0x3F));
    }
    return buf;
  }

  static percentEncodeByte(buf, c) {
    buf += '%';
    const hi = (c >> 4) & 0xf;
    const lo = c & 0xf;
    buf += (hi < 10 ? String.fromCharCode(48+hi) : String.fromCharCode(65+(hi-10)));
    buf += (lo < 10 ? String.fromCharCode(48+lo) : String.fromCharCode(65+(lo-10)));
    return buf;
  }
}