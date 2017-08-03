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

public class ElemPeer
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  public static ElemPeer make(Elem fan)
  {
    return new ElemPeer();
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

  public String text(Elem self) { return this.text; }
  public void text(Elem self, String text) { this.text = text; }

  // TODO: need to serialize all children into <html> format?
  // public String html(Elem self) { return ...; }
  // public void html(Elem self, String html) { ... }

  public boolean enabled(Elem self) { return enabled; }
  public void enabled(Elem self, boolean v) { this.enabled = v; }

//////////////////////////////////////////////////////////////////////////
// Attributes
//////////////////////////////////////////////////////////////////////////

  public Map attrs(Elem self)
  {
    Map map = new Map(new MapType(Sys.StrType, Sys.StrType));
    Iterator it = props.entrySet().iterator();
    while (it.hasNext())
    {
      Entry e = (Entry)it.next();
      map.set(e.getKey(), e.getValue().toString());
    }
    return map;
  }

  public String attr(Elem self, String name)
  {
    // do not route to prop to avoid propHooks traps
    Object val = props.get(name);
    return val == null ? null : val.toString();
  }

  public Elem setAttr(Elem self, String name, String val, Uri ns)
  {
    // TODO: ns?
    // route to setProp
    this.setProp(self, name, val==null ? null : val.toString());
    return self;
  }

  public Elem removeAtrr(Elem self, String name)
  {
    // route to setProp
    this.setProp(self, name, null);
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

//////////////////////////////////////////////////////////////////////////
// Tree
//////////////////////////////////////////////////////////////////////////

  public Elem parent(Elem self)
  {
    return this.parent;
  }

  public boolean hasChildren(Elem self)
  {
    return kids.size() > 0;
  }

  public List children(Elem self)
  {
    return Interop.toFan(kids, self.typeof());
  }

  public Elem firstChild(Elem self)
  {
    if (kids.size() == 0) return null;
    return (Elem)kids.get(0);
  }

  public Elem lastChild(Elem self)
  {
    if (kids.size() == 0) return null;
    return (Elem)kids.get(kids.size()-1);
  }

  public Elem prevSibling(Elem self)
  {
    if (parent == null) return null;
    int i = parent.peer.kids.indexOf(self);
    return i == 0 ? null : (Elem)parent.peer.kids.get(i-1);
  }

  public Elem nextSibling(Elem self)
  {
    if (parent == null) return null;
    int i = parent.peer.kids.indexOf(self);
    return i == parent.peer.kids.size()-1 ? null : (Elem)parent.peer.kids.get(i+1);
  }

  public boolean containsChild(Elem self, Elem elem)
  {
    return kids.contains(elem);
  }

  public void addChild(Elem self, Elem child)
  {
    if (child.parent() != null) throw new RuntimeException("child already parented");
    child.peer.parent = self;
    kids.add(child);
  }

  public void insertChildBefore(Elem self, Elem child, Elem ref)
  {
    if (child.parent() != null) throw new RuntimeException("child already parented");
    int i = kids.indexOf(ref);
    if (i < 0) throw new RuntimeException("ref not a child of this element");
    child.peer.parent = self;
    kids.add(i, child);
  }

  public void replaceChild(Elem self, Elem oldChild, Elem newChild)
  {
    if (newChild.parent() != null) throw new RuntimeException("child already parented");
    int i = kids.indexOf(oldChild);
    if (i < 0) throw new RuntimeException("oldChild not a child of this element");
    oldChild.peer.parent = null;
    newChild.peer.parent = self;
    kids.set(i, newChild);
  }

  public void removeChild(Elem self, Elem child)
  {
    child.peer.parent = null;
    kids.remove(child);
  }

//////////////////////////////////////////////////////////////////////////
// Events
//////////////////////////////////////////////////////////////////////////

  public Func onEvent(Elem self, String type, boolean useCapture, Func handler)
  {
    // ignore
    return handler;
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private static final Uri defns = Uri.fromStr("http://www.w3.org/1999/xhtml");

  private boolean isSvg = false;

  private Uri ns;                             // non-null
  private String tagName;                     // non-null
  private String text = "";                   // non-null
  private Style style;                        // null
  private boolean enabled = true;
  private HashMap props = new HashMap();      // Str:Obj
  private Elem parent;                        // null
  private ArrayList kids = new ArrayList();
}