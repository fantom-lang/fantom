//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   14 Jan 06  Andy Frank  Creation
//

using System.Collections;
using System.Text;

namespace Fan.Sys
{
  /// <summary>
  /// Depend.
  /// </summary>
  public sealed class Depend : FanObj
  {

  //////////////////////////////////////////////////////////////////////////
  // Construction
  //////////////////////////////////////////////////////////////////////////

    public static Depend fromStr(string str) { return fromStr(str, true); }
    public static Depend fromStr(string str, bool check)
    {
      try
      {
        return new Parser(str).parse();
      }
      catch (System.Exception)
      {
        if (!check) return null;
        throw ParseErr.make("Depend", str).val;
      }
    }

    private Depend(string name, Constraint[] constraints)
    {
      this.m_name = name;
      this.m_constraints = constraints;
    }

  //////////////////////////////////////////////////////////////////////////
  // Parser
  //////////////////////////////////////////////////////////////////////////

    class Parser
    {
      internal Parser(string str)
      {
        this.m_str = str;
        this.m_len = str.Length;
        consume();
      }

      internal Depend parse()
      {
        m_name = name();
        constraints.Add(constraint());
        while (m_cur == ',')
        {
          consume();
          consumeSpaces();
          constraints.Add(constraint());
        }
        if (m_pos <= m_len) throw new System.Exception();
        return new Depend(m_name, (Constraint[])constraints.ToArray(
          System.Type.GetType("Fan.Sys.Depend+Constraint")));
      }

      private string name()
      {
        StringBuilder s = new StringBuilder();
        while (m_cur != ' ')
        {
          if (m_cur < 0) throw new System.Exception();
          s.Append((char)m_cur);
          consume();
        }
        consumeSpaces();
        if (s.Length == 0) throw new System.Exception();
        return s.ToString();
      }

      private Constraint constraint()
      {
        Constraint c = new Constraint();
        c.version = version();
        consumeSpaces();
        if (m_cur == '+')
        {
          c.isPlus = true;
          consume();
          consumeSpaces();
        }
        else if (m_cur == '-')
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
          if ('0' <= m_cur && m_cur <= '9')
          {
            seg = seg*10 + consumeDigit();
          }
          else
          {
            segs.add(Long.valueOf(seg));
            seg = 0;
            if (m_cur != '.') break;
            else consume();
          }
        }
        return new Version(segs);
      }

      private int consumeDigit()
      {
        if ('0' <= m_cur && m_cur <= '9')
        {
          int digit = m_cur - '0';
          consume();
          return digit;
        }
        throw new System.Exception();
      }

      private void consumeSpaces()
      {
        while(m_cur == ' ') consume();
      }

      private void consume()
      {
        if (m_pos < m_len)
        {
          m_cur = m_str[m_pos++];
        }
        else
        {
          m_cur = -1;
          m_pos = m_len+1;
        }
      }

      int m_cur;
      int m_pos;
      int m_len;
      string m_str;
      string m_name;
      ArrayList constraints = new ArrayList(4);
    }

  //////////////////////////////////////////////////////////////////////////
  // .NET
  //////////////////////////////////////////////////////////////////////////

    public override int GetHashCode()
    {
      return toStr().GetHashCode();
    }

  //////////////////////////////////////////////////////////////////////////
  // Identity
  //////////////////////////////////////////////////////////////////////////

    public override bool Equals(object obj)
    {
      if (obj is Depend)
        return toStr() == toStr(obj);
      else
        return false;
    }

    public override long hash()
    {
      return FanStr.hash(toStr());
    }

    public override Type @typeof()
    {
      return Sys.DependType;
    }

    public override string toStr()
    {
      if (m_str == null)
      {
        StringBuilder s = new StringBuilder();
        s.Append(m_name).Append(' ');
        for (int i=0; i<m_constraints.Length; i++)
        {
          if (i > 0) s.Append(',');
          Constraint c = m_constraints[i];
          s.Append(c.version);
          if (c.isPlus) s.Append('+');
          if (c.endVersion != null) s.Append('-').Append(c.endVersion);
        }
        m_str = s.ToString();
      }
      return m_str;
    }

  //////////////////////////////////////////////////////////////////////////
  // Methods
  //////////////////////////////////////////////////////////////////////////

    public string name()
    {
      return m_name;
    }

    public long size()
    {
      return m_constraints.Length;
    }

    public Version version() { return version(0); }
    public Version version(long index)
    {
      return m_constraints[(int)index].version;
    }

    public bool isPlus() { return isPlus(0); }
    public bool isPlus(long index)
    {
      return m_constraints[(int)index].isPlus;
    }

    public bool isRange() { return isRange(0); }
    public bool isRange(long index)
    {
      return m_constraints[(int)index].endVersion != null;
    }

    public Version endVersion() { return endVersion(0); }
    public Version endVersion(long index)
    {
      return m_constraints[(int)index].endVersion;
    }

    public bool match(Version v)
    {
      for (int i=0; i<m_constraints.Length; i++)
      {
        Constraint c = m_constraints[i];
        if (c.isPlus)
        {
          // versionPlus
          if (c.version.compare(v) <= 0)
            return true;
        }
        else if (c.endVersion != null)
        {
          // versionRange
          if (c.version.compare(v) <= 0 &&
              (c.endVersion.compare(v) >= 0 || match(c.endVersion, v)))
            return true;
        }
        else
        {
          // versionSimple
          if (match(c.version, v))
            return true;
        }
      }
      return false;
    }

    private static bool match(Version a, Version b)
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

    internal class Constraint
    {
      internal Version version = null;
      internal bool isPlus = false;
      internal Version endVersion = null;
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    private readonly string m_name;
    private readonly Constraint[] m_constraints;
    private string m_str;

  }
}