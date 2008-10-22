//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   13 Sep 06  Andy Frank  Creation
//   21 Oct 08  Andy Frank  Refactor String into FanStr
//

using System;
using System.Collections;
using System.Text;
using System.Text.RegularExpressions;
using Fanx.Serial;
using Fanx.Util;

namespace Fan.Sys
{
  /// <summary>
  /// FanStr defines the methods for sys::string.  The actual
  /// class used for representation is F.lang.String.
  /// </summary>
  public sealed class FanStr
  {

  //////////////////////////////////////////////////////////////////////////
  // Construction
  //////////////////////////////////////////////////////////////////////////

    public static string makeTrim(StringBuilder s)
    {
      int start = 0;
      int end = s.Length;
      while (start < end) if (FanInt.isSpace(s[start])) start++; else break;
      while (end > start) if (FanInt.isSpace(s[end-1])) end--; else break;
      return s.ToString(start, end-start);
    }

  //////////////////////////////////////////////////////////////////////////
  // Identity
  //////////////////////////////////////////////////////////////////////////

    public static Boolean equals(string self, object obj)
    {
      if (obj is string)
        return self == (string)obj ? Boolean.True : Boolean.False;
      else
        return Boolean.False;
    }

    public static Boolean equalsIgnoreCase(string a, string b)
    {
      if (a == b) return Boolean.True;

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

    public static Long compare(string self, object obj)
    {
      int cmp = String.CompareOrdinal(self, (string)obj);
      if (cmp < 0) return FanInt.LT;
      return cmp == 0 ? FanInt.EQ : FanInt.GT;
    }

    public static Long compareIgnoreCase(string a, string b)
    {
      if (a == b) return FanInt.Zero;

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

    public static Long hash(string self)
    {
      return Long.valueOf(self.GetHashCode());
    }

    public static int caseInsensitiveHash(string self)
    {
      int n = self.Length;
      int hash = 0;

      for (int i=0; i<n; i++)
      {
        int c = self[i];
        if ('A' <= c && c <= 'Z') c |= 0x20;
        hash = 31*hash + c;
      }

      return hash;
    }

    public static string toStr(string self)
    {
      return self;
    }

    public static Type type(string self)
    {
      return Sys.StrType;
    }

  //////////////////////////////////////////////////////////////////////////
  // Operators
  //////////////////////////////////////////////////////////////////////////

    public static Long get(string self, Long index)
    {
      int i = index.intValue();
      if (i < 0) i = self.Length+i;
      return Long.valueOf(self[i]);
    }

    public static string slice(string self, Range r)
    {
      int size = self.Length;

      int s = r.start(size);
      int e = r.end(size);
      if (e+1 < s) throw IndexErr.make(r).val;

      return self.Substring(s, (e-s)+1);
    }

    public static string plus(string self, object obj)
    {
      if (obj == null) return String.Concat(self, "null");
      string x = FanObj.toStr(obj);
      if (x == "") return self;
      return String.Concat(self, x);
    }

  //////////////////////////////////////////////////////////////////////////
  // Identity
  //////////////////////////////////////////////////////////////////////////

    public static string intern(string self)
    {
      return String.Intern(self);
    }

    public static Boolean isEmpty(string self)
    {
      return self.Length == 0 ? Boolean.True : Boolean.False;
    }

    public static Long size(string self)
    {
      return Long.valueOf(self.Length);
    }

    public static Boolean startsWith(string self, string s)
    {
      return Boolean.valueOf(self.StartsWith(s));
    }

    public static Boolean endsWith(string self, string s)
    {
      return Boolean.valueOf(self.EndsWith(s));
    }

    public static Boolean contains(string self, string s)
    {
      return index(self, s, FanInt.Zero) != null ? Boolean.True : Boolean.False;
    }

    public static Boolean containsChar(string self, Long ch)
    {
      return self.IndexOf((char)ch.longValue()) >= 0 ? Boolean.True : Boolean.False;
    }

    public static Long index(string self, string s) { return index(self, s, FanInt.Zero); }
    public static Long index(string self, string s, Long off)
    {
      int i = off.intValue();
      if (i < 0) i = self.Length+i;

      int r;
      if (s.Length == 1)
        r = self.IndexOf(s[0], i);
      else
        r = self.IndexOf(s, i);

      if (r < 0) return null;
      return Long.valueOf(r);
    }

    public static Long indexr(string self, string s) { return indexr(self, s, FanInt.NegOne); }
    public static Long indexr(string self, string s, Long off)
    {
      int i = off.intValue();
      if (i < 0) i = self.Length+i;

      int r;
      if (s.Length == 1)
        r = self.LastIndexOf(s[0], i);
      else
      {
        // this doesn't match Java impl - so we have to roll
        // our own - prob alot of room for improvement...
        //r = val.LastIndexOf(sval, i, StringComparison.InvariantCulture);

        int len = self.Length;
        int slen = s.Length;
        if (len < slen) return null;
        r = -1;
        for (; i>=0; i--)
          if (nStartsWith(self, s, i))
            { r = i; break; }
      }

      if (r < 0) return null;
      return Long.valueOf(r);
    }

    public static Long indexIgnoreCase(string self, string s) { return indexIgnoreCase(self, s, FanInt.Zero); }
    public static Long indexIgnoreCase(string self, string s, Long off)
    {
      int vlen = self.Length, slen = s.Length;
      int r = -1;

      int i = off.intValue();
      if (i < 0) i = vlen+i;

      int first = s[0] | 0x20;
      for (; i<=vlen-slen; ++i)
      {
        // test first char
        if (first != (self[i] | 0x20)) continue;

        // test remainder of chars
        r = i;
        for (int si=1, vi=i+1; si<slen; ++si, ++vi)
          if ((s[si] | 0x20) != (self[vi] | 0x20))
            { r = -1; break; }
        if (r >= 0) break;
      }

      if (r < 0) return null;
      return Long.valueOf(r);
    }

    public static Long indexrIgnoreCase(string self, string s) { return indexrIgnoreCase(self, s, FanInt.NegOne); }
    public static Long indexrIgnoreCase(string self, string s, Long off)
    {
      int vlen = self.Length, slen = s.Length;
      int r = -1;

      int i = off.intValue();
      if (i < 0) i = vlen+i;
      if (i+slen >= vlen) i = vlen-slen;

      int first = s[0] | 0x20;
      for (; i>=0; --i)
      {
        // test first char
        if (first != (self[i] | 0x20)) continue;

        // test remainder of chars
        r = i;
        for (int si=1, vi=i+1; si<slen; ++si, ++vi)
          if ((s[si] | 0x20) != (self[vi] | 0x20))
            { r = -1; break; }
        if (r >= 0) break;
      }

      if (r < 0) return null;
      return Long.valueOf(r);
    }

    private static bool nStartsWith(string s, string pre, int off)
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

    public static void each(string self, Func f)
    {
      int len = self.Length;
      for (int i=0; i<len ; i++)
        f.call2(Long.valueOf(self[i]), Long.valueOf(i));
    }

    public static void eachr(string self, Func f)
    {
      for (int i=self.Length-1; i>=0; --i)
        f.call2(Long.valueOf(self[i]), Long.valueOf(i));
    }

    public static Boolean any(string self, Func f)
    {
      int len = self.Length;
      for (int i=0; i<len ; i++)
        if (f.call2(Long.valueOf(self[i]), Long.valueOf(i)) == Boolean.True)
          return Boolean.True;
      return Boolean.False;
    }

    public static Boolean all(string self, Func f)
    {
      int len = self.Length;
      for (int i=0; i<len ; i++)
        if (f.call2(Long.valueOf(self[i]), Long.valueOf(i)) == Boolean.False)
          return Boolean.False;
      return Boolean.True;
    }

  //////////////////////////////////////////////////////////////////////////
  // Utils
  //////////////////////////////////////////////////////////////////////////

    public static string spaces(Long n)
    {
      // do an array lookup for reasonable length
      // strings since that is the common case
      int count = n.intValue();
      try { return m_spaces[count]; } catch (IndexOutOfRangeException) {}

      // otherwise we build a new one
      StringBuilder s = new StringBuilder(m_spaces[m_spaces.Length-1]);
      for (int i=m_spaces.Length-1; i<count; i++)
        s.Append(' ');
      return s.ToString();
    }

    public static string lower(string self)
    {
      StringBuilder s = new StringBuilder(self.Length);
      for (int i=0; i<self.Length; i++)
      {
        int ch = self[i];
        if ('A' <= ch && ch <= 'Z') ch |= 0x20;
        s.Append((char)ch);
      }
      return s.ToString();
    }

    public static string upper(string self)
    {
      StringBuilder s = new StringBuilder(self.Length);
      for (int i=0; i<self.Length; i++)
      {
        int ch = self[i];
        if ('a' <= ch && ch <= 'z') ch &= ~0x20;
        s.Append((char)ch);
      }
      return s.ToString();
    }

    public static string capitalize(string self)
    {
      if (self.Length > 0)
      {
        int ch = self[0];
        if ('a' <= ch && ch <= 'z')
        {
          StringBuilder s = new StringBuilder(self.Length);
          s.Append((char)(ch & ~0x20));
          s.Append(self, 1, self.Length-1);
          return s.ToString();
        }
      }
      return self;
    }

    public static string decapitalize(string self)
    {
      if (self.Length > 0)
      {
        int ch = self[0];
        if ('A' <= ch && ch <= 'Z')
        {
          StringBuilder s = new StringBuilder(self.Length);
          s.Append((char)(ch | 0x20));
          s.Append(self, 1, self.Length-1);
          return s.ToString();
        }
      }
      return self;
    }

    public static string justl(string self, Long width)
    {
      int w = width.intValue();
      if (self.Length >= w) return self;
      StringBuilder s = new StringBuilder(w);
      s.Append(self);
      for (int i=self.Length; i<w; i++)
        s.Append(' ');
      return s.ToString();
    }

    public static string justr(string self, Long width)
    {
      int w = width.intValue();
      if (self.Length >= w) return self;
      StringBuilder s = new StringBuilder(w);
      for (int i=self.Length; i<w; i++)
        s.Append(' ');
      s.Append(self);
      return s.ToString();
    }

    public static string reverse(string self)
    {
      if (self.Length < 2) return self;
      StringBuilder s = new StringBuilder(self.Length);
      for (int i=self.Length-1; i>=0; i--)
        s.Append(self[i]);
      return s.ToString();
    }

    public static string trim(string self)
    {
      int len = self.Length;
      if (len == 0) return self;
      if (self[0] > ' ' && self[len-1] > ' ') return self;
      return self.Trim(m_trimChars);
    }

    public static string trimStart(string self)
    {
      int len = self.Length;
      if (len == 0) return self;
      if (self[0] > ' ') return self;
      int pos = 1;
      while (pos < len && self[pos] <= ' ') pos++;
      return self.Substring(pos, len-pos);
    }

    public static string trimEnd(string self)
    {
      int len = self.Length;
      if (len == 0) return self;
      int pos = len-1;
      if (self[pos] > ' ') return self;
      while (pos >= 0 && self[pos] <= ' ') pos--;
      return self.Substring(0, pos+1);
    }

    public static List split(string self) { return split(self, null, Boolean.True); }
    public static List split(string self, Long separator) { return split(self, separator, Boolean.True); }
    public static List split(string self, Long separator, Boolean trimmed)
    {
      if (separator == null) return splitws(self);
      int sep = separator.intValue();
      bool trim = trimmed.booleanValue();
      List toks = new List(Sys.StrType, 16);
      int len = self.Length;
      int x = 0;
      for (int i=0; i<len; ++i)
      {
        if (self[i] != sep) continue;
        if (x <= i) toks.add(splitStr(self, x, i, trim));
        x = i+1;
      }
      if (x <= len) toks.add(splitStr(self, x, len, trim));
      return toks;
    }

    private static string splitStr(String val, int s, int e, bool trim)
    {
      if (trim)
      {
        while (s < e && val[s] <= ' ') ++s;
        while (e > s && val[e-1] <= ' ') --e;
      }
      return val.Substring(s, e-s);
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
        toks.add(val.Substring(x, i-x));
        x = i + 1;
        while (x < len && val[x] <= ' ') ++x;
        i = x;
      }
      if (x <= len) toks.add(val.Substring(x, len-x));
      if (toks.sz() == 0) toks.add(Empty);
      return toks;
    }

    public static List splitLines(string self)
    {
      List lines = new List(Sys.StrType, 16);
      int len = self.Length;
      int s = 0;
      for (int i=0; i<len; ++i)
      {
        int c = self[i];
        if (c == '\n' || c == '\r')
        {
          lines.add(self.Substring(s, i-s));
          s = i+1;
          if (c == '\r' && s < len && self[s] == '\n') { i++; s++; }
        }
      }
      lines.add(self.Substring(s, len-s));
      return lines;
    }

    public static string replace(string self, string from, string to)
    {
      if (self.Length == 0) return self;
      return StrUtil.Replace(self, from, to);
    }

    public static Long numNewlines(string self)
    {
      int numLines = 0;
      int len = self.Length;
      for (int i=0; i<len; ++i)
      {
        int c = self[i];
        if (c == '\n') numLines++;
        else if (c == '\r')
        {
          numLines++;
          if (i+1<len && self[i+1] == '\n') i++;
        }
      }
      return Long.valueOf(numLines);
    }

    public static Boolean isAscii(string self)
    {
      int len = self.Length;
      for (int i=0; i<len; ++i)
        if (self[i] >= 128) return Boolean.False;
      return Boolean.True;
    }

    public static Boolean isSpace(string self)
    {
      int len = self.Length;
      for (int i=0; i<len; i++)
      {
        int ch = self[i];
        if (ch >= 128 || (FanInt.charMap[ch] & FanInt.SPACE) == 0)
          return Boolean.False;
      }
      return Boolean.True;
    }

    public static Boolean isUpper(string self)
    {
      int len = self.Length;
      for (int i=0; i<len; ++i)
      {
        int ch = self[i];
        if (ch >= 128 || (FanInt.charMap[ch] & FanInt.UPPER) == 0)
          return Boolean.False;
      }
      return Boolean.True;
    }

    public static Boolean isLower(string self)
    {
      int len = self.Length;
      for (int i=0; i<len; ++i)
      {
        int ch = self[i];
        if (ch >= 128 || (FanInt.charMap[ch] & FanInt.LOWER) == 0)
          return Boolean.False;
      }
      return Boolean.True;
    }

    public static bool isEveryChar(string self, int ch)
    {
      int len = self.Length;
      for (int i=0; i<len; ++i)
        if (self[i] != ch) return false;
      return true;
    }

  //////////////////////////////////////////////////////////////////////////
  // Locale
  //////////////////////////////////////////////////////////////////////////

    public static Long localeCompare(string self, string x)
    {
      int cmp = String.Compare(self, x, true, Locale.current().net());
      if (cmp < 0) return FanInt.LT;
      return cmp == 0 ? FanInt.EQ : FanInt.GT;
    }

    public static string localeLower(string self)
    {
      return self.ToLower(Locale.current().net());
    }

    public static string localeUpper(string self)
    {
      return self.ToUpper(Locale.current().net());
    }

    public static string localeCapitalize(string self)
    {
      if (self.Length > 0)
      {
        int ch = self[0];
        if (Char.IsLower((char)ch))
        {
          StringBuilder s = new StringBuilder(self.Length);
          s.Append(Char.ToUpper((char)ch, Locale.current().net()));
          s.Append(self, 1, self.Length-1);
          return s.ToString();
        }
      }
      return self;
    }

    public static string localeDecapitalize(string self)
    {
      if (self.Length > 0)
      {
        int ch = self[0];
        if (Char.IsUpper((char)ch))
        {
          StringBuilder s = new StringBuilder(self.Length);
          s.Append(Char.ToLower((char)ch, Locale.current().net()));
          s.Append(self, 1, self.Length-1);
          return s.ToString();
        }
      }
      return self;
    }

  //////////////////////////////////////////////////////////////////////////
  // Conversion
  //////////////////////////////////////////////////////////////////////////

    public static Boolean toBool(string self) { return FanBool.fromStr(self, Boolean.True); }
    public static Boolean toBool(string self, Boolean check) { return FanBool.fromStr(self, check); }

    public static Long toInt(string self) { return FanInt.fromStr(self, FanInt.Ten, Boolean.True); }
    public static Long toInt(string self, Long radix) { return FanInt.fromStr(self, radix, Boolean.True); }
    public static Long toInt(string self, Long radix, Boolean check) { return FanInt.fromStr(self, radix, check); }

    public static Double toFloat(string self) { return FanFloat.fromStr(self, Boolean.True); }
    public static Double toFloat(string self, Boolean check) { return FanFloat.fromStr(self, check); }

    public static BigDecimal toDecimal(string self) { return FanDecimal.fromStr(self, Boolean.True); }
    public static BigDecimal toDecimal(string self, Boolean check) { return FanDecimal.fromStr(self, check); }

    public static Uri toUri(string self) { return Uri.fromStr(self); }

    public static string toCode(string self) { return toCode(self, FanInt.m_pos['"'], Boolean.False); }
    public static string toCode(string self, Long quote) { return toCode(self, quote, Boolean.False); }
    public static string toCode(string self, Long quote, Boolean escapeUnicode)
    {
      StringBuilder s = new StringBuilder(self.Length+10);

      // opening quote
      bool escu = escapeUnicode.booleanValue();
      int q = 0;
      if (quote != null)
      {
        q = quote.intValue();
        s.Append((char)q);
      }

      // NOTE: these escape sequences are duplicated in ObjEncoder
      int len = self.Length;
      for (int i=0; i<len; ++i)
      {
        int c = self[i];
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

      return s.ToString();
    }

    private static int hex(int nib) { return "0123456789abcdef"[nib]; }

    public static string toXml(string self)
    {
      StringBuilder s = null;
      int len = self.Length;
      for (int i=0; i<len; ++i)
      {
        int c = self[i];
        if (c > '>')
        {
          if (s != null) s.Append((char)c);
        }
        else
        {
          string esc = m_xmlEsc[c];
          if (esc != null && (c != '>' || i==0 || self[i-1] == ']'))
          {
            if (s == null)
            {
              s = new StringBuilder(len+12);
              s.Append(self, 0, i);
            }
            s.Append(esc);
          }
          else if (s != null)
          {
            s.Append((char)c);
          }
        }
      }
      if (s == null) return self;
      return s.ToString();
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    public static readonly string Empty   = "";
    public static readonly string nullStr = "null";
    public static readonly string sysStr  = "sys";
    public static readonly string thisStr = "this";
    public static readonly string uriStr  = "uri";

    private static readonly Hashtable interns = new Hashtable();

    internal static readonly string[] m_ascii = new string[128];
    internal static string[] m_spaces = new string[20];
    internal static readonly char[] m_trimChars;
    internal static string[] m_xmlEsc = new string['>'+1];

    static FanStr()
    {
      // ascii
      for (int i=0; i<m_ascii.Length; i++)
        m_ascii[i] = String.Intern(""+(char)i);

      // spaces
      StringBuilder s = new StringBuilder();
      for (int i=0; i<m_spaces.Length; i++)
      {
        m_spaces[i] = s.ToString();
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

  }
}