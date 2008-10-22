//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Dec 07  Andy Frank  Creation
//

using System.Text.RegularExpressions;

namespace Fan.Sys
{
  /// <summary>
  /// RegexMatcher
  /// </summary>
  public sealed class RegexMatcher : FanObj
  {

  //////////////////////////////////////////////////////////////////////////
  // Constructors
  //////////////////////////////////////////////////////////////////////////

    internal RegexMatcher(Match match, string source)
    {
      this.m_match = match;
      this.m_source = source;
    }

  //////////////////////////////////////////////////////////////////////////
  // Identity
  //////////////////////////////////////////////////////////////////////////

    public override Type type() { return Sys.RegexMatcherType; }

  //////////////////////////////////////////////////////////////////////////
  // Methods
  //////////////////////////////////////////////////////////////////////////

    public Boolean matches()
    {
      // to match java
      return (m_match.Success)
        ? Boolean.valueOf(m_source.Length == m_match.Length) : Boolean.False;
    }

    public Boolean find()
    {
      return Boolean.valueOf(true); //matcher.find());
    }

    public Long groupCount()
    {
      // to match java
      return Long.valueOf(m_match.Groups.Count-1);
    }

    public string group() { return group(FanInt.Zero); }
    public string group(Long group)
    {
      // to match java
      if (!matches().booleanValue()) throw new System.Exception();
      if (group.longValue() < 0 || group.longValue() >= m_match.Groups.Count)
        throw IndexErr.make(group).val;

      return m_match.Groups[group.intValue()].Value;
    }

    public Long start() { return start(FanInt.Zero); }
    public Long start(Long group)
    {
      // to match java
      if (!matches().booleanValue()) throw new System.Exception();
      if (group.longValue() < 0 || group.longValue() >= m_match.Groups.Count)
        throw IndexErr.make(group).val;

      return Long.valueOf(m_match.Groups[group.intValue()].Index);
    }

    public Long end() { return end(FanInt.Zero); }
    public Long end(Long group)
    {
      // to match java
      if (!matches().booleanValue()) throw new System.Exception();
      if (group.longValue() < 0 || group.longValue() >= m_match.Groups.Count)
        throw IndexErr.make(group).val;

      Group g = m_match.Groups[group.intValue()];
      return Long.valueOf(g.Index + g.Length);
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    Match m_match;
    string m_source;

  }
}