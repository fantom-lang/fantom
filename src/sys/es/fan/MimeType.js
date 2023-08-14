//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   22 Jun 2009  Andy Frank  Creation
//   25 Apr 2023  Matthew Giannini  Refactor for ES
//

/**
 * MimeType represents the parsed value of a Content-Type
 * header per RFC 2045 section 5.1.
 */
class MimeType extends Obj {
  constructor() {
    super();
  }

  static #byExt  = {};
  static #byMime = {};
  static #emptyQuery;

  #str;
  #mediaType;
  #subType;
  #params;

//////////////////////////////////////////////////////////////////////////
// fromStr
//////////////////////////////////////////////////////////////////////////

  static fromStr(s, checked=true) {
    try {
      // check interned mime types
      const mime = MimeType.#byMime[s];
      if (mime != null) return mime;

      // for some reason this one is not in ext2mime and we need to cache it
      if (s == "x-directory/normal") 
      {
        const dir = MimeType.#parseStr(s);
        MimeType.#byMime[s] = dir;
        return dir
      }

      return MimeType.#parseStr(s);
    }
    catch (err)
    {
      if (!checked) return null;
      throw ParseErr.makeStr("MimeType",  s);
    }
  }

  static #parseStr(s) {
    const slash = s.indexOf('/');
    if (slash < 0) throw ParseErr.make(s);
    const media = s.slice(0, slash);
    let sub = s.slice(slash+1, s.length);
    let params = MimeType.#emptyParams();

    const semi = sub.indexOf(';');
    if (semi > 0) {
      params = MimeType.#doParseParams(sub, semi+1);
      sub = Str.trim(sub.slice(0, semi));
    }

    const r = new MimeType();
    r.#str = s;
    r.#mediaType = Str.lower(media);
    r.#subType   = Str.lower(sub);
    r.#params    = params.ro();
    return r;
  }

  static parseParams(s, checked=true) {
    try {
      // use local var to trap exception
      const v = MimeType.#doParseParams(s, 0);
      return v;
    }
    catch (err) {
      if (!checked) return null;
      if (err instanceof ParseErr) throw err;
      throw ParseErr.makeStr("MimeType params",  s);
    }
  }

  static #doParseParams(s, offset) {
    const params = Map.make(Str.type$, Str.type$);
    params.caseInsensitive(true);
    let inQuotes = false;
    let keyStart = offset;
    let valStart = -1;
    let valEnd   = -1;
    let eq       = -1;
    let hasEsc   = false;
    for (let i=keyStart; i<s.length; ++i) {
      let c = s.charAt(i);

      // let parens slide since sometimes they occur in cookies
      // if (c == '(' && !inQuotes)
      //   throw fan.sys.ParseErr.makeStr("MimeType", s, "comments not supported");

      if (c == '=' && eq < 0 && !inQuotes) {
        eq = i++;
        while (MimeType.#isSpace(s, i)) ++i;
        if (s.charAt(i) == '"') { inQuotes = true; ++i; c = s.charAt(i); }
        else inQuotes = false;
        valStart = i;
      }

      if (c == ';' && eq < 0 && !inQuotes) {
        // key with no =val
        let key = Str.trim(s.slice(keyStart, i));
        params.set(key, "");
        keyStart = i+1;
        eq = valStart = valEnd = -1;
        hasEsc = false;
        continue;
      }

      if (eq < 0) continue;

      if (c == '\\' && inQuotes) {
        ++i;
        hasEsc = true;
        continue;
      }

      if (c == '"' && inQuotes) {
        valEnd = i-1;
        inQuotes = false;
      }

      if (c == ';' && !inQuotes) {
        if (valEnd < 0) valEnd = i-1;
        var key = Str.trim(s.slice(keyStart, eq));
        var val = Str.trim(s.slice(valStart, valEnd+1));
        if (hasEsc) val = MimeType.#unescape(val);
        params.set(key, val);
        keyStart = i+1;
        eq = valStart = valEnd = -1;
        hasEsc = false;
      }
    }

    if (keyStart < s.length) {
      if (valEnd < 0) valEnd = s.length-1;
      if (eq < 0) {
        var key = Str.trim(s.slice(keyStart, s.length));
        params.set(key, "");
      }
      else {
        let key = Str.trim(s.slice(keyStart, eq));
        let val = Str.trim(s.slice(valStart, valEnd+1));
        if (hasEsc) val = MimeType.#unescape(val);
        params.set(key, val);
      }
    }

    return params;
  }

  static #isSpace(s, i) {
    if (i >= s.length) throw IndexErr.make(i);
    return Int.isSpace(s.charCodeAt(i));
  }

  static #unescape(s) {
    let buf = "";
    for (let i=0; i<s.length; ++i) {
      const c = s.charAt(i);
      if (c != '\\') buf += c;
      else if (s.charAt(i+1) == '\\') { buf += '\\'; i++; }
    }
    return buf;
  }

//////////////////////////////////////////////////////////////////////////
// Extension
//////////////////////////////////////////////////////////////////////////

  static forExt(ext) {
    if (ext == null) return null;
    try {
      ext = ext.toLowerCase();
      return MimeType.#byExt[ext];
    }
    catch (err) {
      ObjUtil.echo("MimeType.forExt: " + s);
      ObjUtil.echo(err);
      return null;
    }
  }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  equals(obj) {
    if (obj instanceof MimeType) {
      return this.#mediaType == obj.#mediaType &&
            this.#subType == obj.#subType &&
            this.#params.equals(obj.#params);
    }
    return false;
  }

  hash() {
    return 0;
    //return this.mediaType.hashCode() ^
    //       this.subType.hashCode() ^
    //       this.params.hashCode();
  }

  toStr() { return this.#str; }

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  mediaType() { return this.#mediaType; }
  subType() { return this.#subType; }
  params() { return this.#params; }

  charset() {
    const s = this.params().get("charset");
    if (s == null) return Charset.utf8();
    return Charset.fromStr(s);
  }

  noParams() {
    if (this.params().isEmpty()) return this;
    return MimeType.fromStr(`${this.mediaType()}/${this.subType()}`);
  }

//////////////////////////////////////////////////////////////////////////
// Lazy Load
//////////////////////////////////////////////////////////////////////////

  static #emptyParams() {
    let q = MimeType.#emptyQuery;
    if (!q)
    {
      q = Map.make(Str.type$, Str.type$);
      q.caseInsensitive(true);
      //q = q.toImmutable();
      MimeType.#emptyQuery = q;
    }
    return q;
  }

//////////////////////////////////////////////////////////////////////////
// Cache - Populated by mime.js generated by MimeTool
//////////////////////////////////////////////////////////////////////////

  static __cache(ext, s) {
    let mime = MimeType.#parseStr(s);

    // map ext to mime
    MimeType.#byExt[ext] = mime;

    // map mime to its string encoding
    MimeType.#byMime[mime.toStr()] = mime;

    // also map the no-parameter mime type by its string encoding
    mime = mime.noParams();
    MimeType.#byMime[mime.toStr()] = mime;
  }

//////////////////////////////////////////////////////////////////////////
// Predefined
//////////////////////////////////////////////////////////////////////////

/*
fan.sys.MimeType.predefined = function(media, sub, params)
{
  if (params === undefined) params = "";
  var t = new fan.sys.MimeType();
  t.m_mediaType = media;
  t.m_subType = sub;
  t.m_params = fan.sys.MimeType.parseParams(params, true);
  t.m_str = media + "/" + sub;
  return t;
}
*/
}