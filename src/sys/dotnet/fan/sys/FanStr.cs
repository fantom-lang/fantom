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

    public static string fromChars(List chars)
    {
      if (chars.sz() == 0) return "";
      StringBuilder s = new StringBuilder(chars.sz());
      for (int i=0; i<chars.sz(); ++i)
        s.Append((char)((Long)chars.get(i)).longValue());
      return s.ToString();
    }

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

    public static bool equals(string self, object obj)
    {
      if (obj is string)
        return self == (string)obj;
      else
        return false;
    }

    public static bool equalsIgnoreCase(string a, string b)
    {
      if (a == b) return true;

      int an   = a.Length;
      int bn   = b.Length;
      if (an != bn) return false;

      for (int i=0; i<an; i++)
      {
        int ac = a[i];
        int bc = b[i];
        if ('A' <= ac && ac <= 'Z') ac |= 0x20;
        if ('A' <= bc && bc <= 'Z') bc |= 0x20;
        if (ac != bc) return false;
      }
      return true;
    }

    public static long compare(string self, object obj)
    {
      int cmp = String.CompareOrdinal(self, (string)obj);
      if (cmp < 0) return -1;
      return cmp == 0 ? 0 : +1;
    }

    public static long compareIgnoreCase(string a, string b)
    {
      if (a == b) return 0;

      int an   = a.Length;
      int bn   = b.Length;

      for (int i=0; i<an && i<bn; i++)
      {
        int ac = a[i];
        int bc = b[i];
        if ('A' <= ac && ac <= 'Z') ac |= 0x20;
        if ('A' <= bc && bc <= 'Z') bc |= 0x20;
        if (ac != bc) return ac < bc ? -1 : +1;
      }

      if (an == bn) return 0;
      return an < bn ? -1 : +1;
    }

    public static long hash(string self)
    {
      return self.GetHashCode();
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

    public static string toLocale(string self)
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

    public static long get(string self, long index)
    {
      try
      {
        int i = (int)index;
        if (i < 0) i = self.Length+i;
        return self[i];
      }
      catch (System.IndexOutOfRangeException)
      {
        throw IndexErr.make(index).val;
      }
    }

    public static long getSafe(String self, long index) { return getSafe(self, index, 0); }
    public static long getSafe(String self, long index, long def)
    {
      try
      {
        int i = (int)index;
        if (i < 0) i = self.Length+i;
        return self[i];
      }
      catch (System.IndexOutOfRangeException)
      {
        return def;
      }
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

    public static bool isEmpty(string self)
    {
      return self.Length == 0;
    }

    public static long size(string self)
    {
      return self.Length;
    }

    public static bool startsWith(string self, string s)
    {
      return self.StartsWith(s);
    }

    public static bool endsWith(string self, string s)
    {
      return self.EndsWith(s);
    }

    public static bool contains(string self, string s)
    {
      return index(self, s, 0) != null;
    }

    public static bool containsChar(string self, long ch)
    {
      return self.IndexOf((char)ch) >= 0;
    }

    public static Long index(string self, string s) { return index(self, s, 0); }
    public static Long index(string self, string s, long off)
    {
      int i = (int)off;
      if (i < 0) i = self.Length+i;

      int r;
      if (s.Length == 1)
        r = self.IndexOf(s[0], i);
      else
        r = self.IndexOf(s, i);

      if (r < 0) return null;
      return Long.valueOf(r);
    }

    public static Long indexr(string self, string s) { return indexr(self, s, -1); }
    public static Long indexr(string self, string s, long off)
    {
      int i = (int)off;
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

    public static Long indexIgnoreCase(string self, string s) { return indexIgnoreCase(self, s, 0); }
    public static Long indexIgnoreCase(string self, string s, long off)
    {
      int vlen = self.Length, slen = s.Length;
      int r = -1;

      int i = (int)off;
      if (i < 0) i = vlen+i;

      int first = s[0];
      for (; i<=vlen-slen; ++i)
      {
        // test first char
        if (neic(first, self[i])) continue;

        // test remainder of chars
        r = i;
        for (int si=1, vi=i+1; si<slen; ++si, ++vi)
          if (neic(s[si], self[vi]))
            { r = -1; break; }
        if (r >= 0) break;
      }

      if (r < 0) return null;
      return Long.valueOf(r);
    }

    public static Long indexrIgnoreCase(string self, string s) { return indexrIgnoreCase(self, s, -1); }
    public static Long indexrIgnoreCase(string self, string s, long off)
    {
      int vlen = self.Length, slen = s.Length;
      int r = -1;

      int i = (int)off;
      if (i < 0) i = vlen+i;
      if (i+slen >= vlen) i = vlen-slen;

      int first = s[0];
      for (; i>=0; --i)
      {
        // test first char
        if (neic(first, self[i])) continue;

        // test remainder of chars
        r = i;
        for (int si=1, vi=i+1; si<slen; ++si, ++vi)
          if (neic(s[si], self[vi]))
            { r = -1; break; }
        if (r >= 0) break;
      }

      if (r < 0) return null;
      return Long.valueOf(r);
    }

    private static bool neic(int a, int b)
    {
      if (a == b) return false;
      if ((a | 0x20) == (b | 0x20)) return FanInt.lower(a) != FanInt.lower(b);
      return true;
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

    public static List chars(string self)
    {
      int len = self.Length;
      if (len == 0) return Sys.IntType.emptyList();
      Long[] chars = new Long[len];
      for (int i=0; i<len; ++i) chars[i] = Long.valueOf(self[i]);
      return new List(Sys.IntType, chars);
    }

    public static void each(string self, Func f)
    {
      int len = self.Length;
      for (int i=0; i<len ; i++)
        f.call(self[i], i);
    }

    public static void eachr(string self, Func f)
    {
      for (int i=self.Length-1; i>=0; --i)
        f.call(self[i], i);
    }

    public static bool any(string self, Func f)
    {
      int len = self.Length;
      for (int i=0; i<len ; i++)
        if (f.call(self[i], i) == Boolean.True)
          return true;
      return false;
    }

    public static bool all(string self, Func f)
    {
      int len = self.Length;
      for (int i=0; i<len ; i++)
        if (f.call(self[i], i) == Boolean.False)
          return false;
      return true;
    }

  //////////////////////////////////////////////////////////////////////////
  // Utils
  //////////////////////////////////////////////////////////////////////////

    public static string spaces(long n)
    {
      // do an array lookup for reasonable length
      // strings since that is the common case
      int count = (int)n;
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

    public static string toDisplayName(string self)
    {
      if (self.Length == 0) return "";
      StringBuilder s = new StringBuilder(self.Length+4);

      // capitalize first word
      int c = self[0];
      if ('a' <= c && c <= 'z') c &= ~0x20;
      s.Append((char)c);

      // insert spaces before every capital
      int last = c;
      for (int i=1; i<self.Length; ++i)
      {
        c = self[i];
        if ('A' <= c && c <= 'Z' && last != '_')
        {
          int next = i+1 < self.Length ? self[i+1] : 'Q';
          if (!('A' <= last && last <= 'Z') || !('A' <= next && next <= 'Z'))
            s.Append(' ');
        }
        else if ('a' <= c && c <= 'z')
        {
          if ('0' <= last && last <= '9') { s.Append(' '); c &= ~0x20; }
          else if (last == '_') c &= ~0x20;
        }
        else if ('0' <= c && c <= '9')
        {
          if (!('0' <= last && last <= '9')) s.Append(' ');
        }
        else if (c == '_')
        {
          s.Append(' ');
          last = c;
          continue;
        }
        s.Append((char)c);
        last = c;
      }
      return s.ToString();
    }

    public static string fromDisplayName(string self)
    {
      if (self.Length == 0) return "";
      StringBuilder s = new StringBuilder(self.Length);
      int c = self[0];
      int c2 = self.Length == 1 ? 0 : self[1];
      if ('A' <= c && c <= 'Z' && !('A' <= c2 && c2 <= 'Z')) c |= 0x20;
      s.Append((char)c);
      int last = c;
      for (int i=1; i<self.Length; ++i)
      {
        c = self[i];
        if (c != ' ')
        {
          if (last == ' ' && 'a' <= c && c <= 'z') c &= ~0x20;
          s.Append((char)c);
        }
        last = c;
      }
      return s.ToString();
    }

    public static string justl(string self, long width)
    {
      return padr(self, width, ' ');
    }

    public static string justr(string self, long width)
    {
      return padl(self, width, ' ');
    }

    public static string padl(string self, long width) { return padl(self, width, ' '); }
    public static string padl(string self, long width, long ch)
    {
      int w = (int)width;
      if (self.Length >= w) return self;
      char c = (char)ch;
      StringBuilder s = new StringBuilder(w);
      for (int i=self.Length; i<w; i++) s.Append(c);
      s.Append(self);
      return s.ToString();
    }

    public static string padr(string self, long width) { return padr(self, width, ' '); }
    public static string padr(string self, long width, long ch)
    {
      int w = (int)width;
      if (self.Length >= w) return self;
      char c = (char)ch;
      StringBuilder s = new StringBuilder(w);
      s.Append(self);
      for (int i=self.Length; i<w; i++) s.Append(c);
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

    public static List split(string self) { return split(self, null, true); }
    public static List split(string self, Long separator) { return split(self, separator, true); }
    public static List split(string self, Long separator, bool trim)
    {
      if (separator == null) return splitws(self);
      int sep = separator.intValue();
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
      if (toks.sz() == 0) toks.add("");
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

    public static long numNewlines(string self)
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
      return numLines;
    }

    public static bool isAscii(string self)
    {
      int len = self.Length;
      for (int i=0; i<len; ++i)
        if (self[i] >= 128) return false;
      return true;
    }

    public static bool isSpace(string self)
    {
      int len = self.Length;
      for (int i=0; i<len; i++)
      {
        int ch = self[i];
        if (ch >= 128 || (FanInt.charMap[ch] & FanInt.SPACE) == 0)
          return false;
      }
      return true;
    }

    public static bool isUpper(string self)
    {
      int len = self.Length;
      for (int i=0; i<len; ++i)
      {
        int ch = self[i];
        if (ch >= 128 || (FanInt.charMap[ch] & FanInt.UPPER) == 0)
          return false;
      }
      return true;
    }

    public static bool isLower(string self)
    {
      int len = self.Length;
      for (int i=0; i<len; ++i)
      {
        int ch = self[i];
        if (ch >= 128 || (FanInt.charMap[ch] & FanInt.LOWER) == 0)
          return false;
      }
      return true;
    }

    public static bool isAlpha(string self)
    {
      int len = self.Length;
      for (int i=0; i<len; ++i)
      {
        int ch = self[i];
        if (ch >= 128 || (FanInt.charMap[ch] & FanInt.ALPHA) == 0)
          return false;
      }
      return true;
    }

    public static bool isAlphaNum(string self)
    {
      int len = self.Length;
      for (int i=0; i<len; ++i)
      {
        int ch = self[i];
        if (ch >= 128 || (FanInt.charMap[ch] & FanInt.ALPHANUM) == 0)
          return false;
      }
      return true;
    }

    public static bool isEveryChar(string self, int ch)
    {
      int len = self.Length;
      for (int i=0; i<len; ++i)
        if (self[i] != ch) return false;
      return true;
    }

    public static InStream @in(string self)
    {
      return new StrInStream(self);
    }

    public static Buf toBuf(string self) { return toBuf(self, Charset.m_utf8); }
    public static Buf toBuf(string self, Charset charset)
    {
      MemBuf buf = new MemBuf(self.Length*2);
      buf.charset(charset);
      buf.print(self);
      return buf.flip();
    }

  //////////////////////////////////////////////////////////////////////////
  // Locale
  //////////////////////////////////////////////////////////////////////////

    public static long localeCompare(string self, string x)
    {
      int cmp = String.Compare(self, x, true, Locale.cur().dotnet());
      if (cmp < 0) return -1;
      return cmp == 0 ? 0 : +1;
    }

    public static string localeLower(string self)
    {
      return self.ToLower(Locale.cur().dotnet());
    }

    public static string localeUpper(string self)
    {
      return self.ToUpper(Locale.cur().dotnet());
    }

    public static string localeCapitalize(string self)
    {
      if (self.Length > 0)
      {
        int ch = self[0];
        if (Char.IsLower((char)ch))
        {
          StringBuilder s = new StringBuilder(self.Length);
          s.Append(Char.ToUpper((char)ch, Locale.cur().dotnet()));
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
          s.Append(Char.ToLower((char)ch, Locale.cur().dotnet()));
          s.Append(self, 1, self.Length-1);
          return s.ToString();
        }
      }
      return self;
    }

  //////////////////////////////////////////////////////////////////////////
  // Conversion
  //////////////////////////////////////////////////////////////////////////

    public static Boolean toBool(string self) { return FanBool.fromStr(self, true); }
    public static Boolean toBool(string self, bool check) { return FanBool.fromStr(self, check); }

    public static Long toInt(string self) { return FanInt.fromStr(self, 10, true); }
    public static Long toInt(string self, long radix) { return FanInt.fromStr(self, radix, true); }
    public static Long toInt(string self, long radix, bool check) { return FanInt.fromStr(self, radix, check); }

    public static Double toFloat(string self) { return FanFloat.fromStr(self, true); }
    public static Double toFloat(string self, bool check) { return FanFloat.fromStr(self, check); }

    public static BigDecimal toDecimal(string self) { return FanDecimal.fromStr(self, true); }
    public static BigDecimal toDecimal(string self, bool check) { return FanDecimal.fromStr(self, check); }

    public static Uri toUri(string self) { return Uri.fromStr(self); }

    public static string toCode(string self) { return toCode(self, Long.valueOf('"'), false); }
    public static string toCode(string self, Long quote) { return toCode(self, quote, false); }
    public static string toCode(string self, Long quote, bool escapeUnicode)
    {
      StringBuilder s = new StringBuilder(self.Length+10);

      // opening quote
      bool escu = escapeUnicode;
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

    private static readonly Hashtable interns = new Hashtable();

    public static readonly string m_defVal = "";

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