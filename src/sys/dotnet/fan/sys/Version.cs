//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   14 Jan 06  Andy Frank  Creation
//

using System.Text;

namespace Fan.Sys
{
  /// <summary>
  /// Version.
  /// </summary>
  public sealed class Version : FanObj
  {

  //////////////////////////////////////////////////////////////////////////
  // Construction
  //////////////////////////////////////////////////////////////////////////

    public static Version fromStr(string s) { return fromStr(s, true); }
    public static Version fromStr(string s, bool check)
    {
      List segments = new List(Sys.IntType, 4);
      int seg = -1;
      bool valid = true;
      int len = s.Length;
      for (int i=0; i<len; ++i)
      {
        int c = s[i];
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
        if (check)
          throw ParseErr.make("Version", s).val;
        else
          return null;
      }

      return new Version(segments);
    }

    public static Version make(List segments)
    {
      bool valid = segments.sz() > 0;
      for (int i=0; i<segments.sz(); i++)
        if (((Long)segments.get(i)).longValue() < 0) valid = false;
      if (!valid) throw ArgErr.make("Invalid Version: '" + segments + "'").val;
      return new Version(segments);
    }

    internal Version(List segments)
    {
      this.m_segments = segments.ro();
    }

  //////////////////////////////////////////////////////////////////////////
  // Identity
  //////////////////////////////////////////////////////////////////////////

    public override bool Equals(object obj)
    {
      if (obj is Version)
        return toStr() == ((Version)obj).toStr();
      else
        return false;
    }

    public override long compare(object obj)
    {
      Version that = (Version)obj;
      List a = this.m_segments;
      List b = that.m_segments;
      for (int i=0; i<a.sz() && i<b.sz(); i++)
      {
        long ai = (a.get(i) as Long).longValue();
        long bi = (b.get(i) as Long).longValue();
        if (ai < bi) return -1;
        if (ai > bi) return +1;
      }
      if (a.sz() < b.sz()) return -1;
      if (a.sz() > b.sz()) return +1;
      return 0;
    }

    public override int GetHashCode()
    {
      return toStr().GetHashCode();
    }

    public override long hash()
    {
      return FanStr.hash(toStr());
    }

    public override Type @typeof()
    {
      return Sys.VersionType;
    }

    public override string toStr()
    {
      if (m_str == null)
      {
        StringBuilder s = new StringBuilder();
        for (int i=0; i<m_segments.sz(); i++)
        {
          if (i > 0) s.Append('.');
          s.Append(m_segments.get(i));
        }
        m_str = s.ToString();
      }
      return m_str;
    }

  //////////////////////////////////////////////////////////////////////////
  // Methods
  //////////////////////////////////////////////////////////////////////////

    public List segments()
    {
      return m_segments;
    }

    public int segment(int index)
    {
      return ((Long)m_segments.get(index)).intValue();
    }

    public long major()
    {
      return ((Long)m_segments.get(0)).longValue();
    }

    public Long minor()
    {
      if (m_segments.sz() < 2) return null;
      return (Long)m_segments.get(1);
    }

    public Long build()
    {
      if (m_segments.sz() < 3) return null;
      return (Long)m_segments.get(2);
    }

    public Long patch()
    {
      if (m_segments.sz() < 4) return null;
      return (Long)m_segments.get(3);
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    public static readonly Version m_defVal = fromStr("0");

    private readonly List m_segments;
    private string m_str;

  }
}