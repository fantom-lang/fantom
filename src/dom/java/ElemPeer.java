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
import java.util.Iterator;
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
    if (style == null) style = new Style();
    return style;
  }

  // TODO: need to serialize all children into <html> format?
  public String html(Elem self) { throw err(); }
  public void html(Elem self, String html) { throw err(); }

  public Boolean enabled(Elem self) { return enabled; }
  public void enabled(Elem self, Boolean v) { this.enabled = v; }

//////////////////////////////////////////////////////////////////////////
// Attributes
//////////////////////////////////////////////////////////////////////////

  public Map attrs(Elem self)
  {
    Map map = Map.make(Sys.StrType, Sys.StrType);

    // collect props
    Iterator it = props.entrySet().iterator();
    while (it.hasNext())
    {
      Entry e = (Entry)it.next();
      map.set(e.getKey(), e.getValue().toString());
    }

    // merge in class if specified
    String className = self.attr("class");
    if (className != null) map.set("class", className);

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

    // do not route to prop to avoid propHooks traps
    Object val = props.get(name);
    return val == null ? null : val.toString();
  }

  public Elem setAttr(Elem self, String name, String val, Uri ns)
  {
    if (name.equals("class"))
    {
      // delegate to Style for class
      style(self).peer._setClass(style, val);
    }
    else
    {
      // TODO: ns?
      // route to setProp
      this.setProp(self, name, val==null ? null : val.toString());
    }
    return self;
  }

  public Elem removeAttr(Elem self, String name)
  {
    if (name.equals("class"))
    {
      // delegate to Style for class
      style(self).peer._setClass(style, "");
    }
    else
    {
      // route to setProp
      this.setProp(self, name, null);
    }
    return self;
  }

//////////////////////////////////////////////////////////////////////////
// Props
//////////////////////////////////////////////////////////////////////////

  public Object prop(Elem self, String name)
  {
    if (propHooks.get(name) != null)
    {
      // return "" for null id to match js
      if (name.equals("id")) { Object v=props.get("id"); return v==null ? "" : v; }
    }

    return props.get(name);
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

  public Object invoke(String name, List args) { throw err(); }

//////////////////////////////////////////////////////////////////////////
//Layout
//////////////////////////////////////////////////////////////////////////

// cannot compile against "web" pod - see https://fantom.org/forum/topic/2886
// public Point pos       (Elem self) { throw err(); }
// public Point pagePos   (Elem self) { throw err(); }
// public Size  size      (Elem self) { throw err(); }
// public Point scrollPos (Elem self) { throw err(); }
// public Size  scrollSize(Elem self) { throw err(); }

  public Elem scrollIntoView(Elem self, boolean alignToTop) { throw err(); }

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
    return (Elem)querySelectorAll(self, selectors).first();
  }

  public List querySelectorAll(Elem self, String selectors)
  {
    QuerySelector q = QuerySelector.parse(selectors);
    ArrayList matches = new ArrayList();
    matchQuerySelector(self, q, matches);
    return Interop.toFan(matches, Type.find("dom::Elem"));
  }

  private void matchQuerySelector(Elem parent, QuerySelector q, ArrayList matches)
  {
    List kids = parent.children();
    for (int i=0; i<kids.size(); i++)
    {
      Elem elem = (Elem)kids.get(i);

      // TODO: match on tag name and/or class name

      // check attrs
      Map attrs = elem.attrs();
      for (int j=0; j<attrs.keys().size(); j++)
      {
        String key = (String)attrs.keys().get(j);
        String val = (String)attrs.get(key);
        if (q.attrs.contains(key)) matches.add(elem);
        // TODO: match on value
      }

      // recurse children
      matchQuerySelector(elem, q, matches);
    }
  }

//////////////////////////////////////////////////////////////////////////
// Events
//////////////////////////////////////////////////////////////////////////

  public boolean hasFocus(Elem self) { throw err(); }
  public void    focus   (Elem self) { throw err(); }
  public void    blur    (Elem self) { throw err(); }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private static final Uri defns = Uri.fromStr("http://www.w3.org/1999/xhtml");

  private boolean isSvg = false;

  private Uri ns;                             // non-null
  private String tagName;                     // non-null
  private Style style;                        // null
  private boolean enabled = true;
  private HashMap props = new HashMap();      // Str:Obj

  private static Err err() { return UnsupportedErr.make(); }
}

