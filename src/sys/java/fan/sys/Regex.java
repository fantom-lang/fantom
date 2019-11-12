//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   26 Dec 07  Brian Frank  Creation
//
package fan.sys;

import java.util.regex.*;

/**
 * Regex
 */
public final class Regex
  extends FanObj
{

//////////////////////////////////////////////////////////////////////////
// Constructors
//////////////////////////////////////////////////////////////////////////

  public static Regex fromStr(String pattern) { return fromStr(pattern, ""); }
  public static Regex fromStr(String pattern, String flags)
  {
    return new Regex(pattern, flags);
  }

  public static Regex glob(String pattern)
  {
    StringBuilder s = new StringBuilder();
    for (int i=0; i<pattern.length(); ++i)
    {
      int c = pattern.charAt(i);
      if (FanInt.isAlphaNum(c)) s.append((char)c);
      else if (c == '?') s.append('.');
      else if (c == '*') s.append('.').append('*');
      else s.append('\\').append((char)c);
    }
    return new Regex(s.toString(), "");
  }

  public static Regex quote(String str)
  {
    StringBuilder s = new StringBuilder();
    for (int i=0; i<str.length(); ++i)
    {
      int c = str.charAt(i);
      if (FanInt.isAlphaNum(c)) s.append((char)c);
      else s.append('\\').append((char)c);
    }
    return new Regex(s.toString(), "");
  }

  Regex(String source, String flags)
  {
    this.source  = source;
    this.pattern = Pattern.compile(source, parseFlags(flags));
    this.flags   = flags;
  }

  private static int parseFlags(String s)
  {
    int flags = 0;
    for (int i = 0; i<s.length(); ++i)
    {
      switch (s.charAt(i))
      {
        case 'i': flags |= Pattern.CASE_INSENSITIVE; break;
        case 'm': flags |= Pattern.MULTILINE; break;
        case 's': flags |= Pattern.DOTALL; break;
      }
    }
    return flags;
  }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  public final boolean equals(Object obj)
  {
    if (obj instanceof Regex)
    {
      Regex that = (Regex)obj;
      return this.source.equals(that.source) && this.flags.equals(that.flags);
    }
    else
    {
      return false;
    }
  }

  public final int hashCode() { return source.hashCode(); }

  public final long hash() { return FanStr.hash(source); }

  public String flags() { return flags; }

  public String toStr() { return source; }

  public Type typeof() { return Sys.RegexType; }

//////////////////////////////////////////////////////////////////////////
// Regular expression
//////////////////////////////////////////////////////////////////////////

  public boolean matches(String s)
  {
    return pattern.matcher(s).matches();
  }

  public RegexMatcher matcher(String s)
  {
    return new RegexMatcher(pattern.matcher(s));
  }

  public List split(String s) { return split(s, 0L); }
  public List split(String s, long limit)
  {
    return new List(pattern.split(s, (int)limit));
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  public static final Regex defVal = new Regex("", "");

  private String source;
  private Pattern pattern;
  private String flags;
}