//
// Copyright (c) 2023, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 Feb 2023  Brian Frank  Creation
//

package fan.dom;

import fan.sys.*;

public class DocPeer
{
  public static DocPeer make(Doc fan)
  {
    return DomPeerFactory.factory().makeDoc(fan);
  }

  public String  title               (Doc self)                                                { throw err(); }
  public Elem    head                (Doc self)                                                { throw err(); }
  public Elem    body                (Doc self)                                                { throw err(); }
  public Elem    activeElem          (Doc self)                                                { throw err(); }
  public Elem    elemById            (Doc self, String id)                                     { throw err(); }
  public Elem    createElem          (Doc self, String tagName, Map attrib, Uri ns)            { throw err(); }
  public Elem    createFrag          (Doc self)                                                { throw err(); }
  public Elem    querySelector       (Doc self, String selectors)                              { throw err(); }
  public List    querySelectorAll    (Doc self, String selectors)                              { throw err(); }
  public List    querySelectorAllType(Doc self, String selectors, Type type)                   { throw err(); }
  public String  exportPng           (Doc self, Elem img)                                      { throw err(); }
  public String  exportJpg           (Doc self, Elem img, double quality)                      { throw err(); }
  public Func    onEvent             (Doc self, String type, boolean useCapture, Func handler) { throw err(); }
  public void    removeEvent         (Doc self, String type, boolean useCapture, Func handler) { throw err(); }
  public boolean exec                (Doc self, String name, boolean defUi, Object val)        { throw err(); }
  public String  getCookiesStr       (Doc self)                                                { throw err(); }

//  cannot compile against "web" pod - see https://fantom.org/forum/topic/2886
//  public WebOutStream out          (Doc self)                                                { throw err(); }
//  public void         addCookie    (Doc self, Cookie c)                                      { throw err(); }

  private static Err err() { return UnsupportedErr.make(); }
}
