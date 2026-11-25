//
// Copyright (c) 2026, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 Nov 2026  Brian Frank  Creation
//

package fan.dom;

/**
 * TextSelPeer is the JVM implementation of TextSel.  Text is never
 * selected on the JVM, so clear does nothing.
 */
public class TextSelPeer
{
  public static TextSelPeer make(TextSel fan) { return new TextSelPeer(); }

  public void clear(TextSel self) {}
}
