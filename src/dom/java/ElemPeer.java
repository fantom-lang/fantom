//
// Copyright (c) 2017, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 May 2017  Andy Frank  Creation
//

package fan.dom;

import java.lang.StringBuffer;
import java.util.ArrayList;
import java.util.Map.Entry;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Iterator;
import java.util.LinkedHashMap;
import fan.sys.*;
import fanx.interop.*;

public class ElemPeer extends DomNodePeer
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  public static ElemPeer make(Elem fan)
  {
    ElemPeer peer = DomPeerFactory.factory().makeElem(fan);
    ((DomNode)fan).peer = peer; // override base class's peer field
    return peer;
  }

  public static Elem fromNative(Object elem, Type type)
  {
    return DomPeerFactory.factory().elemFromNative(elem, type);
  }

  public void _make(Elem self, String tagName, Uri ns)
  {
    this.tagName = tagName;
    this.ns = ns==null ? defns : ns;

    // optimziation hooks for non-html namespaces
    if (ns != null)
    {
      this.isSvg = ns.toStr().equals("http://www.w3.org/2000/svg");
    }
  }

//////////////////////////////////////////////////////////////////////////
// Accessors
//////////////////////////////////////////////////////////////////////////

  public Uri ns(Elem self) { return this.ns; }

  public String tagName(Elem self) { return this.tagName; }

  public Style style(Elem self)
  {
    if (style == null)
    {
      style = new Style();
      style.peer.elem = self;
    }
    return style;
  }

  public String html(Elem self)
  {
    StringBuilder s = new StringBuilder();
    for (int i=0; i<kids.size(); i++) writeHtml(s, (DomNode)kids.get(i));
    return s.toString();
  }

  public void html(Elem self, String html)
  {
    self.removeAll();
    HtmlParser.parse(self, html);
  }

  // serialize a node as a browser does for innerHTML: a void element
  // has no end tag, every other element has one
  private static void writeHtml(StringBuilder s, DomNode node)
  {
    if (!(node instanceof Elem)) { escHtml(s, node.text(), false); return; }

    Elem elem = (Elem)node;
    ElemPeer peer = (ElemPeer)elem.peer;
    s.append('<').append(peer.tagName);
    Map attrs = elem.attrs();
    List names = attrs.keys();
    for (int i=0; i<names.sz(); i++)
    {
      String name = (String)names.get(i);
      s.append(' ').append(name).append("=\"");
      escHtml(s, (String)attrs.get(name), true);
      s.append('"');
    }
    s.append('>');
    if (!peer.isSvg && HtmlParser.voidTags.contains(peer.tagName)) return;
    for (int i=0; i<peer.kids.size(); i++) writeHtml(s, (DomNode)peer.kids.get(i));
    s.append("</").append(peer.tagName).append('>');
  }

  private static void escHtml(StringBuilder s, String val, boolean isAttr)
  {
    for (int i=0; i<val.length(); i++)
    {
      char c = val.charAt(i);
      if (c == '&') s.append("&amp;");
      else if (c == '<') s.append("&lt;");
      else if (c == '>') s.append("&gt;");
      else if (c == '"' && isAttr) s.append("&quot;");
      else s.append(c);
    }
  }

  public Boolean enabled(Elem self) { return enabled; }
  public void enabled(Elem self, Boolean v) { this.enabled = v; }

//////////////////////////////////////////////////////////////////////////
// Attributes
//////////////////////////////////////////////////////////////////////////

  // attributes in the order they were first set; class is kept by
  // Style, and takes its place in the order from its key
  public Map attrs(Elem self)
  {
    Map map = Map.make(Sys.StrType, Sys.StrType);
    map.ordered(true);
    String className = self.attr("class");
    Iterator it = attrs.entrySet().iterator();
    while (it.hasNext())
    {
      Entry e = (Entry)it.next();
      if (e.getKey().equals("class")) { if (className != null) map.set("class", className); }
      else map.set(e.getKey(), e.getValue());
    }

    // classes added thru Style without the attribute being set
    if (className != null && !attrs.containsKey("class")) map.set("class", className);

    return map;
  }

  public String attr(Elem self, String name)
  {
    // delegate to Style for class
    if (name.equals("class"))
    {
      List c = style(self).classes();
      return c.size() == 0 ? null : c.join(" ");
    }

    return (String)attrs.get(name);
  }

  public Elem setAttr(Elem self, String name, String val, Uri ns)
  {
    // TODO: ns?
    if (val == null) return removeAttr(self, name);
    String old = MutationObserverPeer.isActive() ? attr(self, name) : null;

    // delegate to Style for class
    if (name.equals("class")) style(self).peer._setClass(style, val);

    attrs.put(name, val);
    MutationObserverPeer.attr(self, name, old);
    return self;
  }

  public Elem removeAttr(Elem self, String name)
  {
    String old = attr(self, name);
    if (old == null && !attrs.containsKey(name)) return self;

    // delegate to Style for class
    if (name.equals("class")) style(self).peer._setClass(style, "");

    attrs.remove(name);
    MutationObserverPeer.attr(self, name, old);
    return self;
  }

//////////////////////////////////////////////////////////////////////////
// Props
//////////////////////////////////////////////////////////////////////////

  // a property which has not been set reflects the attribute of
  // the same name; setting a property never writes an attribute
  public Object prop(Elem self, String name)
  {
    Object v = props.get(name);
    if (v == null) v = attr(self, name);

    // return "" for null id to match js
    if (v == null && propHooks.get(name) != null) return "";

    return v;
  }

  public Elem setProp(Elem self, String name, Object val)
  {
    if (val == null)
      props.remove(name);
    else
      props.put(name, val);
    return self;
  }

  private static HashMap propHooks = new HashMap();
  static
  {
    propHooks.put("id", true);
  }

//////////////////////////////////////////////////////////////////////////
// FFI
//////////////////////////////////////////////////////////////////////////

  public Object trap(Elem self, String name, List args)
  {
    if (isSvg) return Svg.doTrap(self, name, args);

    if (args == null || args.isEmpty()) return this.prop(self, name);
    this.setProp(self, name, args.first());
    return null;
  }

  public Object invoke(Elem self, String name, List args)
  {
    return DomFuncs.invoke(self, name, args);
  }

//////////////////////////////////////////////////////////////////////////
//Layout
//////////////////////////////////////////////////////////////////////////

// cannot compile against "web" pod - see https://fantom.org/forum/topic/2886
// public Point pos       (Elem self) { throw err(); }
// public Point pagePos   (Elem self) { throw err(); }
// public Size  size      (Elem self) { throw err(); }
// public Point scrollPos (Elem self) { throw err(); }
// public Size  scrollSize(Elem self) { throw err(); }

  public Elem scrollIntoView(Elem self, boolean alignToTop) { return self; }

//////////////////////////////////////////////////////////////////////////
// Tree
//////////////////////////////////////////////////////////////////////////

  public boolean hasChildren(Elem self)
  {
    return elemKids().size() > 0;
  }

  public List children(Elem self)
  {
    return Interop.toFan(elemKids(), Type.find("dom::Elem"));
  }

  public Elem firstChild(Elem self)
  {
    ArrayList elems = elemKids();
    return elems.size() == 0 ? null : (Elem)elems.get(0);
  }

  public Elem lastChild(Elem self)
  {
    ArrayList elems = elemKids();
    return elems.size() == 0 ? null : (Elem)elems.get(elems.size()-1);
  }

  public Elem prevSibling(Elem self)
  {
    if (parentNode == null) return null;
    ArrayList sibs = parentNode.peer.elemKids();
    int i = sibs.indexOf(self);
    return i == 0 ? null : (Elem)sibs.get(i-1);
  }

  public Elem nextSibling(Elem self)
  {
    if (parentNode == null) return null;
    ArrayList sibs = parentNode.peer.elemKids();
    int i = sibs.indexOf(self);
    return i == sibs.size()-1 ? null : (Elem)sibs.get(i+1);
  }

  public Elem querySelector(Elem self, String selectors)
  {
    ArrayList matches = new ArrayList();
    QuerySelector.parse(selectors).findAll(self, self, matches, 1);
    return matches.size() == 0 ? null : (Elem)matches.get(0);
  }

  public List querySelectorAll(Elem self, String selectors)
  {
    ArrayList matches = new ArrayList();
    QuerySelector.parse(selectors).findAll(self, self, matches, Integer.MAX_VALUE);
    return Interop.toFan(matches, Type.find("dom::Elem"));
  }

  public Elem closest(Elem self, String selectors)
  {
    QuerySelector q = QuerySelector.parse(selectors);
    for (Elem e = self; e != null; e = e.parent())
      if (q.matches(e, self)) return e;
    return null;
  }

//////////////////////////////////////////////////////////////////////////
// Events
//////////////////////////////////////////////////////////////////////////

  public boolean hasFocus(Elem self) { return DomFuncs.hasFocus(self); }
  public void    focus   (Elem self) { DomFuncs.focus(self); }
  public void    blur    (Elem self) { DomFuncs.blur(self); }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private static final Uri defns = Uri.fromStr("http://www.w3.org/1999/xhtml");

  private boolean isSvg = false;

  private Uri ns;                             // non-null
  private String tagName;                     // non-null
  private Style style;                        // null
  private boolean enabled = true;
  private LinkedHashMap attrs = new LinkedHashMap();  // Str:Str
  private HashMap props = new HashMap();      // Str:Obj

  boolean popoverOpen;                        // is shown as a popover
  boolean modal;                              // is shown as a modal dialog
  Object[] toggle;                            // states of the toggle event which is queued
  Elem prevFocus;                             // focus when shown as a popover or dialog
}

