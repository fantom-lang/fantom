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

    internal RegexMatcher(Match match, Str source)
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

    public Bool matches()
    {
      // to match java
      return (m_match.Success)
        ? Bool.make(m_source.val.Length == m_match.Length) : Bool.False;
    }

    public Bool find()
    {
      return Bool.make(true); //matcher.find());
    }

    public Int groupCount()
    {
      // to match java
      return Int.make(m_match.Groups.Count-1);
    }

    public Str group() { return group(Int.Zero); }
    public Str group(Int group)
    {
      // to match java
      if (!matches().val) throw new System.Exception();
      if (group.val < 0 || group.val >= m_match.Groups.Count)
        throw IndexErr.make(group).val;

      return Str.make(m_match.Groups[(int)group.val].Value);
    }

    public Int start() { return start(Int.Zero); }
    public Int start(Int group)
    {
      // to match java
      if (!matches().val) throw new System.Exception();
      if (group.val < 0 || group.val >= m_match.Groups.Count)
        throw IndexErr.make(group).val;

      return Int.make(m_match.Groups[(int)group.val].Index);
    }

    public Int end() { return end(Int.Zero); }
    public Int end(Int group)
    {
      // to match java
      if (!matches().val) throw new System.Exception();
      if (group.val < 0 || group.val >= m_match.Groups.Count)
        throw IndexErr.make(group).val;

      Group g = m_match.Groups[(int)group.val];
      return Int.make(g.Index + g.Length);
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    Match m_match;
    Str m_source;

  }
}