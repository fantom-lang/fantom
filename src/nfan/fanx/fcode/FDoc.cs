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
    public static void read(BinaryReader input)
    {
      StreamReader r = new StreamReader(input.BaseStream, Encoding.UTF8);
      string line;
      string key = null;
      StringBuilder s = new StringBuilder();
      while ((line = r.ReadLine()) != null)
      {
        if (line.StartsWith("  ")) { s.Append(line.Substring(2)).Append('\n'); continue; }
        if (line.Length == 0 && key != null)
        {
          if (key.IndexOf('.') < 0)
            Type.find(key, true).m_doc = Str.make(s.ToString());
          else
            Slot.find(key, true).m_doc = Str.make(s.ToString());
          s = new StringBuilder();
          key = null;
        }
        else
        {
          key = line;
        }
      }
    }

  }
}
