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
   * Top is ClassType or Pod.
   */
  public static void read(InputStream in, Object top)
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
        setDoc(top, key, s.toString());
        s = new StringBuilder();
        key = null;
      }
      else
      {
        key = line;
      }
    }
  }

  private static void setDoc(Object top, String key, String doc)
  {
    if (top instanceof Pod)
    {
      int colon = key.lastIndexOf(':');
      String name = colon < 0 ? null : key.substring(colon+1);
      if (name == null)
        ((Pod)top).doc = doc;
      else
        throw new RuntimeException(key);
    }
    else
    {
      int dot = key.lastIndexOf('.');
      String name = dot < 0 ? null : key.substring(dot+1);
      if (name == null)
        ((ClassType)top).doc = doc;
      else
        ((Type)top).slot(name, true).doc = doc;
    }
  }


}