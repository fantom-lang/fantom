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

  public FDoc(InputStream in, ClassType type)
    throws IOException
  {
    this.in   = new BufferedReader(new InputStreamReader(in, "UTF-8"));
    this.type = type;
  }

  public void read()
    throws IOException
  {
    consume();
    // == <type>
    if (!cur.startsWith("== ")) throw new IOException("Unexpected type line: " + cur);
    type.doc = readAttrsToDoc();

    // -- <slot> sections
    while (cur != null)
    {
      // <slot>      :=  (<fieldSig> | <methodSig>) <attrs>
      // <fieldSig>  :=  "-- " <name> <sp> <type> [":=" <expr>] <nl>
      // <methodSig> :=  "-- " <name> "(" <nl> [<param> <nl>]* ")" <sp> <return> <nl>
      if (!cur.startsWith("-- ")) throw new IOException("Unexpected slot line: " + cur);
      String slotName = cur.endsWith("(") ?
         cur.substring(3, cur.length()-1) :
         cur.substring(3, cur.indexOf(' ', 4));
      String slotDoc = readAttrsToDoc();
      Slot slot = type.slot(slotName, false);
      if (slot != null) slot.doc = slotDoc;
    }
  }

  private String readAttrsToDoc()
    throws IOException
  {
    // skip meta/facets, params, etc; fandoc starts after blank line
    while (cur != null && cur.length() > 0) consume();
    consume();

    // read the fandoc
    StringBuilder s = new StringBuilder();
    while (cur != null && !cur.startsWith("-- "))
    {
      s.append(cur).append('\n');
      consume();
    }
    if (s.length() == 0) return "";
    if (s.charAt(s.length()-1) == '\n') s.setLength(s.length()-1);
    return s.toString();
  }

  private void consume()
    throws IOException
  {
    cur = in.readLine();
  }

  private BufferedReader in;  // stream of lines to read
  private ClassType type;     // type we are storing result to
  private String cur;         // current line
}