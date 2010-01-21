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

  public static Version fromStr(String str) { return fromStr(str, true); }
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
        segments.add(Long.valueOf(seg));
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
    if (seg >= 0) segments.add(Long.valueOf(seg));

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
      if (((Long)segments.get(i)).longValue() < 0) valid = false;
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

  public boolean equals(Object obj)
  {
    if (obj instanceof Version)
      return toStr().equals(((Version)obj).toStr());
    else
      return false;
  }

  public long compare(Object obj)
  {
    Version that = (Version)obj;
    List a = this.segments;
    List b = that.segments;
    for (int i=0; i<a.sz() && i<b.sz(); ++i)
    {
      long ai = (Long)a.get(i);
      long bi = (Long)b.get(i);
      if (ai < bi) return -1;
      if (ai > bi) return +1;
    }
    if (a.sz() < b.sz()) return -1;
    if (a.sz() > b.sz()) return +1;
    return 0;
  }

  public int hashCode()
  {
    return toStr().hashCode();
  }

  public long hash()
  {
    return FanStr.hash(toStr());
  }

  public Type typeof()
  {
    return Sys.VersionType;
  }

  public String toStr()
  {
    if (str == null)
    {
      StringBuilder s = new StringBuilder();
      for (int i=0; i<segments.sz(); ++i)
      {
        if (i > 0) s.append('.');
        s.append(segments.get(i));
      }
      str = s.toString();
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
    return ((Long)segments.get(index)).intValue();
  }

  public long major()
  {
    return (Long)segments.get(0);
  }

  public Long minor()
  {
    if (segments.sz() < 2) return null;
    return (Long)segments.get(1);
  }

  public Long build()
  {
    if (segments.sz() < 3) return null;
    return (Long)segments.get(2);
  }

  public Long patch()
  {
    if (segments.sz() < 4) return null;
    return (Long)segments.get(3);
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  public static final Version defVal = fromStr("0");

  private final List segments;
  private String str;

}