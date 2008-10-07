//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   2 Jul 06  Brian Frank  Creation
//
package fanx.fcode;

import java.io.*;
import java.util.*;
import fan.sys.*;

/**
 * FDoc is used to read a fandoc text file.  The fandoc file
 * format is an extremely simple plan text format with left justified
 * type/slot qnames, followed by the fandoc content indented two spaces.
 */
public class FDoc
{

  /**
   * Read a fandoc file and store the doc strings.
   */
  public static void read(InputStream in)
    throws IOException
  {
    BufferedReader r = new BufferedReader(new InputStreamReader(in, "UTF-8"));
    String line;
    String key = null;
    StringBuilder s = new StringBuilder();
    while ((line = r.readLine()) != null)
    {
      if (line.startsWith("  ")) { s.append(line.substring(2)).append('\n'); continue; }
      if (line.length() == 0 && key != null)
      {
        if (key.indexOf('.') < 0)
          ((ClassType)Type.find(key, true)).doc = s.toString();
        else
          Slot.find(key, true).doc = s.toString();
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