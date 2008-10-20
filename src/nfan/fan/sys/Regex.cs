//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Dec 07  Andy Frank  Creation
//

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

    public static Regex fromStr(Str pattern)
    {
      return new Regex(pattern);
    }

    Regex(Str source)
    {
      this.m_source  = source;
      this.m_pattern = new NRegex(source.val);
    }

  //////////////////////////////////////////////////////////////////////////
  // Identity
  //////////////////////////////////////////////////////////////////////////

    public sealed override Boolean _equals(object obj)
    {
      if (obj is Regex)
        return ((Regex)obj).m_source._equals(this.m_source);
      else
        return Boolean.False;
    }

    public sealed override int GetHashCode() { return m_source.GetHashCode(); }

    public sealed override Long hash() { return m_source.hash(); }

    public override Str toStr() { return m_source; }

    public override Type type() { return Sys.RegexType; }

  //////////////////////////////////////////////////////////////////////////
  // Regular expression
  //////////////////////////////////////////////////////////////////////////

    public Boolean matches(Str s)
    {
      return new RegexMatcher(m_pattern.Match(s.val), s).matches();
    }

    public RegexMatcher matcher(Str s)
    {
      return new RegexMatcher(m_pattern.Match(s.val), s);
    }

    public List split(Str s) { return split(s, FanInt.Zero); }
    public List split(Str s, Long limit)
    {
      int l = (limit.longValue() < 0) ? 0 : limit.intValue();
      List result = new List(m_pattern.Split(s.val, l));

      // to match java we need to discard any trailing
      // emptys strings (use limit, not l)
      if (limit.longValue() == 0)
        while (result.sz() > 0 && (result.last() as Str).val.Length == 0)
          result.pop();

      return result;
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    private Str m_source;
    private NRegex m_pattern;

  }
}