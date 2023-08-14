//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   22 Dec 2008  Andy Frank  Creation
//   20 May 2009  Andy Frank  Refactor to new OO model
//   12 Apr 2023  Matthew Giannini Refactor to ES
//

/**
 * Str
 */
class Str extends Obj {
  constructor() { super(); }

  static defVal() { return ""; } 
  static #spaces = null;

  

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  static equalsIgnoreCase(self, that) { return self.toLowerCase() == that.toLowerCase(); }

  static compareIgnoreCase(self, that) {
    const a = self.toLowerCase();
    const b = that.toLowerCase();
    if (a < b) return -1;
    if (a == b) return 0;
    return 1;
  }

  static toStr(self) { return self; }
  static toLocale(self) { return self; }

  static hash(self) {
    let hash = 0;
    if (self.length == 0) return hash;
    for (let i=0; i<self.length; i++) {
      var ch = self.charCodeAt(i);
      hash = ((hash << 5) - hash) + ch;
      hash = hash & hash;
    }
    return hash;
  }

//////////////////////////////////////////////////////////////////////////
// Operators
//////////////////////////////////////////////////////////////////////////

  static get(self, index) {
    if (index < 0) index += self.length;
    if (index < 0 || index >= self.length) throw IndexErr.make(index);
    return self.charCodeAt(index);
  }

  static getSafe(self, index, def=0) {
    try {
      if (index < 0) index += self.length;
      if (index < 0 || index >= self.length) throw new Error();
      return self.charCodeAt(index);
    }
    catch (err) { return def; }
  }

  static getRange(self, range) {
    const size = self.length;
    const s = range.__start(size);
    const e = range.__end(size);
    if (e+1 < s) throw IndexErr.make(range);
    return self.substr(s, (e-s)+1);
  }

  static plus(self, obj) {
    if (obj == null) return self + "null";
    const x = ObjUtil.toStr(obj);
    if (x.length == 0) return self;
    return self + x;
  }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  static intern(self) { return self; }
  static isEmpty(self) { return self.length == 0; }
  static size(self) { return self.length; }

  static startsWith(self, test) { return self.startsWith(test); }

  static endsWith(self, test) { return self.endsWith(test); }

  static contains(self, arg) { return self.indexOf(arg) != -1 }

  static containsChar(self, arg) { return self.indexOf(Int.toChar(arg)) != -1 }

  static index(self, s, off=0) {
    let i = off;
    if (i < 0) i = self.length+i;
    const r = self.indexOf(s, i);
    if (r < 0) return null;
    return r;
  }

  static indexr(self, s, off=-1) {
    var i = off;
    if (i < 0) i = self.length+i;
    const r = self.lastIndexOf(s, i);
    if (r < 0) return null;
    return r;
  }

  static indexIgnoreCase(self, s, off=0) {
    return Str.index(self.toLowerCase(), s.toLowerCase(), off);
  }

  static indexrIgnoreCase(self, s, off=-1) {
    return Str.indexr(self.toLowerCase(), s.toLowerCase(), off);
  }

//////////////////////////////////////////////////////////////////////////
// Iterators
//////////////////////////////////////////////////////////////////////////

  static each(self, f) {
    const len = self.length;
    for (let i=0; i<len; ++i) f(self.charCodeAt(i), i);
  }

  static eachr(self, f) {
    for (let i=self.length-1; i>=0; i--) f(self.charCodeAt(i), i);
  }

  static eachWhile(self, f) {
    const len = self.length;
    for (let i=0; i<len; ++i) {
      const r = f(self.charCodeAt(i), i);
      if (r != null) return r;
    }
    return null
  }

  static any(self, f) {
    const len = self.length;
    for (let i=0; i<len; ++i) {
      if (f(self.charCodeAt(i), i) == true)
        return true;
    }
    return false;
  }

  static all(self, f) {
    const len = self.length;
    for (let i=0; i<len; ++i) {
      if (f(self.charCodeAt(i), i) == false)
        return false;
    }
    return true;
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  static spaces(n) {
    if (Str.#spaces == null) {
      Str.#spaces = new Array();
      let s = "";
      for (let i=0; i<20; i++) {
        Str.#spaces[i] = s;
        s += " ";
      }
    }
    if (n < 20) return Str.#spaces[n];
    let s = "";
    for (let i=0; i<n; i++) s += " ";
    return s;
  }

  // Fantom restricts lower/upper to ASCII chars only
  static lower(self) {
    let lower = "";
    for (let i = 0; i < self.length; ++i) {
      let char = self[i];
      const code = self.charCodeAt(i);
      if (65 <= code && code <= 90)
        char = String.fromCharCode(code | 0x20);
      lower = lower + char;
    }
    return lower;
  }

  static upper(self) {
    let upper = "";
    for (let i = 0; i < self.length; ++i) {
      let char = self[i];
      const code = self.charCodeAt(i);
      if (97 <= code && code <= 122)
        char = String.fromCharCode(code & ~0x20);
      upper = upper + char;
    }
    return upper;
  }

  static capitalize(self) {
    if (self.length > 0) {
      const ch = self.charCodeAt(0);
      if (97 <= ch && ch <= 122)
        return String.fromCharCode(ch & ~0x20) + self.substring(1);
    }
    return self;
  }

  static decapitalize(self) {
    if (self.length > 0) {
      const ch = self.charCodeAt(0);
      if (65 <= ch && ch <= 90) {
        let s = String.fromCharCode(ch | 0x20);
        s += self.substring(1)
        return s;
      }
    }
    return self;
  }

  static toDisplayName(self) {
    if (self.length == 0) return "";
    let s = '';

    // capitalize first word
    let c = self.charCodeAt(0);
    if (97 <= c && c <= 122) c &= ~0x20;
    s += String.fromCharCode(c);

    // insert spaces before every capital
    let last = c;
    for (let i=1; i<self.length; ++i) {
      c = self.charCodeAt(i);
      if (65 <= c && c <= 90 && last != 95) {
        let next = i+1 < self.length ? self.charCodeAt(i+1) : 81;
        if (!(65 <= last && last <= 90) || !(65 <= next && next <= 90))
          s += ' ';
      } 
      else if (97 <= c && c <= 122) {
        if ((48 <= last && last <= 57)) { s += ' '; c &= ~0x20; }
        else if (last == 95) c &= ~0x20;
      } 
      else if (48 <= c && c <= 57) {
        if (!(48 <= last && last <= 57)) s += ' ';
      } 
      else if (c == 95) {
        s += ' ';
        last = c;
        continue;
      }
      s += String.fromCharCode(c);
      last = c;
    }
    return s;
  }

  static fromDisplayName(self) {
    if (self.length == 0) return "";
    let s = "";
    let c = self.charCodeAt(0);
    let c2 = self.length == 1 ? 0 : self.charCodeAt(1);
    if (65 <= c && c <= 90 && !(65 <= c2 && c2 <= 90)) c |= 0x20;
    s += String.fromCharCode(c);
    let last = c;
    for (let i=1; i<self.length; ++i) {
      c = self.charCodeAt(i);
      if (c != 32) {
        if (last == 32 && 97 <= c && c <= 122) c &= ~0x20;
        s += String.fromCharCode(c);
      }
      last = c;
    }
    return s;
  }

  static mult(self, times) {
    if (times <= 0) return "";
    if (times == 1) return self;
    let s = '';
    for (let i=0; i<times; ++i) s += self;
    return s;
  }

  static justl(self, width) { return Str.padr(self, width, 32); }
  static justr(self, width) { return Str.padl(self, width, 32); }

  static padl(self, w, ch=32) {
    if (self.length >= w) return self;
    const c = String.fromCharCode(ch);
    let s = '';
    for (let i=self.length; i<w; ++i) s += c;
    s += self;
    return s;
  }

  static padr(self, w, ch=32) {
    if (self.length >= w) return self;
    const c = String.fromCharCode(ch);
    let s = '';
    s += self;
    for (let i=self.length; i<w; ++i) s += c;
    return s;
  }

  static reverse(self) {
    let rev = "";
    for (let i=self.length-1; i>=0; i--)
      rev += self[i];
    return rev;
  }

  static trim(self, trimStart=true, trimEnd=true) {
    if (self.length == 0) return self;
    let s = 0;
    let e = self.length-1;
    while (trimStart && s<self.length && self.charCodeAt(s) <= 32) s++;
    while (trimEnd && e>=s && self.charCodeAt(e) <= 32) e--;
    return self.substr(s, (e-s)+1);
  }
  static trimStart(self) { return Str.trim(self, true, false); }
  static trimEnd(self) { return Str.trim(self, false, true); }

  static trimToNull(self) {
    const trimmed = Str.trim(self, true, true);
    return trimmed.length == 0 ? null : trimmed;
  }

  static split(self, sep=null, trimmed=true) {
    if (sep == null) return Str.#splitws(self);
    const toks = List.make(Str.type$, []);
    const trim = (trimmed != null) ? trimmed : true;
    const len = self.length;
    let x = 0;
    for (let i=0; i<len; ++i) {
      if (self.charCodeAt(i) != sep) continue;
      if (x <= i) toks.add(Str.#splitStr(self, x, i, trim));
      x = i+1;
    }
    if (x <= len) toks.add(Str.#splitStr(self, x, len, trim));
    return toks;
  }

  static #splitStr(val, s, e, trim) {
    if (trim == true) {
      while (s < e && val.charCodeAt(s) <= 32) ++s;
      while (e > s && val.charCodeAt(e-1) <= 32) --e;
    }
    return val.substring(s, e);
  }

  static #splitws(val) {
    const toks = List.make(Str.type$, []);
    let len = val.length;
    while (len > 0 && val.charCodeAt(len-1) <= 32) --len;
    let x = 0;
    while (x < len && val.charCodeAt(x) <= 32) ++x;
    for (let i=x; i<len; ++i) {
      if (val.charCodeAt(i) > 32) continue;
      toks.add(val.substring(x, i));
      x = i + 1;
      while (x < len && val.charCodeAt(x) <= 32) ++x;
      i = x;
    }
    if (x <= len) toks.add(val.substring(x, len));
    if (toks.size() == 0) toks.add("");
    return toks;
  }

  static splitLines(self) {
    const lines = List.make(Str.type$, []);
    const len = self.length;
    let s = 0;
    for (var i=0; i<len; ++i) {
      const c = self.charAt(i);
      if (c == '\n' || c == '\r') {
        lines.add(self.substring(s, i));
        s = i+1;
        if (c == '\r' && s < len && self.charAt(s) == '\n') { i++; s++; }
      }
    }
    lines.add(self.substring(s, len));
    return lines;
  }

  static replace(self, oldstr, newstr) {
    if (oldstr == '') return self;
    return self.split(oldstr).join(newstr);
  }

  static numNewlines(self) {
    let numLines = 0;
    const len = self.length;
    for (var i=0; i<len; ++i)
    {
      const c = self.charCodeAt(i);
      if (c == 10) numLines++;
      else if (c == 13) {
        numLines++;
        if (i+1<len && self.charCodeAt(i+1) == 10) i++;
      }
    }
    return numLines;
  }

  static isAscii(self) {
    for (let i=0; i<self.length; i++)
      if (self.charCodeAt(i) > 127)
        return false;
    return true;
  }

  static isSpace(self) {
    for (let i=0; i<self.length; i++) {
      const ch = self.charCodeAt(i);
      if (ch != 32 && ch != 9 && ch != 10 && ch != 12 && ch != 13)
        return false;
    }
    return true;
  }

  static isUpper(self) {
    for (let i=0; i<self.length; i++) {
      const ch = self.charCodeAt(i);
      if (ch < 65 || ch > 90) return false;
    }
    return true;
  }

  static isLower(self) {
    for (let i=0; i<self.length; i++) {
      const ch = self.charCodeAt(i);
      if (ch < 97 || ch > 122) return false;
    }
    return true;
  }

  static isAlpha(self) {
    for (let i=0; i<self.length; i++) {
      const ch = self.charCodeAt(i);
      if (ch >= 128 || (Int.charMap[ch] & Int.ALPHA) == 0)
        return false;
    }
    return true;
  }

  static isAlphaNum(self) {
    for (let i=0; i<self.length; i++) {
      const ch = self.charCodeAt(i);
      if (ch >= 128 || (Int.charMap[ch] & Int.ALPHANUM) == 0)
        return false;
    }
    return true;
  }

  static isEveryChar(self, ch) {
    const len = self.length;
    for (let i=0; i<len; ++i)
      if (self.charCodeAt(i) != ch) return false;
    return true;
  }

//////////////////////////////////////////////////////////////////////////
// Locale
//////////////////////////////////////////////////////////////////////////

  static localeCompare(self, that) {
    return self.localeCompare(that, Locale.cur().toStr(), {sensitivity:'base'});
  }

  static localeUpper(self) { return self.toLocaleUpperCase(Locale.cur().toStr()); }

  static localeLower(self) { return self.toLocaleLowerCase(Locale.cur().toStr()); }

  static localeCapitalize(self) {
    const upper = Str.localeUpper(self);
    return upper[0] + self.substring(1);
  }

  static localeDecapitalize(self) {
    const lower = Str.localeLower(self);
    return lower[0] + self.substring(1);
  }

//////////////////////////////////////////////////////////////////////////
// Conversion
//////////////////////////////////////////////////////////////////////////

  static toBool(self, checked=true) { return Bool.fromStr(self, checked); }
  static toFloat(self, checked=true) { return Float.fromStr(self, checked); }
  static toInt(self, radix=10, checked=true) { return Int.fromStr(self, radix, checked); }
  static toDecimal(self, checked=true) { return Decimal.fromStr(self, checked); }

  static in$(self) { return InStream.__makeForStr(self); }
  static toUri(self) { return Uri.fromStr(self); }
  static toRegex(self) { return Regex.fromStr(self); }

  static chars(self) {
    const ch = List.make(Int.type$, []);
    for (let i=0; i<self.length; i++) ch.add(self.charCodeAt(i));
    return ch;
  }

  static fromChars(ch) {
    let s = '';
    for (let i=0; i<ch.size(); i++) s += String.fromCharCode(ch.get(i));
    return s;
  }

  static toBuf(self, charset=Charset.utf8()) {
    const buf = new MemBuf();
    buf.charset(charset);
    buf.print(self);
    return buf.flip();
  }

  static toCode(self, quote=34, escapeUnicode=false) {
    // opening quote
    let s = "";
    let q = 0;
    if (quote != null) {
      q = String.fromCharCode(quote);
      s += q;
    }

    // NOTE: these escape sequences are duplicated in ObjEncoder
    const len = self.length;
    for (let i=0; i<len; ++i) {
      const c = self.charAt(i);
      switch (c)
      {
        case '\n': s += '\\' + 'n'; break;
        case '\r': s += '\\' + 'r'; break;
        case '\f': s += '\\' + 'f'; break;
        case '\t': s += '\\' + 't'; break;
        case '\\': s += '\\' + '\\'; break;
        case '"':  if (q == '"')  s += '\\' + '"';  else s += c; break;
        case '`':  if (q == '`')  s += '\\' + '`';  else s += c; break;
        case '\'': if (q == '\'') s += '\\' + '\''; else s += c; break;
        case '$':  s += '\\' + '$'; break;
        default:
          var hex  = function(x) { return "0123456789abcdef".charAt(x); }
          var code = c.charCodeAt(0);
          if (code < 32 || (escapeUnicode && code > 127)) {
            s += '\\' + 'u'
              + hex((code>>12)&0xf)
              + hex((code>>8)&0xf)
              + hex((code>>4)&0xf)
              + hex(code & 0xf);
          }
          else {
            s += c;
          }
      }
    }

    // closing quote
    if (q != 0) s += q;
    return s;
  }

  static toXml(self) {
    let s = null;
    const len = self.length;
    for (let i=0; i<len; ++i) {
      const ch = self.charAt(i);
      const c = self.charCodeAt(i);
      if (c > 62) {
        if (s != null) s += ch;
      }
      else {
        const esc = Str.xmlEsc[c];
        if (esc != null && (c != 62 || i==0 || self.charCodeAt(i-1) == 93))
        {
          if (s == null)
          {
            s = "";
            s += self.substring(0,i);
          }
          s += esc;
        }
        else if (s != null)
        {
          s += ch;
        }
      }
    }
    if (s == null) return self;
    return s;
  }

  static xmlEsc = [];
  static
  {
    Str.xmlEsc[38] = "&amp;";
    Str.xmlEsc[60] = "&lt;";
    Str.xmlEsc[62] = "&gt;";
    Str.xmlEsc[39] = "&#39;";
    Str.xmlEsc[34] = "&quot;";
  }

}
