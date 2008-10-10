//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   3 Nov 06  Brian Frank  Creation
//
package fan.sys;

import java.util.*;

/**
 * Depend
 */
public final class Depend
  extends FanObj
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  public static Depend fromStr(String str) { return fromStr(str, true); }
  public static Depend fromStr(String str, Boolean checked)
  {
    try
    {
      return new Parser(str).parse();
    }
    catch (Throwable e)
    {
      if (!checked) return null;
      throw ParseErr.make("Depend", str).val;
    }
  }

  private Depend(String name, Constraint[] constraints)
  {
    this.name = name;
    this.constraints = constraints;
  }

//////////////////////////////////////////////////////////////////////////
// Parser
//////////////////////////////////////////////////////////////////////////

  static class Parser
  {
    Parser(String str)
    {
      this.str = str;
      this.len = str.length();
      consume();
    }

    Depend parse()
    {
      name = name();
      constraints.add(constraint());
      while (cur == ',')
      {
        consume();
        consumeSpaces();
        constraints.add(constraint());
      }
      if (pos <= len) throw new RuntimeException();
      return new Depend(name, (Constraint[])constraints .toArray(new Constraint[constraints.size()]));
    }

    private String name()
    {
      StringBuilder s = new StringBuilder();
      while (cur != ' ')
      {
        if (cur < 0) throw new RuntimeException();
        s.append((char)cur);
        consume();
      }
      consumeSpaces();
      if (s.length() == 0) throw new RuntimeException();
      return s.toString();
    }

    private Constraint constraint()
    {
      Constraint c = new Constraint();
      c.version = version();
      consumeSpaces();
      if (cur == '+')
      {
        c.isPlus = true;
        consume();
        consumeSpaces();
      }
      else if (cur == '-')
      {
        consume();
        consumeSpaces();
        c.endVersion = version();
        consumeSpaces();
      }
      return c;
    }

    private Version version()
    {
      List segs = new List(Sys.IntType, 4);
      int seg = consumeDigit();
      while (true)
      {
        if ('0' <= cur && cur <= '9')
        {
          seg = seg*10 + consumeDigit();
        }
        else
        {
          segs.add(Long.valueOf(seg));
          seg = 0;
          if (cur != '.') break;
          else consume();
        }
      }
      return new Version(segs);
    }

    private int consumeDigit()
    {
      if ('0' <= cur && cur <= '9')
      {
        int digit = cur - '0';
        consume();
        return digit;
      }
      throw new RuntimeException();
    }

    private void consumeSpaces()
    {
      while (cur == ' ') consume();
    }

    private void consume()
    {
      if (pos < len)
      {
        cur = str.charAt(pos++);
      }
      else
      {
        cur = -1;
        pos = len+1;
      }
    }

    int cur;
    int pos;
    int len;
    String str;
    String name;
    ArrayList constraints = new ArrayList(4);
  }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  public Boolean _equals(Object obj)
  {
    if (obj instanceof Depend)
      return toStr().equals(toStr(obj));
    else
      return false;
  }

  public int hashCode()
  {
    return toStr().hashCode();
  }

  public Long hash()
  {
    return FanStr.hash(toStr());
  }

  public Type type()
  {
    return Sys.DependType;
  }

  public String toStr()
  {
    if (str == null)
    {
      StringBuilder s = new StringBuilder();
      s.append(name).append(' ');
      for (int i=0; i<constraints.length; ++i)
      {
        if (i > 0) s.append(',');
        Constraint c = constraints[i];
        s.append(c.version);
        if (c.isPlus) s.append('+');
        if (c.endVersion != null) s.append('-').append(c.endVersion);
      }
      str = s.toString();
    }
    return str;
  }

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  public final String name()
  {
    return name;
  }

  public final Long size()
  {
    return Long.valueOf(constraints.length);
  }

  public final Version version() { return version(0L); }
  public final Version version(Long index)
  {
    return constraints[index.intValue()].version;
  }

  public final Boolean isPlus() { return isPlus(0L); }
  public final Boolean isPlus(Long index)
  {
    return constraints[index.intValue()].isPlus;
  }

  public final Boolean isRange() { return isRange(0L); }
  public final Boolean isRange(Long index)
  {
    return constraints[index.intValue()].endVersion != null;
  }

  public final Version endVersion() { return endVersion(0L); }
  public final Version endVersion(Long index)
  {
    return constraints[index.intValue()].endVersion;
  }

  public final Boolean match(Version v)
  {
    for (int i=0; i<constraints.length; ++i)
    {
      Constraint c = constraints[i];
      if (c.isPlus)
      {
        // versionPlus
        if (c.version.compare(v).longValue() <= 0)
          return true;
      }
      else if (c.endVersion != null)
      {
        // versionRange
        if (c.version.compare(v).longValue() <= 0 &&
            (c.endVersion.compare(v).longValue() >= 0 || doMatch(c.endVersion, v)))
          return true;
      }
      else
      {
        // versionSimple
        if (doMatch(c.version, v))
          return true;
      }
    }
    return false;
  }

  private static boolean doMatch(Version a, Version b)
  {
    if (a.segments().sz() > b.segments().sz()) return false;
    for (int i=0; i<a.segments().sz(); ++i)
      if (a.segment(i) != b.segment(i))
        return false;
    return true;
  }

//////////////////////////////////////////////////////////////////////////
// Constraint
//////////////////////////////////////////////////////////////////////////

  static class Constraint
  {
    Version version;
    boolean isPlus;
    Version endVersion;
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private final String name;
  private final Constraint[] constraints;
  private String str;

}