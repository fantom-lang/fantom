//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Sep 06  Andy Frank  Creation
//

using System;
using System.Text;

namespace Fanx.Util
{
  /// <summary>
  /// Utilites for dealing with type names in .NET.
  /// </summary>
  public class NameUtil
  {

    /// <summary>
    /// Return a new string, where the first letter is uppercase.
    /// If the string is a fully qualified type name, make each
    /// character following a '.' uppercase as well.
    /// </summary>
    public static string upper(string str)
    {
      if (str.Length <= 1) return str.ToUpper();

      // Always first letter
      Char[] chars = str.ToCharArray();
      chars[0] = Char.ToUpper(chars[0]);

      // Check for namespace
      for (int i=0; i<chars.Length-1; i++)
        if (chars[i] == '.')
          chars[i+1] = Char.ToUpper(chars[i+1]);

      return new string(chars);
    }

    /// <summary>
    /// If the qualifed type name is a Fan type, then return
    /// the pod name the type should belong to, which should
    /// also be the assembly name.  If the type name does not
    /// appear to be a Fan type, return null.
    /// </summary>
    public static string getPodName(string qname)
    {
      if (!qname.StartsWith("Fan.")) return null;

      // Must have one more '.'
      int index = qname.IndexOf('.', 5);
      if (index == -1) return null;

      // Make first char lower case
      StringBuilder s = new StringBuilder(qname.Substring(4, index-4));
      s[0] = Char.ToLower(s[0]);
      return s.ToString();
    }

    /// <summary>
    /// Split a qualifed type name into two strings, where
    /// s[0] is the namespace, and s[1] is the simple type
    /// name.
    /// If qname represents a nested class, then s[0] will
    /// be the qualified type name of the parent, and s[1]
    /// will simply be the nested class name.
    /// </summary>
    public static string[] splitQName(string qname)
    {
      string[] s = new string[] { null, qname };
      int index = qname.LastIndexOf('/');
      if (index != -1)
      {
        s[0] = qname.Substring(0, index);
        s[1] = qname.Substring(index+1);
      }
      else
      {
        index = qname.LastIndexOf('.');
        if (index != -1)
        {
          s[0] = qname.Substring(0, index);
          s[1] = qname.Substring(index+1);
        }
      }
      return s;
    }

  }
}