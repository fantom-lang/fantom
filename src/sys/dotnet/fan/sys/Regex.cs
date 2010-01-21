//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Dec 07  Andy Frank  Creation
//

using System.Text;
using System.Text.RegularExpressions;
using NRegex = System.Text.RegularExpressions.Regex;

namespace Fan.Sys
{
  /// <summary>
  /// Regex
  /// </summary>
  public sealed class Regex : FanObj
  {

  //////////////////////////////////////////////////////////////////////////
  // Constructors
  //////////////////////////////////////////////////////////////////////////

    public static Regex fromStr(string pattern)
    {
      return new Regex(pattern);
    }

    public static Regex glob(string pattern)
    {
      StringBuilder s = new StringBuilder();
      for (int i=0; i<pattern.Length; ++i)
      {
        int c = pattern[i];
        if (FanInt.isAlphaNum(c)) s.Append((char)c);
        else if (c == '?') s.Append('.');
        else if (c == '*') s.Append('.').Append('*');
        else s.Append('\\').Append((char)c);
      }
      return new Regex(s.ToString());
    }

    Regex(string source)
    {
      this.m_source  = source;
      this.m_pattern = new NRegex(source);
    }

  //////////////////////////////////////////////////////////////////////////
  // Identity
  //////////////////////////////////////////////////////////////////////////

    public sealed override bool Equals(object obj)
    {
      if (obj is Regex)
        return ((Regex)obj).m_source == this.m_source;
      else
        return false;
    }

    public sealed override int GetHashCode() { return m_source.GetHashCode(); }

    public sealed override long hash() { return FanStr.hash(m_source); }

    public override string toStr() { return m_source; }

    public override Type @typeof() { return Sys.RegexType; }

  //////////////////////////////////////////////////////////////////////////
  // Regular expression
  //////////////////////////////////////////////////////////////////////////

    public bool matches(string s)
    {
      return new RegexMatcher(m_pattern.Match(s), s).matches();
    }

    public RegexMatcher matcher(string s)
    {
      return new RegexMatcher(m_pattern.Match(s), s);
    }

    public List split(string s) { return split(s, 0); }
    public List split(string s, long limit)
    {
      int l = (limit < 0) ? 0 : (int)limit;
      List result = new List(m_pattern.Split(s, l));

      // to match java we need to discard any trailing
      // emptys strings (use limit, not l)
      if (limit == 0)
        while (result.sz() > 0 && (result.last() as string).Length == 0)
          result.pop();

      return result;
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    private string m_source;
    private NRegex m_pattern;

  }
}