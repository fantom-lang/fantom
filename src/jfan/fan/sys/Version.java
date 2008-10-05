//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Jul 06  Brian Frank  Creation
//
package fan.sys;

import java.util.*;

/**
 * Version
 */
public final class Version
  extends FanObj
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  public static Version fromStr(Str str) { return fromStr(str.val, true); }
  public static Version fromStr(Str str, Boolean checked) { return fromStr(str.val, checked.booleanValue()); }
  public static Version fromStr(String s) { return fromStr(s, true); }
  public static Version fromStr(String s, boolean checked)
  {
    List segments = new List(Sys.IntType, 4);
    int seg = -1;
    boolean valid = true;
    int len = s.length();
    for (int i=0; i<len; ++i)
    {
      int c = s.charAt(i);
      if (c == '.')
      {
        if (seg < 0 || i+1>=len) { valid = false; break; }
        segments.add(Int.pos(seg));
        seg = -1;
      }
      else
      {
        if ('0' <= c && c <= '9')
        {
          if (seg < 0) seg = c-'0';
          else seg = seg*10 + (c-'0');
        }
        else
        {
          valid = false; break;
        }
      }
    }
    if (seg >= 0) segments.add(Int.pos(seg));

    if (!valid || segments.sz() == 0)
    {
      if (checked)
        throw ParseErr.make("Version", s).val;
      else
        return null;
    }

    return new Version(segments);
  }

  public static Version make(List segments)
  {
    boolean valid = segments.sz() > 0;
    for (int i=0; i<segments.sz(); ++i)
      if (((Int)segments.get(i)).val < 0) valid = false;
    if (!valid) throw ArgErr.make("Invalid Version: '" + segments + "'").val;
    return new Version(segments);
  }

  Version(List segments)
  {
    this.segments = segments.ro();
  }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  public Boolean _equals(Object obj)
  {
    if (obj instanceof Version)
      return toStr()._equals(((Version)obj).toStr());
    else
      return false;
  }

  public Int compare(Object obj)
  {
    Version that = (Version)obj;
    List a = this.segments;
    List b = that.segments;
    for (int i=0; i<a.sz() && i<b.sz(); ++i)
    {
      long ai = ((Int)a.get(i)).val;
      long bi = ((Int)b.get(i)).val;
      if (ai < bi) return Int.LT;
      if (ai > bi) return Int.GT;
    }
    if (a.sz() < b.sz()) return Int.LT;
    if (a.sz() > b.sz()) return Int.GT;
    return Int.EQ;
  }

  public int hashCode()
  {
    return toStr().hashCode();
  }

  public Int hash()
  {
    return toStr().hash();
  }

  public Type type()
  {
    return Sys.VersionType;
  }

  public Str toStr()
  {
    if (str == null)
    {
      StringBuilder s = new StringBuilder();
      for (int i=0; i<segments.sz(); ++i)
      {
        if (i > 0) s.append('.');
        s.append(((Int)segments.get(i)).val);
      }
      str = Str.make(s.toString());
    }
    return str;
  }

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  public List segments()
  {
    return segments;
  }

  public int segment(int index)
  {
    return (int)((Int)segments.get(index)).val;
  }

  public Int major()
  {
    return (Int)segments.get(0);
  }

  public Int minor()
  {
    if (segments.sz() < 2) return null;
    return (Int)segments.get(1);
  }

  public Int build()
  {
    if (segments.sz() < 3) return null;
    return (Int)segments.get(2);
  }

  public Int patch()
  {
    if (segments.sz() < 4) return null;
    return (Int)segments.get(3);
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private final List segments;
  private Str str;

}