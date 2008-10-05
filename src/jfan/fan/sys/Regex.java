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

  public static final Regex fromStr(Str pattern)
  {
    return new Regex(pattern);
  }

  Regex(Str source)
  {
    this.source  = source;
    this.pattern = Pattern.compile(source.val);
  }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  public final Boolean _equals(Object obj)
  {
    if (obj instanceof Regex)
      return ((Regex)obj).source._equals(this.source);
    else
      return false;
  }

  public final int hashCode() { return source.hashCode(); }

  public final Long hash() { return source.hash(); }

  public Str toStr() { return source; }

  public Type type() { return Sys.RegexType; }

//////////////////////////////////////////////////////////////////////////
// Regular expression
//////////////////////////////////////////////////////////////////////////

  public Boolean matches(Str s)
  {
    return pattern.matcher(s.val).matches();
  }

  public RegexMatcher matcher(Str s)
  {
    return new RegexMatcher(pattern.matcher(s.val));
  }

  public List split(Str s) { return split(s, 0L); }
  public List split(Str s, Long limit)
  {
    return new List(pattern.split(s.val, limit.intValue()));
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private Str source;
  private Pattern pattern;
}
