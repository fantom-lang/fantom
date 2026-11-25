//
// Copyright (c) 2026, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 Nov 2026  Brian Frank  Creation
//

package fan.dom;

/**
 * TextSelPeer has nothing to clear: no text is ever selected.
 */
public class TextSelPeer
{
  public static TextSelPeer make(TextSel fan) { return new TextSelPeer(); }

  public void clear(TextSel self) {}
}
