//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   17 Jan 08  Andy Frank  Creation
//

using System.IO;

namespace Fanx.Util
{
  /// <summary>
  /// FileUtil.
  /// </summary>
  public class FileUtil
  {
    /// <summary>
    /// Combine the string array into a valid file path.
    /// </summary>
    public static string combine(string[] paths)
    {
      // TODO - pretty naive - could be better and faster.
      string s = paths[0];
      for (int i=1; i<paths.Length; i++)
        s = Path.Combine(s, paths[i]);
      return s;
    }

    public static string combine(string a, string b)
    {
      return Path.Combine(a, b);
    }

    public static string combine(string a, string b, string c)
    {
      return combine(new string[] { a, b, c });
    }

    public static string combine(string a, string b, string c, string d)
    {
      return combine(new string[] { a, b, c, d });
    }

  }
}
