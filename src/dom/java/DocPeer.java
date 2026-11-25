//
// Copyright (c) 2017, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 May 2017  Andy Frank   Creation
//   24 Nov 2026  Brian Frank  Tree, queries and focus
//

package fan.dom;

import java.util.ArrayList;
import java.util.HashMap;
import fan.sys.*;
import fanx.interop.*;

/**
 * DocPeer is the JVM implementation of a window's document.  It is
 * the root of the node tree and has html, head and body elements.
 * It also tracks document-wide state: the focused element, the open
 * popovers and the captured pointers.
 */
public class DocPeer extends DomNodePeer
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  public static DocPeer make(Doc fan)
  {
    DocPeer peer = DomPeerFactory.factory().makeDoc(fan);
    ((DomNode)fan).peer = peer; // override base class's peer field
    return peer;
  }

  void init(Doc self, Win win)
  {
    this.win  = win;
    this.html = Elem.make("html", null);
    this.head = Elem.make("head", null);
    this.body = Elem.make("body", null);
    addChild(self, html);
    html.add(head);
    html.add(body);
  }

  // Get the peer of the document a node is attached to, or null if
  // the node is not in a document
  static DocPeer of(DomNode node)
  {
    DomNode root = node;
    while (root.peer.parentNode != null) root = root.peer.parentNode;
    return root instanceof Doc ? ((Doc)root).peer : null;
  }

//////////////////////////////////////////////////////////////////////////
// Accessors
//////////////////////////////////////////////////////////////////////////

  public String title(Doc self) { return title; }
  public void title(Doc self, String title) { this.title = title; }

  public Elem head(Doc self) { return head; }

  public Elem body(Doc self) { return body; }

  public boolean hasFocus(Doc self) { return true; }

  public boolean isHidden(Doc self) { return false; }

  // Get the focused element, or the body if nothing has focus.  An
  // element removed from the document silently loses focus
  public Elem activeElem(Doc self)
  {
    if (active != null && of(active) != this) active = null;
    return active == null ? body : active;
  }

//////////////////////////////////////////////////////////////////////////
// Tree
//////////////////////////////////////////////////////////////////////////

  public Elem elemById(Doc self, String id) { return findById(html, id); }

  private static Elem findById(Elem e, String id)
  {
    if (id.equals(e.attr("id"))) return e;
    ArrayList kids = e.peer.kids;
    for (int i=0; i<kids.size(); i++)
    {
      if (!(kids.get(i) instanceof Elem)) continue;
      Elem x = findById((Elem)kids.get(i), id);
      if (x != null) return x;
    }
    return null;
  }

  public Elem createElem(Doc self, String tagName, Map attrib, Uri ns)
  {
    Elem elem = Elem.make(tagName, ns);
    if (attrib != null)
    {
      List names = attrib.keys();
      for (int i=0; i<names.sz(); i++) elem.setAttr((String)names.get(i), (String)attrib.get(names.get(i)));
    }
    return elem;
  }

  public DomFrag createFrag(Doc self) { return DomFrag.make(); }

  public Elem querySelector(Doc self, String selectors)
  {
    ArrayList matches = new ArrayList();
    QuerySelector.parse(selectors).findAll(self, html, matches, 1);
    return matches.size() == 0 ? null : (Elem)matches.get(0);
  }

  public List querySelectorAll(Doc self, String selectors)
  {
    ArrayList matches = new ArrayList();
    QuerySelector.parse(selectors).findAll(self, html, matches, Integer.MAX_VALUE);
    return Interop.toFan(matches, Type.find("dom::Elem"));
  }

  public List querySelectorAllType(Doc self, String selectors, Type type)
  {
    return querySelectorAll(self, selectors);
  }

//////////////////////////////////////////////////////////////////////////
// Unsupported
//////////////////////////////////////////////////////////////////////////

  public String  exportPng    (Doc self, Elem img)                               { throw err(); }
  public String  exportJpg    (Doc self, Elem img, Double quality)               { throw err(); }
  public boolean exec         (Doc self, String name, boolean defUi, Object val) { throw err(); }
  public String  getCookiesStr(Doc self)                                         { return ""; }

// cannot compile against "graphics" or "web" pod - see https://fantom.org/forum/topic/2886
//  public Elem         elemFromPos  (Doc self, Point p)   { throw err(); }
//  public List         elemsFromPos (Doc self, Point p)   { throw err(); }
//  public WebOutStream out          (Doc self)            { throw err(); }
//  public void         addCookie    (Doc self, Cookie c)  { throw err(); }

  private static Err err() { return UnsupportedErr.make(); }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  Win win;
  Elem html;
  Elem head;
  Elem body;
  String title = "";
  Elem active;                                   // null for the body
  final ArrayList popovers = new ArrayList();    // Elem: open, oldest first
  final HashMap captures = new HashMap();        // pointer id : Elem
}
