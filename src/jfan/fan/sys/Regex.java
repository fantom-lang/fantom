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

  public final Bool _equals(Obj obj)
  {
    if (obj instanceof Regex)
      return ((Regex)obj).source._equals(this.source);
    else
      return Bool.False;
  }

  public final int hashCode() { return source.hashCode(); }

  public final Int hash() { return source.hash(); }

  public Str toStr() { return source; }

  public Type type() { return Sys.RegexType; }

//////////////////////////////////////////////////////////////////////////
// Regular expression
//////////////////////////////////////////////////////////////////////////

  public Bool matches(Str s)
  {
    return Bool.make(pattern.matcher(s.val).matches());
  }

  public RegexMatcher matcher(Str s)
  {
    return new RegexMatcher(pattern.matcher(s.val));
  }

  public List split(Str s) { return split(s, Int.Zero); }
  public List split(Str s, Int limit)
  {
    return new List(pattern.split(s.val, (int)limit.val));
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private Str source;
  private Pattern pattern;
}