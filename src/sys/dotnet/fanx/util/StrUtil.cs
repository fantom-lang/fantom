//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   20 Dec 06  Andy Frank  Creation
//

using System;
using System.Text;
using Fanx.Fcode;

namespace Fanx.Util
{
  /// <summary>
  /// StrUtil provides helpful methods for string manipulation.
  /// </summary>
  public class StrUtil
  {
    /// <summary>
    /// Return a new string replacing all occurances of
    /// <code>match</code> with <code>replace</code> in
    /// <code>s</code>.
    /// <summary>
    public static string Replace(string s, string match, string replace)
    {
      StringBuilder b = new StringBuilder();

      int mlen = match.Length;
      int last = 0;
      int curr = s.IndexOf(match);

      while (curr != -1)
      {
        b.Append(s.Substring(last, curr-last));
        b.Append(replace);

        last = curr + mlen;
        curr = s.IndexOf(match, last);
      }

      if (last < s.Length)
        b.Append(s.Substring(last));

      return b.ToString();
    }

    /// <summary>
    /// Translate the specified string as it would appear in
    /// code as a string literal.  For example all newlines
    /// appear as \n.
    /// </summary>
    public static string asCode(string s)
    {
      StringBuilder b = new StringBuilder();
      for (int i=0; i<s.Length; i++)
      {
        char c = s[i];
        switch (c)
        {
          case '\0': b.Append("\\0");  break;
          case '\t': b.Append("\\t");  break;
          case '\n': b.Append("\\n");  break;
          case '\r': b.Append("\\r");  break;
          case '\\': b.Append("\\\\"); break;
          default:   b.Append(c);      break;
        }
      }
      return b.ToString();
    }

    /// <summary>
    /// Get a string containing the specified number of spaces.
    /// </summary>
    public static string getSpaces(int len)
    {
      // do an array lookup for reasonable length
      // strings since that is the common case
      try { return spaces[len]; } catch(IndexOutOfRangeException) {}

      // otherwise we build a new one
      StringBuilder s = new StringBuilder(spaces[spaces.Length-1]);
      for (int i=spaces.Length-1; i<len; i++)
        s.Append(' ');
      return s.ToString();
    }
    static string[] spaces = new string[20];
    static StrUtil()
    {
      StringBuilder s = new StringBuilder();
      for (int i=0; i<spaces.Length; ++i)
      {
        spaces[i] = s.ToString();
        s.Append(' ');
      }
    }

    /// <summary>
    /// Pad to the left to ensure string is specified length.
    /// If s.length already greater than len, do nothing.
    /// </summary>
    public static string padl(string s, int len)
    {
      if (s.Length >= len) return s;
      return getSpaces(len-s.Length) + s;
    }

    /// <summary>
    /// Pad to the right to ensure string is specified length.
    /// If s.length already greater than len, do nothing.
    /// </summary>
    public static string padr(string s, int len)
    {
      if (s.Length >= len) return s;
      return s + getSpaces(len-s.Length);
    }

    /**
     * Get current hostname.
     */
    /*
    public static string hostname()
    {
      if (hostname == null)
      {
        try
        {
          hostname = InetAddress.getLocalHost().getHostName();
        }
        catch(Exception e)
        {
          hostname = "Unknown";
        }
      }
      return hostname;
    }
    static string hostname = null;
    */

    /**
     * Get a timestamp string for current time.
     */
    /*
    public static string timestamp()
    {
      return new SimpleDateFormat("d-MMM-yyyy HH:mm:ss zzz").format(new Date());
    }
    */

    /**
     * Get simple class name from specified class.
     */
    /*
    public static string getName(Class cls)
    {
      string name = cls.getName();
      int dot = name.lastIndexOf('.');
      if (dot < 0) return name;
      return name.substring(dot+1);
    }
    */

    /**
     * Write the stack trace to a string.
     */
    /*
    public static string traceToString(Throwable e)
    {
      StringWriter out = new StringWriter();
      e.printStackTrace(new PrintWriter(out));
      return out.toString();
    }
    */

    /// <summary>
    /// Return a zero based index as "first", "second", etc.
    /// </summary>
    public static string toOrder(int index)
    {
      switch (index)
      {
        case 0:  return "first";
        case 1:  return "second";
        case 2:  return "third";
        case 3:  return "fourth";
        case 4:  return "fifth";
        case 5:  return "sixth";
        case 6:  return "seventh";
        case 7:  return "eighth";
        case 8:  return "ninth";
        case 9:  return "tenth";
        default: return (index+1) + "th";
      }
    }

    /**
     * Convert FConst flags to a string.
     */
    public static string flagsToString(int flags)
    {
      StringBuilder s = new StringBuilder();
      if ((flags & FConst.Public)    != 0) s.Append("public ");
      if ((flags & FConst.Protected) != 0) s.Append("protected ");
      if ((flags & FConst.Private)   != 0) s.Append("private ");
      if ((flags & FConst.Internal)  != 0) s.Append("internal ");
      if ((flags & FConst.Native)    != 0) s.Append("native ");
      if ((flags & FConst.Enum)      != 0) s.Append("enum ");
      if ((flags & FConst.Mixin)     != 0) s.Append("mixin ");
      if ((flags & FConst.Final)     != 0) s.Append("final ");
      if ((flags & FConst.Ctor)      != 0) s.Append("new ");
      if ((flags & FConst.Override)  != 0) s.Append("override ");
      if ((flags & FConst.Abstract)  != 0) s.Append("abstract ");
      if ((flags & FConst.Static)    != 0) s.Append("static ");
      if ((flags & FConst.Virtual)   != 0) s.Append("virtual ");
      return s.ToString();
    }

    /*
    public static Comparator comparator = new Comparator()
    {
      public int compare(Object a, Object b)
      {
        return string.valueOf(a).compareTo(string.valueOf(b));
      }
    };
    */

  }
}
