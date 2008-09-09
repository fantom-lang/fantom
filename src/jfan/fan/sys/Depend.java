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

  public static Depend fromStr(Str str) { return fromStr(str.val); }
  public static Depend fromStr(String str)
  {
    try
    {
      return new Parser(str).parse();
    }
    catch (Throwable e)
    {
      throw ParseErr.make("Invalid Depend: '" + str + "'").val;
    }
  }

  private Depend(Str name, Constraint[] constraints)
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

    private Str name()
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
      return Str.make(s.toString());
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
          segs.add(Int.pos(seg));
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
    Str name;
    ArrayList constraints = new ArrayList(4);
  }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  public Bool equals(Obj obj)
  {
    if (obj instanceof Depend)
      return toStr().equals(obj.toStr());
    else
      return Bool.False;
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
    return Sys.DependType;
  }

  public Str toStr()
  {
    if (str == null)
    {
      StringBuilder s = new StringBuilder();
      s.append(name.val).append(' ');
      for (int i=0; i<constraints.length; ++i)
      {
        if (i > 0) s.append(',');
        Constraint c = constraints[i];
        s.append(c.version);
        if (c.isPlus) s.append('+');
        if (c.endVersion != null) s.append('-').append(c.endVersion);
      }
      str = Str.make(s.toString());
    }
    return str;
  }

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  public final Str name()
  {
    return name;
  }

  public final Int size()
  {
    return Int.pos(constraints.length);
  }

  public final Version version() { return version(Int.Zero); }
  public final Version version(Int index)
  {
    return constraints[(int)index.val].version;
  }

  public final Bool isPlus() { return isPlus(Int.Zero); }
  public final Bool isPlus(Int index)
  {
    return constraints[(int)index.val].isPlus ? Bool.True : Bool.False;
  }

  public final Bool isRange() { return isRange(Int.Zero); }
  public final Bool isRange(Int index)
  {
    return constraints[(int)index.val].endVersion != null ? Bool.True : Bool.False;
  }

  public final Version endVersion() { return endVersion(Int.Zero); }
  public final Version endVersion(Int index)
  {
    return constraints[(int)index.val].endVersion;
  }

  public final Bool match(Version v)
  {
    for (int i=0; i<constraints.length; ++i)
    {
      Constraint c = constraints[i];
      if (c.isPlus)
      {
        // versionPlus
        if (c.version.compare(v).val <= 0)
          return Bool.True;
      }
      else if (c.endVersion != null)
      {
        // versionRange
        if (c.version.compare(v).val <= 0 &&
            (c.endVersion.compare(v).val >= 0 || doMatch(c.endVersion, v)))
          return Bool.True;
      }
      else
      {
        // versionSimple
        if (doMatch(c.version, v))
          return Bool.True;
      }
    }
    return Bool.False;
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

  private final Str name;
  private final Constraint[] constraints;
  private Str str;

}