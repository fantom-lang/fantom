//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   13 Sep 06  Andy Frank  Creation
//

using System;
using System.Collections;
using System.Text;
using System.Text.RegularExpressions;
using Fanx.Serial;
using Fanx.Util;

namespace Fan.Sys
{
  ///
  /// Str is a string of Unicode characters.
  ///
  public sealed class Str : FanObj, Literal
  {

  //////////////////////////////////////////////////////////////////////////
  // Construction
  //////////////////////////////////////////////////////////////////////////

    public static Str make(string val)
    {
      if (val == null) return null;
      if (val == "")   return Empty;
      return new Str(val);
    }

    public static Str makeTrim(StringBuilder s)
    {
      int start = 0;
      int end = s.Length;
      while (start < end) if (FanInt.isSpace(s[start])) start++; else break;
      while (end > start) if (FanInt.isSpace(s[end-1])) end--; else break;
      return make(s.ToString(start, end-start));
    }

    private Str(string val)
    {
      this.val = val;
    }

  //////////////////////////////////////////////////////////////////////////
  // Identity
  //////////////////////////////////////////////////////////////////////////

    public override Boolean _equals(object obj)
    {
      if (obj is Str)
        return val == ((Str)obj).val ? Boolean.True : Boolean.False;
      else
        return Boolean.False;
    }

    public Boolean equalsIgnoreCase(Str s)
    {
      if (s == this) return Boolean.True;

      string a = this.val;
      string b = s.val;
      int an   = a.Length;
      int bn   = b.Length;
      if (an != bn) return Boolean.False;

      for (int i=0; i<an; i++)
      {
        int ac = a[i];
        int bc = b[i];
        if ('A' <= ac && ac <= 'Z') ac |= 0x20;
        if ('A' <= bc && bc <= 'Z') bc |= 0x20;
        if (ac != bc) return Boolean.False;
      }
      return Boolean.True;
    }

    public override Long compare(object obj)
    {
      int cmp = String.CompareOrdinal(val, ((Str)obj).val);
      if (cmp < 0) return FanInt.LT;
      return cmp == 0 ? FanInt.EQ : FanInt.GT;
    }

    public Long compareIgnoreCase(Str s)
    {
      if (s == this) return FanInt.Zero;

      string a = this.val;
      string b = s.val;
      int an   = a.Length;
      int bn   = b.Length;

      for (int i=0; i<an && i<bn; i++)
      {
        int ac = a[i];
        int bc = b[i];
        if ('A' <= ac && ac <= 'Z') ac |= 0x20;
        if ('A' <= bc && bc <= 'Z') bc |= 0x20;
        if (ac != bc) return ac < bc ? FanInt.LT : FanInt.GT;
      }

      if (an == bn) return FanInt.Zero;
      return an < bn ? FanInt.LT : FanInt.GT;
    }

    public override int GetHashCode()
    {
      return val.GetHashCode();
    }

    public override Long hash()
    {
      return Long.valueOf(val.GetHashCode());
    }

    public int caseInsensitiveHash()
    {
      string val = this.val;
      int n = val.Length;
      int hash = 0;

      for (int i=0; i<n; i++)
      {
        int c = val[i];
        if ('A' <= c && c <= 'Z') c |= 0x20;
        hash = 31*hash + c;
      }

      return hash;
    }

    public override Str toStr()
    {
      return this;
    }

    public void encode(ObjEncoder @out)
    {
      @out.wStrLiteral(val, '"');
    }

    public override Type type()
    {
      return Sys.StrType;
    }

  //////////////////////////////////////////////////////////////////////////
  // Operators
  //////////////////////////////////////////////////////////////////////////

    public Long get(Long index)
    {
      int i = index.intValue();
      if (i < 0) i = val.Length+i;
      return Long.valueOf(val[i]);
    }

    public Str slice(Range r)
    {
      int size = val.Length;

      int s = r.start(size);
      int e = r.end(size);
      if (e+1 < s) throw IndexErr.make(r).val;

      return make(val.Substring(s, (e-s)+1));
    }

    public Str plus(object obj)
    {
      if (obj == null) return make(String.Concat(val, "null"));
      Str x = FanObj.toStr(obj);
      if (x.val == "") return this;
      return make(String.Concat(val, x.val));
    }

  //////////////////////////////////////////////////////////////////////////
  // Identity
  //////////////////////////////////////////////////////////////////////////

    public Str intern()
    {
      Str s = (Str)interns[val];
      if (s == null) interns[val] = s = this;
      return s;
    }

    public Boolean isEmpty()
    {
      return val.Length == 0 ? Boolean.True : Boolean.False;
    }

    public Long size()
    {
      return Long.valueOf(val.Length);
    }

    public Boolean startsWith(Str s)
    {
      return Boolean.valueOf(val.StartsWith(s.val));
    }

    public Boolean endsWith(Str s)
    {
      return Boolean.valueOf(val.EndsWith(s.val));
    }

    public Boolean contains(Str s)
    {
      return index(s, FanInt.Zero) != null ? Boolean.True : Boolean.False;
    }

    public Boolean containsChar(Long ch)
    {
      return val.IndexOf((char)ch.longValue()) >= 0 ? Boolean.True : Boolean.False;
    }

    public Long index(Str s) { return index(s, FanInt.Zero); }
    public Long index(Str s, Long off)
    {
      int i = off.intValue();
      if (i < 0) i = val.Length+i;

      int r;
      string sval = s.val;
      if (sval.Length == 1)
        r = val.IndexOf(sval[0], i);
      else
        r = val.IndexOf(sval, i);

      if (r < 0) return null;
      return Long.valueOf(r);
    }

    public Long indexr(Str s) { return indexr(s, FanInt.NegOne); }
    public Long indexr(Str s, Long off)
    {
      int i = off.intValue();
      if (i < 0) i = val.Length+i;

      int r;
      string sval = s.val;
      if (sval.Length == 1)
        r = val.LastIndexOf(sval[0], i);
      else
      {
        // this doesn't match Java impl - so we have to roll
        // our own - prob alot of room for improvement...
        //r = val.LastIndexOf(sval, i, StringComparison.InvariantCulture);

        int len = val.Length;
        int slen = sval.Length;
        if (len < slen) return null;
        r = -1;
        for (; i>=0; i--)
          if (nStartsWith(val, sval, i))
            { r = i; break; }
      }

      if (r < 0) return null;
      return Long.valueOf(r);
    }

    public Long indexIgnoreCase(Str s) { return indexIgnoreCase(s, FanInt.Zero); }
    public Long indexIgnoreCase(Str s, Long off)
    {
      string val  = this.val, sval = s.val;
      int vlen = val.Length, slen = sval.Length;
      int r = -1;

      int i = off.intValue();
      if (i < 0) i = vlen+i;

      int first = sval[0] | 0x20;
      for (; i<=vlen-slen; ++i)
      {
        // test first char
        if (first != (val[i] | 0x20)) continue;

        // test remainder of chars
        r = i;
        for (int si=1, vi=i+1; si<slen; ++si, ++vi)
          if ((sval[si] | 0x20) != (val[vi] | 0x20))
            { r = -1; break; }
        if (r >= 0) break;
      }

      if (r < 0) return null;
      return Long.valueOf(r);
    }

    public Long indexrIgnoreCase(Str s) { return indexrIgnoreCase(s, FanInt.NegOne); }
    public Long indexrIgnoreCase(Str s, Long off)
    {
      string val  = this.val, sval = s.val;
      int vlen = val.Length, slen = sval.Length;
      int r = -1;

      int i = off.intValue();
      if (i < 0) i = vlen+i;
      if (i+slen >= vlen) i = vlen-slen;

      int first = sval[0] | 0x20;
      for (; i>=0; --i)
      {
        // test first char
        if (first != (val[i] | 0x20)) continue;

        // test remainder of chars
        r = i;
        for (int si=1, vi=i+1; si<slen; ++si, ++vi)
          if ((sval[si] | 0x20) != (val[vi] | 0x20))
            { r = -1; break; }
        if (r >= 0) break;
      }

      if (r < 0) return null;
      return Long.valueOf(r);
    }

    private bool nStartsWith(string s, string pre, int off)
    {
      if (off >= s.Length) return false;

      int slen = s.Length;
      int plen = pre.Length;
      if (off+plen > s.Length) return false;

      for (int i=0; i<plen && i+off<slen; i++)
        if (s[i+off] != pre[i]) return false;

      return true;
    }

  //////////////////////////////////////////////////////////////////////////
  // Iterators
  //////////////////////////////////////////////////////////////////////////

    public void each(Func f)
    {
      string val = this.val;
      int len = val.Length;
      for (int i=0; i<len ; i++)
        f.call2(Long.valueOf(val[i]), Long.valueOf(i));
    }

    public void eachr(Func f)
    {
      string val = this.val;
      for (int i=val.Length-1; i>=0; --i)
        f.call2(Long.valueOf(val[i]), Long.valueOf(i));
    }

    public Boolean any(Func f)
    {
      string val = this.val;
      int len = val.Length;
      for (int i=0; i<len ; i++)
        if (f.call2(Long.valueOf(val[i]), Long.valueOf(i)) == Boolean.True)
          return Boolean.True;
      return Boolean.False;
    }

    public Boolean all(Func f)
    {
      string val = this.val;
      int len = val.Length;
      for (int i=0; i<len ; i++)
        if (f.call2(Long.valueOf(val[i]), Long.valueOf(i)) == Boolean.False)
          return Boolean.False;
      return Boolean.True;
    }

  //////////////////////////////////////////////////////////////////////////
  // Utils
  //////////////////////////////////////////////////////////////////////////

    public static Str spaces(Long n)
    {
      // do an array lookup for reasonable length
      // strings since that is the common case
      int count = n.intValue();
      try { return m_spaces[count]; } catch (IndexOutOfRangeException) {}

      // otherwise we build a new one
      StringBuilder s = new StringBuilder(m_spaces[m_spaces.Length-1].val);
      for (int i=m_spaces.Length-1; i<count; i++)
        s.Append(' ');
      return Str.make(s.ToString());
    }

    public Str lower() { return Str.make(lower(val)); }
    public static string lower(string val)
    {
      StringBuilder s = new StringBuilder(val.Length);
      for (int i=0; i<val.Length; i++)
      {
        int ch = val[i];
        if ('A' <= ch && ch <= 'Z') ch |= 0x20;
        s.Append((char)ch);
      }
      return s.ToString();
    }

    public Str upper()
    {
      string val = this.val;
      StringBuilder s = new StringBuilder(val.Length);
      for (int i=0; i<val.Length; i++)
      {
        int ch = val[i];
        if ('a' <= ch && ch <= 'z') ch &= ~0x20;
        s.Append((char)ch);
      }
      return make(s.ToString());
    }

    public Str capitalize()
    {
      string val = this.val;
      if (val.Length > 0)
      {
        int ch = val[0];
        if ('a' <= ch && ch <= 'z')
        {
          StringBuilder s = new StringBuilder(val.Length);
          s.Append((char)(ch & ~0x20));
          s.Append(val, 1, val.Length-1);
          return make(s.ToString());
        }
      }
      return this;
    }

    public Str decapitalize()
    {
      string val = this.val;
      if (val.Length > 0)
      {
        int ch = val[0];
        if ('A' <= ch && ch <= 'Z')
        {
          StringBuilder s = new StringBuilder(val.Length);
          s.Append((char)(ch | 0x20));
          s.Append(val, 1, val.Length-1);
          return make(s.ToString());
        }
      }
      return this;
    }

    public Str justl(Long width)
    {
      string val = this.val;
      int w = width.intValue();
      if (val.Length >= w) return this;
      StringBuilder s = new StringBuilder(w);
      s.Append(val);
      for (int i=val.Length; i<w; i++)
        s.Append(' ');
      return make(s.ToString());
    }

    public Str justr(Long width)
    {
      string val = this.val;
      int w = width.intValue();
      if (val.Length >= w) return this;
      StringBuilder s = new StringBuilder(w);
      for (int i=val.Length; i<w; i++)
        s.Append(' ');
      s.Append(val);
      return make(s.ToString());
    }

    public Str reverse()
    {
      string val = this.val;
      if (val.Length < 2) return this;
      StringBuilder s = new StringBuilder(val.Length);
      for (int i=val.Length-1; i>=0; i--)
        s.Append(val[i]);
      return make(s.ToString());
    }

    public Str trim()
    {
      string val = this.val;
      int len = val.Length;
      if (len == 0) return this;
      if (val[0] > ' ' && val[len-1] > ' ') return this;
      return make(val.Trim(m_trimChars));
    }

    public Str trimStart()
    {
      String val = this.val;
      int len = val.Length;
      if (len == 0) return this;
      if (val[0] > ' ') return this;
      int pos = 1;
      while (pos < len && val[pos] <= ' ') pos++;
      return make(val.Substring(pos, len-pos));
    }

    public Str trimEnd()
    {
      String val = this.val;
      int len = val.Length;
      if (len == 0) return this;
      int pos = len-1;
      if (val[pos] > ' ') return this;
      while (pos >= 0 && val[pos] <= ' ') pos--;
      return make(val.Substring(0, pos+1));
    }

    public List split() { return split(null, Boolean.True); }
    public List split(Long separator) { return split(separator, Boolean.True); }
    public List split(Long separator, Boolean trimmed)
    {
      String val = this.val;
      if (separator == null) return splitws(val);
      int sep = separator.intValue();
      bool trim = trimmed.booleanValue();
      List toks = new List(Sys.StrType, 16);
      int len = val.Length;
      int x = 0;
      for (int i=0; i<len; ++i)
      {
        if (val[i] != sep) continue;
        if (x <= i) toks.add(splitStr(val, x, i, trim));
        x = i+1;
      }
      if (x <= len) toks.add(splitStr(val, x, len, trim));
      return toks;
    }

    private static Str splitStr(String val, int s, int e, bool trim)
    {
      if (trim)
      {
        while (s < e && val[s] <= ' ') ++s;
        while (e > s && val[e-1] <= ' ') --e;
      }
      return Str.make(val.Substring(s, e-s));
    }

    public static List splitws(String val)
    {
      List toks = new List(Sys.StrType, 16);
      int len = val.Length;
      while (len > 0 && val[len-1] <= ' ') --len;
      int x = 0;
      while (x < len && val[x] <= ' ') ++x;
      for (int i=x; i<len; ++i)
      {
        if (val[i] > ' ') continue;
        toks.add(Str.make(val.Substring(x, i-x)));
        x = i + 1;
        while (x < len && val[x] <= ' ') ++x;
        i = x;
      }
      if (x <= len) toks.add(Str.make(val.Substring(x, len-x)));
      if (toks.sz() == 0) toks.add(Empty);
      return toks;
    }

    public List splitLines()
    {
      List lines = new List(Sys.StrType, 16);
      String val = this.val;
      int len = val.Length;
      int s = 0;
      for (int i=0; i<len; ++i)
      {
        int c = val[i];
        if (c == '\n' || c == '\r')
        {
          lines.add(make(val.Substring(s, i-s)));
          s = i+1;
          if (c == '\r' && s < len && val[s] == '\n') { i++; s++; }
        }
      }
      lines.add(make(val.Substring(s, len-s)));
      return lines;
    }

    public Str replace(Str from, Str to)
    {
      return make(StrUtil.Replace(val, from.val, to.val));
    }

    public Long numNewlines() { return Long.valueOf(numNewlines(val)); }
    public static int numNewlines(String val)
    {
      int numLines = 0;
      int len = val.Length;
      for (int i=0; i<len; ++i)
      {
        int c = val[i];
        if (c == '\n') numLines++;
        else if (c == '\r')
        {
          numLines++;
          if (i+1<len && val[i+1] == '\n') i++;
        }
      }
      return numLines;
    }

    public Boolean isAscii()
    {
      string val = this.val;
      int len = val.Length;
      for (int i=0; i<len; ++i)
        if (val[i] >= 128) return Boolean.False;
      return Boolean.True;
    }

    public Boolean isSpace()
    {
      string val = this.val;
      int len = val.Length;
      for (int i=0; i<len; i++)
      {
        int ch = val[i];
        if (ch >= 128 || (FanInt.charMap[ch] & FanInt.SPACE) == 0)
          return Boolean.False;
      }
      return Boolean.True;
    }

    public Boolean isUpper()
    {
      string val = this.val;
      int len = val.Length;
      for (int i=0; i<len; ++i)
      {
        int ch = val[i];
        if (ch >= 128 || (FanInt.charMap[ch] & FanInt.UPPER) == 0)
          return Boolean.False;
      }
      return Boolean.True;
    }

    public Boolean isLower()
    {
      string val = this.val;
      int len = val.Length;
      for (int i=0; i<len; ++i)
      {
        int ch = val[i];
        if (ch >= 128 || (FanInt.charMap[ch] & FanInt.LOWER) == 0)
          return Boolean.False;
      }
      return Boolean.True;
    }

    public bool isEveryChar(int ch)
    {
      string val = this.val;
      int len = val.Length;
      for (int i=0; i<len; ++i)
        if (val[i] != ch) return false;
      return true;
    }

  //////////////////////////////////////////////////////////////////////////
  // Locale
  //////////////////////////////////////////////////////////////////////////

    public Long localeCompare(Str x)
    {
      int cmp = String.Compare(val, x.val, true, Locale.current().net());
      if (cmp < 0) return FanInt.LT;
      return cmp == 0 ? FanInt.EQ : FanInt.GT;
    }

    public Str localeLower()
    {
      return make(val.ToLower(Locale.current().net()));
    }

    public Str localeUpper()
    {
      return make(val.ToUpper(Locale.current().net()));
    }

    public Str localeCapitalize()
    {
      string val = this.val;
      if (val.Length > 0)
      {
        int ch = val[0];
        if (Char.IsLower((char)ch))
        {
          StringBuilder s = new StringBuilder(val.Length);
          s.Append(Char.ToUpper((char)ch, Locale.current().net()));
          s.Append(val, 1, val.Length-1);
          return make(s.ToString());
        }
      }
      return this;
    }

    public Str localeDecapitalize()
    {
      string val = this.val;
      if (val.Length > 0)
      {
        int ch = val[0];
        if (Char.IsUpper((char)ch))
        {
          StringBuilder s = new StringBuilder(val.Length);
          s.Append(Char.ToLower((char)ch, Locale.current().net()));
          s.Append(val, 1, val.Length-1);
          return make(s.ToString());
        }
      }
      return this;
    }

  //////////////////////////////////////////////////////////////////////////
  // Conversion
  //////////////////////////////////////////////////////////////////////////

    public Boolean toBool() { return FanBool.fromStr(this, Boolean.True); }
    public Boolean toBool(Boolean check) { return FanBool.fromStr(this, check); }

    public Long toInt() { return FanInt.fromStr(this, FanInt.Ten, Boolean.True); }
    public Long toInt(Long radix) { return FanInt.fromStr(this, radix, Boolean.True); }
    public Long toInt(Long radix, Boolean check) { return FanInt.fromStr(this, radix, check); }

    public Double toFloat() { return FanFloat.fromStr(this, Boolean.True); }
    public Double toFloat(Boolean check) { return FanFloat.fromStr(this, check); }

    public BigDecimal toDecimal() { return FanDecimal.fromStr(this, Boolean.True); }
    public BigDecimal toDecimal(Boolean check) { return FanDecimal.fromStr(this, check); }

    public Uri toUri() { return Uri.fromStr(this); }

    public Str toCode() { return toCode(FanInt.m_pos['"'], Boolean.False); }
    public Str toCode(Long quote) { return toCode(quote, Boolean.False); }
    public Str toCode(Long quote, Boolean escapeUnicode)
    {
      StringBuilder s = new StringBuilder(val.Length+10);

      // opening quote
      bool escu = escapeUnicode.booleanValue();
      int q = 0;
      if (quote != null)
      {
        q = quote.intValue();
        s.Append((char)q);
      }

      // NOTE: these escape sequences are duplicated in ObjEncoder
      string v = this.val;
      int len = v.Length;
      for (int i=0; i<len; ++i)
      {
        int c = v[i];
        switch (c)
        {
          case '\n': s.Append('\\').Append('n'); break;
          case '\r': s.Append('\\').Append('r'); break;
          case '\f': s.Append('\\').Append('f'); break;
          case '\t': s.Append('\\').Append('t'); break;
          case '\\': s.Append('\\').Append('\\'); break;
          case '"':  if (q == '"')  s.Append('\\').Append('"');  else s.Append((char)c); break;
          case '`':  if (q == '`')  s.Append('\\').Append('`');  else s.Append((char)c); break;
          case '\'': if (q == '\'') s.Append('\\').Append('\''); else s.Append((char)c); break;
          case '$':  s.Append('\\').Append('$'); break;
          default:
            if (escu && c > 127)
            {
              s.Append('\\').Append('u')
               .Append((char)hex((c>>12)&0xf))
               .Append((char)hex((c>>8)&0xf))
               .Append((char)hex((c>>4)&0xf))
               .Append((char)hex(c&0xf));
            }
            else
            {
              s.Append((char)c);
            }
            break;
        }
      }

      // closing quote
      if (q != 0) s.Append((char)q);

      return make(s.ToString());
    }

    private int hex(int nib) { return "0123456789abcdef"[nib]; }

    public Str toXml()
    {
      StringBuilder s = null;
      string val = this.val;
      int len = val.Length;
      for (int i=0; i<len; ++i)
      {
        int c = val[i];
        if (c > '>')
        {
          if (s != null) s.Append((char)c);
        }
        else
        {
          string esc = m_xmlEsc[c];
          if (esc != null && (c != '>' || i==0 || val[i-1] == ']'))
          {
            if (s == null)
            {
              s = new StringBuilder(len+12);
              s.Append(val, 0, i);
            }
            s.Append(esc);
          }
          else if (s != null)
          {
            s.Append((char)c);
          }
        }
      }
      if (s == null) return this;
      return make(s.ToString());
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    public static readonly Str Empty   = new Str("");
    public static readonly Str nullStr = new Str("null");
    public static readonly Str sysStr  = new Str("sys");
    public static readonly Str thisStr = new Str("this");
    public static readonly Str uriStr  = new Str("uri");

    private static readonly Hashtable interns = new Hashtable();

    internal static readonly Str[] m_ascii = new Str[128];
    internal static Str[] m_spaces = new Str[20];
    internal static readonly char[] m_trimChars;
    internal static string[] m_xmlEsc = new string['>'+1];

    static Str()
    {
      // ascii
      for (int i=0; i<m_ascii.Length; i++)
        m_ascii[i] = make("" + (char)i).intern();

      // spaces
      StringBuilder s = new StringBuilder();
      for (int i=0; i<m_spaces.Length; i++)
      {
        m_spaces[i] = Str.make(s.ToString());
        s.Append(' ');
      }

      // trim chars
      m_trimChars = new char[0x20+1];
      for (int i=0; i<=0x20; i++)
        m_trimChars[i] = (char)i;

      // xml
      m_xmlEsc['&']  = "&amp;";
      m_xmlEsc['<']  = "&lt;";
      m_xmlEsc['>']  = "&gt;";
      m_xmlEsc['\''] = "&apos;";
      m_xmlEsc['"']  = "&quot;";
    }

    public readonly string val;
  }
}