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

    public override Type @typeof() { return Sys.RegexMatcherType; }

  //////////////////////////////////////////////////////////////////////////
  // Methods
  //////////////////////////////////////////////////////////////////////////

    public bool matches()
    {
      // to match java
      return (m_match.Success) ? m_source.Length == m_match.Length : false;
    }

    public bool find()
    {
      return true; //matcher.find());
    }

    public long groupCount()
    {
      // to match java
      return m_match.Groups.Count-1;
    }

    public string group() { return group(0); }
    public string group(long group)
    {
      // to match java
      if (!matches()) throw new System.Exception();
      if (group < 0 || group >= m_match.Groups.Count)
        throw IndexErr.make(group).val;

      return m_match.Groups[(int)group].Value;
    }

    public long start() { return start(0); }
    public long start(long group)
    {
      // to match java
      if (!matches()) throw new System.Exception();
      if (group < 0 || group >= m_match.Groups.Count)
        throw IndexErr.make(group).val;

      return m_match.Groups[(int)group].Index;
    }

    public long end() { return end(0); }
    public long end(long group)
    {
      // to match java
      if (!matches()) throw new System.Exception();
      if (group < 0 || group >= m_match.Groups.Count)
        throw IndexErr.make(group).val;

      Group g = m_match.Groups[(int)group];
      return g.Index + g.Length;
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    Match m_match;
    string m_source;

  }
}