//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   18 Feb 08  Andy Frank  Creation
//

using System.IO;
using System.Text;
using Fan.Sys;

namespace Fanx.Fcode
{
  /// <summary>
  /// FDoc is used to read a fandoc text file.  The fandoc file
  /// format is an extremely simple plan text format with left justified
  /// type/slot qnames, followed by the fandoc content indented two spaces.
  /// </summary>
  public class FDoc
  {
    /// <summary>
    /// Read a fandoc file and store the doc strings.
    /// </summary>
    public static void read(Stream input, object top)
    {
      StreamReader r = new StreamReader(input, Encoding.UTF8);
      string line;
      string key = null;
      StringBuilder s = new StringBuilder();
      while ((line = r.ReadLine()) != null)
      {
        if (line.StartsWith("  ")) { s.Append(line.Substring(2)).Append('\n'); continue; }
        if (line.Length == 0 && key != null)
        {
          setDoc(top, key, s.ToString());
          s = new StringBuilder();
          key = null;
        }
        else
        {
          key = line;
        }
      }
    }

  private static void setDoc(object top, string key, string doc)
  {
    if (top is Pod)
    {
      int colon = key.LastIndexOf(':');
      string name = colon < 0 ? null : key.Substring(colon+1);
      if (name == null)
        ((Pod)top).m_doc = doc;
    }
    else
    {
      int dot = key.LastIndexOf('.');
      string name = dot < 0 ? null : key.Substring(dot+1);
      if (name == null)
        ((ClassType)top).m_doc = doc;
      else
        ((Type)top).slot(name, true).m_doc = doc;
    }
  }

  }
}