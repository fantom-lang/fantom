//
// Copyright (c) 2010, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   9 Feb 10  Andy Frank  Creation
//

using System;
using System.Collections;
using System.IO;

namespace Fanx.Util
{
  /// <summary>
  /// Properties is an partial implemention of java.util.Properties for .NET.
  /// </summary>
  public class Properties
  {

  //////////////////////////////////////////////////////////////////////////
  // Constructor
  //////////////////////////////////////////////////////////////////////////

    /// <summary>
    /// Creates an empty property list with no default values.
    /// </summary>
    public Properties()
    {
    }

  //////////////////////////////////////////////////////////////////////////
  // Access
  //////////////////////////////////////////////////////////////////////////

    /// <summary>
    /// Searches for the property with the specified key in this
    /// property list. If the key is not found in this property list,
    /// return default value argument.
    /// </summary>
    public string getProperty(string key)
    {
      return getProperty(key, null);
    }


    /// <summary>
    /// Searches for the property with the specified key in this
    /// property list. If the key is not found in this property list,
    /// return default value argument.
    /// </summary>
    public string getProperty(string key, string defVal)
    {
      string val = (string)map[key];
      if (val == null) return defVal;
      return val;
    }

  //////////////////////////////////////////////////////////////////////////
  // Load
  //////////////////////////////////////////////////////////////////////////

    /// <summary>
    /// Reads a property list (key and element pairs) from the input stream.
    /// </summary>
    public void load(Stream input)
    {
      // TODO FIXIT: just the basics needed to get sys.pod bootstrapped
      StreamReader reader = new StreamReader(input);
      string line = reader.ReadLine();
      while (line != null)
      {
        // skip empty lines
        if (line.Length == 0) continue;

        // find key/val delimiter
        int off = line.IndexOf("=");
        if (off < 1) throw new IOException("Invalid format " + line);

        // parse key/val
        string key = line.Substring(0, off).Trim();
        string val = line.Substring(off+1, line.Length-off-1).Trim();
        map[key] = val;
        line = reader.ReadLine();
      }
    }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    private Hashtable map = new Hashtable();

  }
}