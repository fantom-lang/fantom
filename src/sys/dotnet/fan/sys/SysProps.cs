//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   20 Feb 08  Andy Frank  Creation
//

using System.Collections;

namespace Fan.Sys
{
  /// <summary>
  /// SysProps serves the role of Java's System.properties.
  /// </summary>
  public class SysProps
  {
    /// <summary>
    /// Return the system property for this name, or null if no
    /// matching property value can be found.
    /// </summary>
    public static string getProperty(string name)
    {
      return map[name] as string;
    }

    /// <summary>
    /// Set the system property for this name.
    /// </summary>
    public static void putProperty(string name, string val)
    {
      map[name] = val;
    }

    private static Hashtable map = new Hashtable();

  }
}
