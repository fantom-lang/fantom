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

  public static final Regex fromStr(String pattern)
  {
    return new Regex(pattern);
  }

  Regex(String source)
  {
    this.source  = source;
    this.pattern = Pattern.compile(source);
  }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  public final boolean _equals(Object obj)
  {
    if (obj instanceof Regex)
      return ((Regex)obj).source.equals(this.source);
    else
      return false;
  }

  public final int hashCode() { return source.hashCode(); }

  public final Long hash() { return FanStr.hash(source); }

  public String toStr() { return source; }

  public Type type() { return Sys.RegexType; }

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
  public List split(String s, Long limit)
  {
    return new List(pattern.split(s, limit.intValue()));
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private String source;
  private Pattern pattern;
}
