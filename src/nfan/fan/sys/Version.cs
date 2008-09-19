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

    public static Version fromStr(Str str) { return fromStr(str.val, true); }
    public static Version fromStr(Str str, Bool check) { return fromStr(str.val, check.val); }
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
        if (((Int)segments.get(i)).val < 0) valid = false;
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

    public override Bool equals(Obj obj)
    {
      if (obj is Version)
        return toStr().equals(((Version)obj).toStr());
      else
        return Bool.False;
    }

    public override Int compare(Obj obj)
    {
      Version that = (Version)obj;
      List a = this.m_segments;
      List b = that.m_segments;
      for (int i=0; i<a.sz() && i<b.sz(); i++)
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

    public override int GetHashCode()
    {
      return toStr().GetHashCode();
    }

    public override Int hash()
    {
      return toStr().hash();
    }

    public override Type type()
    {
      return Sys.VersionType;
    }

    public override Str toStr()
    {
      if (m_str == null)
      {
        StringBuilder s = new StringBuilder();
        for (int i=0; i<m_segments.sz(); i++)
        {
          if (i > 0) s.Append('.');
          s.Append(((Int)m_segments.get(i)).val);
        }
        m_str = Str.make(s.ToString());
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
      return (int)((Int)m_segments.get(index)).val;
    }

    public Int major()
    {
      return (Int)m_segments.get(0);
    }

    public Int minor()
    {
      if (m_segments.sz() < 2) return null;
      return (Int)m_segments.get(1);
    }

    public Int build()
    {
      if (m_segments.sz() < 3) return null;
      return (Int)m_segments.get(2);
    }

    public Int patch()
    {
      if (m_segments.sz() < 4) return null;
      return (Int)m_segments.get(3);
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    private readonly List m_segments;
    private Str m_str;

  }
}
