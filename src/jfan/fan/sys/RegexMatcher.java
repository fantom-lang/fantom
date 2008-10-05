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
 * RegexMatcher
 */
public final class RegexMatcher
  extends FanObj
{

//////////////////////////////////////////////////////////////////////////
// Constructors
//////////////////////////////////////////////////////////////////////////

  RegexMatcher(Matcher matcher)
  {
    this.matcher = matcher;
  }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  public Type type() { return Sys.RegexMatcherType; }

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  public final Boolean matches()
  {
    return matcher.matches();
  }

  public final Boolean find()
  {
    return matcher.find();
  }

  public final Int groupCount()
  {
    return Int.make(matcher.groupCount());
  }

  public final Str group() { return group(Int.Zero); }
  public final Str group(Int group)
  {
    try
    {
      return Str.make(matcher.group((int)group.val));
    }
    catch (IllegalStateException e)
    {
      throw Err.make(e.getMessage()).val;
    }
    catch (IndexOutOfBoundsException e)
    {
      throw IndexErr.make(group).val;
    }
  }

  public final Int start() { return start(Int.Zero); }
  public final Int start(Int group)
  {
    try
    {
      return Int.make(matcher.start((int)group.val));
    }
    catch (IllegalStateException e)
    {
      throw Err.make(e.getMessage()).val;
    }
    catch (IndexOutOfBoundsException e)
    {
      throw IndexErr.make(group).val;
    }
  }

  public final Int end() { return end(Int.Zero); }
  public final Int end(Int group)
  {
    try
    {
      return Int.make(matcher.end((int)group.val));
    }
    catch (IllegalStateException e)
    {
      throw Err.make(e.getMessage()).val;
    }
    catch (IndexOutOfBoundsException e)
    {
      throw IndexErr.make(group).val;
    }
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  Matcher matcher;
}