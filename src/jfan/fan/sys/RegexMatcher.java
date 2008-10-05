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

  public final Long groupCount()
  {
    return Long.valueOf(matcher.groupCount());
  }

  public final Str group() { return group(0L); }
  public final Str group(Long group)
  {
    try
    {
      return Str.make(matcher.group(group.intValue()));
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

  public final Long start() { return start(0L); }
  public final Long start(Long group)
  {
    try
    {
      return Long.valueOf(matcher.start(group.intValue()));
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

  public final Long end() { return end(0L); }
  public final Long end(Long group)
  {
    try
    {
      return Long.valueOf(matcher.end(group.intValue()));
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
