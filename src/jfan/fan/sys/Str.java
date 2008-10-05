//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   4 Dec 05  Brian Frank  Creation
//
package fan.sys;

import java.util.HashMap;
import fanx.serial.*;
import fanx.util.StrUtil;

/**
 * Str is a string of Unicode characters.
 */
public final class Str
  extends FanObj
  implements Literal
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  public static Str make(String val)
  {
    if (val == null) return null;
    if (val == "")   return Empty;
    return new Str(val);
  }

  public static Str makeTrim(StringBuilder s)
  {
    int start = 0;
    int end = s.length();
    while (start < end) if (Int.isSpace(s.charAt(start))) start++; else break;
    while (end > start) if (Int.isSpace(s.charAt(end-1))) end--; else break;
    return make(s.substring(start, end));
  }

  private Str(String val)
  {
    this.val = val;
  }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  public final Bool _equals(Object obj)
  {
    if (obj instanceof Str)
      return val.equals(((Str)obj).val) ? Bool.True : Bool.False;
    else
      return Bool.False;
  }

  public final Bool equalsIgnoreCase(Str s)
  {
    if (s == this) return Bool.True;

    String a = this.val;
    String b = s.val;
    int an   = a.length();
    int bn   = b.length();
    if (an != bn) return Bool.False;

    for (int i=0; i<an; ++i)
    {
      int ac = a.charAt(i);
      int bc = b.charAt(i);
      if ('A' <= ac && ac <= 'Z') ac |= 0x20;
      if ('A' <= bc && bc <= 'Z') bc |= 0x20;
      if (ac != bc) return Bool.False;
    }
    return Bool.True;
  }

  public final Int compare(Object obj)
  {
    int cmp = val.compareTo(((Str)obj).val);
    if (cmp < 0) return Int.LT;
    return cmp == 0 ? Int.EQ : Int.GT;
  }

  public final Int compareIgnoreCase(Str s)
  {
    if (s == this) return Int.Zero;

    String a = this.val;
    String b = s.val;
    int an   = a.length();
    int bn   = b.length();

    for (int i=0; i<an && i<bn; ++i)
    {
      int ac = a.charAt(i);
      int bc = b.charAt(i);
      if ('A' <= ac && ac <= 'Z') ac |= 0x20;
      if ('A' <= bc && bc <= 'Z') bc |= 0x20;
      if (ac != bc) return ac < bc ? Int.LT : Int.GT;
    }

    if (an == bn) return Int.Zero;
    return an < bn ? Int.LT : Int.GT;
  }

  public final int hashCode()
  {
    return val.hashCode();
  }

  public final Int hash()
  {
    return Int.make(val.hashCode());
  }

  public final int caseInsensitiveHash()
  {
    String val = this.val;
    int n = val.length();
    int hash = 0;

    for (int i=0; i<n; ++i)
    {
      int c = val.charAt(i);
      if ('A' <= c && c <= 'Z') c |= 0x20;
      hash = 31*hash + c;
    }

    return hash;
  }

  public final Str toStr()
  {
    return this;
  }

  public final void encode(ObjEncoder out)
  {
    out.wStrLiteral(val, '"');
  }

  public final Type type()
  {
    return Sys.StrType;
  }

//////////////////////////////////////////////////////////////////////////
// Operators
//////////////////////////////////////////////////////////////////////////

  public final Int get(Int index)
  {
    int i = (int)index.val;
    if (i < 0) i = val.length()+i;
    return Int.pos(val.charAt(i));
  }

  public final Str slice(Range r)
  {
    int size = val.length();

    int s = r.start(size);
    int e = r.end(size);
    if (e+1 < s) throw IndexErr.make(r).val;

    return make(val.substring(s, e+1));
  }

  public final Str plus(Object obj)
  {
    if (obj == null) return make(val.concat("null"));
    Str x = FanObj.toStr(obj);
    if (x.val == "") return this;
    return make(val.concat(x.val));
  }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  public final Str intern()
  {
    synchronized (interns)
    {
      Str s = (Str)interns.get(val);
      if (s == null) interns.put(val.intern(), s = this);
      return s;
    }
  }

  public final Bool isEmpty()
  {
    return val.length() == 0 ? Bool.True : Bool.False;
  }

  public final Int size()
  {
    return Int.pos(val.length());
  }

  public final Bool startsWith(Str s)
  {
    return Bool.make(val.startsWith(s.val, 0));
  }

  public final Bool endsWith(Str s)
  {
    return Bool.make(val.endsWith(s.val));
  }

  public final Bool contains(Str s)
  {
    return index(s, Int.Zero) != null ? Bool.True : Bool.False;
  }

  public final Bool containsChar(Int ch)
  {
    return val.indexOf((int)ch.val) >= 0 ? Bool.True : Bool.False;
  }

  public final Int index(Str s) { return index(s, Int.Zero); }
  public final Int index(Str s, Int off)
  {
    int i = (int)off.val;
    if (i < 0) i = val.length()+i;

    int r;
    String sval = s.val;
    if (sval.length() == 1)
      r = val.indexOf(sval.charAt(0), i);
    else
      r = val.indexOf(sval, i);

    if (r < 0) return null;
    return Int.make(r);
  }

  public final Int indexr(Str s) { return indexr(s, Int.NegOne); }
  public final Int indexr(Str s, Int off)
  {
    int i = (int)off.val;
    if (i < 0) i = val.length()+i;

    int r;
    String sval = s.val;
    if (sval.length() == 1)
      r = val.lastIndexOf(sval.charAt(0), i);
    else
      r = val.lastIndexOf(sval, i);

    if (r < 0) return null;
    return Int.make(r);
  }

  public final Int indexIgnoreCase(Str s) { return indexIgnoreCase(s, Int.Zero); }
  public final Int indexIgnoreCase(Str s, Int off)
  {
    String val  = this.val, sval = s.val;
    int vlen = val.length(), slen = sval.length();
    int r = -1;

    int i = (int)off.val;
    if (i < 0) i = vlen+i;

    int first = sval.charAt(0) | 0x20;
    for (; i<=vlen-slen; ++i)
    {
      // test first char
      if (first != (val.charAt(i) | 0x20)) continue;

      // test remainder of chars
      r = i;
      for (int si=1, vi=i+1; si<slen; ++si, ++vi)
        if ((sval.charAt(si) | 0x20) != (val.charAt(vi) | 0x20))
          { r = -1; break; }
      if (r >= 0) break;
    }

    if (r < 0) return null;
    return Int.make(r);
  }

  public final Int indexrIgnoreCase(Str s) { return indexrIgnoreCase(s, Int.NegOne); }
  public final Int indexrIgnoreCase(Str s, Int off)
  {
    String val  = this.val, sval = s.val;
    int vlen = val.length(), slen = sval.length();
    int r = -1;

    int i = (int)off.val;
    if (i < 0) i = vlen+i;
    if (i+slen >= vlen) i = vlen-slen;

    int first = sval.charAt(0) | 0x20;
    for (; i>=0; --i)
    {
      // test first char
      if (first != (val.charAt(i) | 0x20)) continue;

      // test remainder of chars
      r = i;
      for (int si=1, vi=i+1; si<slen; ++si, ++vi)
        if ((sval.charAt(si) | 0x20) != (val.charAt(vi) | 0x20))
          { r = -1; break; }
      if (r >= 0) break;
    }

    if (r < 0) return null;
    return Int.make(r);
  }

//////////////////////////////////////////////////////////////////////////
// Iterators
//////////////////////////////////////////////////////////////////////////

  public final void each(Func f)
  {
    String val = this.val;
    int len = val.length();
    for (int i=0; i<len ; ++i)
      f.call2(Int.pos(val.charAt(i)), Int.pos(i));
  }

  public final void eachr(Func f)
  {
    String val = this.val;
    for (int i=val.length()-1; i>=0; --i)
      f.call2(Int.pos(val.charAt(i)), Int.pos(i));
  }

  public final Bool any(Func f)
  {
    String val = this.val;
    int len = val.length();
    for (int i=0; i<len ; ++i)
      if (f.call2(Int.pos(val.charAt(i)), Int.pos(i)) == Bool.True)
        return Bool.True;
    return Bool.False;
  }

  public final Bool all(Func f)
  {
    String val = this.val;
    int len = val.length();
    for (int i=0; i<len ; ++i)
      if (f.call2(Int.pos(val.charAt(i)), Int.pos(i)) == Bool.False)
        return Bool.False;
    return Bool.True;
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  public static Str spaces(Int n)
  {
    // do an array lookup for reasonable length
    // strings since that is the common case
    int count = (int)n.val;
    try { return spaces[count]; } catch (ArrayIndexOutOfBoundsException e) {}

    // otherwise we build a new one
    StringBuilder s = new StringBuilder(spaces[spaces.length-1].val);
    for (int i=spaces.length-1; i<count; ++i)
      s.append(' ');
    return Str.make(s.toString());
  }
  static Str[] spaces = new Str[20];
  static
  {
    StringBuilder s = new StringBuilder();
    for (int i=0; i<spaces.length; ++i)
    {
      spaces[i] = Str.make(s.toString());
      s.append(' ');
    }
  }

  public final Str lower() { return Str.make(lower(val)); }
  public static String lower(String val)
  {
    StringBuilder s = new StringBuilder(val.length());
    for (int i=0; i<val.length(); ++i)
    {
      int ch = val.charAt(i);
      if ('A' <= ch && ch <= 'Z') ch |= 0x20;
      s.append((char)ch);
    }
    return s.toString();
  }

  public final Str upper()
  {
    String val = this.val;
    StringBuilder s = new StringBuilder(val.length());
    for (int i=0; i<val.length(); ++i)
    {
      int ch = val.charAt(i);
      if ('a' <= ch && ch <= 'z') ch &= ~0x20;
      s.append((char)ch);
    }
    return make(s.toString());
  }

  public final Str capitalize()
  {
    String val = this.val;
    if (val.length() > 0)
    {
      int ch = val.charAt(0);
      if ('a' <= ch && ch <= 'z')
      {
        StringBuilder s = new StringBuilder(val.length());
        s.append((char)(ch & ~0x20));
        s.append(val, 1, val.length());
        return make(s.toString());
      }
    }
    return this;
  }

  public final Str decapitalize()
  {
    String val = this.val;
    if (val.length() > 0)
    {
      int ch = val.charAt(0);
      if ('A' <= ch && ch <= 'Z')
      {
        StringBuilder s = new StringBuilder(val.length());
        s.append((char)(ch | 0x20));
        s.append(val, 1, val.length());
        return make(s.toString());
      }
    }
    return this;
  }

  public final Str justl(Int width)
  {
    String val = this.val;
    int w = (int)width.val;
    if (val.length() >= w) return this;
    StringBuilder s = new StringBuilder(w);
    s.append(val);
    for (int i=val.length(); i<w; ++i)
      s.append(' ');
    return make(s.toString());
  }

  public final Str justr(Int width)
  {
    String val = this.val;
    int w = (int)width.val;
    if (val.length() >= w) return this;
    StringBuilder s = new StringBuilder(w);
    for (int i=val.length(); i<w; ++i)
      s.append(' ');
    s.append(val);
    return make(s.toString());
  }

  public final Str reverse()
  {
    String val = this.val;
    if (val.length() < 2) return this;
    StringBuilder s = new StringBuilder(val.length());
    for (int i=val.length()-1; i>=0; --i)
      s.append(val.charAt(i));
    return make(s.toString());
  }

  public final Str trim()
  {
    String val = this.val;
    int len = val.length();
    if (len == 0) return this;
    if (val.charAt(0) > ' ' && val.charAt(len-1) > ' ') return this;
    return make(val.trim());
  }

  public final Str trimStart()
  {
    String val = this.val;
    int len = val.length();
    if (len == 0) return this;
    if (val.charAt(0) > ' ') return this;
    int pos = 1;
    while (pos < len && val.charAt(pos) <= ' ') pos++;
    return make(val.substring(pos));
  }

  public final Str trimEnd()
  {
    String val = this.val;
    int len = val.length();
    if (len == 0) return this;
    int pos = len-1;
    if (val.charAt(pos) > ' ') return this;
    while (pos >= 0 && val.charAt(pos) <= ' ') pos--;
    return make(val.substring(0, pos+1));
  }

  public final List split() { return split(null, Bool.True); }
  public final List split(Int separator) { return split(separator, Bool.True); }
  public final List split(Int separator, Bool trimmed)
  {
    String val = this.val;
    if (separator == null) return splitws(val);
    int sep = (int)separator.val;
    boolean trim = trimmed.val;
    List toks = new List(Sys.StrType, 16);
    int len = val.length();
    int x = 0;
    for (int i=0; i<len; ++i)
    {
      if (val.charAt(i) != sep) continue;
      if (x <= i) toks.add(splitStr(val, x, i, trim));
      x = i+1;
    }
    if (x <= len) toks.add(splitStr(val, x, len, trim));
    return toks;
  }

  private static Str splitStr(String val, int s, int e, boolean trim)
  {
    if (trim)
    {
      while (s < e && val.charAt(s) <= ' ') ++s;
      while (e > s && val.charAt(e-1) <= ' ') --e;
    }
    return Str.make(val.substring(s, e));
  }

  public static List splitws(String val)
  {
    List toks = new List(Sys.StrType, 16);
    int len = val.length();
    while (len > 0 && val.charAt(len-1) <= ' ') --len;
    int x = 0;
    while (x < len && val.charAt(x) <= ' ') ++x;
    for (int i=x; i<len; ++i)
    {
      if (val.charAt(i) > ' ') continue;
      toks.add(Str.make(val.substring(x, i)));
      x = i + 1;
      while (x < len && val.charAt(x) <= ' ') ++x;
      i = x;
    }
    if (x <= len) toks.add(Str.make(val.substring(x, len)));
    if (toks.sz() == 0) toks.add(Empty);
    return toks;
  }

  public final List splitLines()
  {
    List lines = new List(Sys.StrType, 16);
    String val = this.val;
    int len = val.length();
    int s = 0;
    for (int i=0; i<len; ++i)
    {
      int c = val.charAt(i);
      if (c == '\n' || c == '\r')
      {
        lines.add(make(val.substring(s, i)));
        s = i+1;
        if (c == '\r' && s < len && val.charAt(s) == '\n') { i++; s++; }
      }
    }
    lines.add(make(val.substring(s, len)));
    return lines;
  }

  public final Str replace(Str from, Str to)
  {
    if (val.length() == 0) return this;
    return make(StrUtil.replace(val, from.val, to.val));
  }

  public Int numNewlines() { return Int.pos(numNewlines(val)); }
  public static int numNewlines(String val)
  {
    int numLines = 0;
    int len = val.length();
    for (int i=0; i<len; ++i)
    {
      int c = val.charAt(i);
      if (c == '\n') numLines++;
      else if (c == '\r')
      {
        numLines++;
        if (i+1<len && val.charAt(i+1) == '\n') i++;
      }
    }
    return numLines;
  }

  public Bool isAscii()
  {
    String val = this.val;
    int len = val.length();
    for (int i=0; i<len; ++i)
      if (val.charAt(i) >= 128) return Bool.False;
    return Bool.True;
  }

  public Bool isSpace()
  {
    String val = this.val;
    int len = val.length();
    for (int i=0; i<len; ++i)
    {
      int ch = val.charAt(i);
      if (ch >= 128 || (Int.charMap[ch] & Int.SPACE) == 0)
        return Bool.False;
    }
    return Bool.True;
  }

  public Bool isUpper()
  {
    String val = this.val;
    int len = val.length();
    for (int i=0; i<len; ++i)
    {
      int ch = val.charAt(i);
      if (ch >= 128 || (Int.charMap[ch] & Int.UPPER) == 0)
        return Bool.False;
    }
    return Bool.True;
  }

  public Bool isLower()
  {
    String val = this.val;
    int len = val.length();
    for (int i=0; i<len; ++i)
    {
      int ch = val.charAt(i);
      if (ch >= 128 || (Int.charMap[ch] & Int.LOWER) == 0)
        return Bool.False;
    }
    return Bool.True;
  }

  public boolean isEveryChar(int ch)
  {
    String val = this.val;
    int len = val.length();
    for (int i=0; i<len; ++i)
      if (val.charAt(i) != ch) return false;
    return true;
  }

//////////////////////////////////////////////////////////////////////////
// Locale
//////////////////////////////////////////////////////////////////////////

  public final Int localeCompare(Str x)
  {
    int cmp = Locale.current().collator().compare(val, x.val);
    if (cmp < 0) return Int.LT;
    return cmp == 0 ? Int.EQ : Int.GT;
  }

  public final Str localeLower()
  {
    return make(val.toLowerCase(Locale.current().java()));
  }

  public final Str localeUpper()
  {
    return make(val.toUpperCase(Locale.current().java()));
  }

  public final Str localeCapitalize()
  {
    String val = this.val;
    if (val.length() > 0)
    {
      int ch = val.charAt(0);
      if (Character.isLowerCase(ch))
      {
        StringBuilder s = new StringBuilder(val.length());
        s.append(Character.toString((char)ch).toUpperCase(Locale.current().java()).charAt(0));
        s.append(val, 1, val.length());
        return make(s.toString());
      }
    }
    return this;
  }

  public final Str localeDecapitalize()
  {
    String val = this.val;
    if (val.length() > 0)
    {
      int ch = val.charAt(0);
      if (Character.isUpperCase(ch))
      {
        StringBuilder s = new StringBuilder(val.length());
        s.append(Character.toString((char)ch).toLowerCase(Locale.current().java()).charAt(0));
        s.append(val, 1, val.length());
        return make(s.toString());
      }
    }
    return this;
  }

//////////////////////////////////////////////////////////////////////////
// Conversion
//////////////////////////////////////////////////////////////////////////

  public final Bool toBool() { return Bool.fromStr(this, Bool.True); }
  public final Bool toBool(Bool checked) { return Bool.fromStr(this, checked); }

  public final Int toInt() { return Int.fromStr(this, Int.Ten, Bool.True); }
  public final Int toInt(Int radix) { return Int.fromStr(this, radix, Bool.True); }
  public final Int toInt(Int radix, Bool checked) { return Int.fromStr(this, radix, checked); }

  public final Double toFloat() { return FanFloat.fromStr(this, Bool.True); }
  public final Double toFloat(Bool checked) { return FanFloat.fromStr(this, checked); }

  public final Decimal toDecimal() { return Decimal.fromStr(this, Bool.True); }
  public final Decimal toDecimal(Bool checked) { return Decimal.fromStr(this, checked); }

  public final Uri toUri() { return Uri.fromStr(this); }

  public final Str toCode() { return toCode(Int.pos['"'], Bool.False); }
  public final Str toCode(Int quote) { return toCode(quote, Bool.False); }
  public final Str toCode(Int quote, Bool escapeUnicode)
  {
    StringBuilder s = new StringBuilder(val.length()+10);

    // opening quote
    boolean escu = escapeUnicode.val;
    int q = 0;
    if (quote != null)
    {
      q = (int)quote.val;
      s.append((char)q);
    }

    // NOTE: these escape sequences are duplicated in ObjEncoder
    String val = this.val;
    int len = val.length();
    for (int i=0; i<len; ++i)
    {
      int c = val.charAt(i);
      switch (c)
      {
        case '\n': s.append('\\').append('n'); break;
        case '\r': s.append('\\').append('r'); break;
        case '\f': s.append('\\').append('f'); break;
        case '\t': s.append('\\').append('t'); break;
        case '\\': s.append('\\').append('\\'); break;
        case '"':  if (q == '"')  s.append('\\').append('"');  else s.append((char)c); break;
        case '`':  if (q == '`')  s.append('\\').append('`');  else s.append((char)c); break;
        case '\'': if (q == '\'') s.append('\\').append('\''); else s.append((char)c); break;
        case '$':  s.append('\\').append('$'); break;
        default:
          if (escu && c > 127)
          {
            s.append('\\').append('u')
             .append((char)hex((c>>12)&0xf))
             .append((char)hex((c>>8)&0xf))
             .append((char)hex((c>>4)&0xf))
             .append((char)hex(c&0xf));
          }
          else
          {
            s.append((char)c);
          }
      }
    }

    // closing quote
    if (q != 0) s.append((char)q);

    return make(s.toString());
  }

  private int hex(int nib) { return "0123456789abcdef".charAt(nib); }

  public final Str toXml()
  {
    StringBuilder s = null;
    String val = this.val;
    int len = val.length();
    for (int i=0; i<len; ++i)
    {
      int c = val.charAt(i);
      if (c > '>')
      {
        if (s != null) s.append((char)c);
      }
      else
      {
        String esc = xmlEsc[c];
        if (esc != null && (c != '>' || i==0 || val.charAt(i-1) == ']'))
        {
          if (s == null)
          {
            s = new StringBuilder(len+12);
            s.append(val, 0, i);
          }
          s.append(esc);
        }
        else if (s != null)
        {
          s.append((char)c);
        }
      }
    }
    if (s == null) return this;
    return make(s.toString());
  }

  private static String[] xmlEsc = new String['>'+1];
  static
  {
    xmlEsc['&']  = "&amp;";
    xmlEsc['<']  = "&lt;";
    xmlEsc['>']  = "&gt;";
    xmlEsc['\''] = "&apos;";
    xmlEsc['"']  = "&quot;";
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  public static final Str Empty   = new Str("");
  public static final Str nullStr = new Str("null");
  public static final Str sysStr  = new Str("sys");
  public static final Str thisStr = new Str("this");
  public static final Str uriStr  = new Str("uri");

  private static final HashMap interns = new HashMap();

  static final Str[] ascii = new Str[128];
  static
  {
    for (int i=0; i<ascii.length; ++i)
      ascii[i] = make(String.valueOf((char)i)).intern();
  }

  public final String val;

}