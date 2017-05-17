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
    this.ns = ns;
  }

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  public String tagName(Elem self) { return this.tagName; }

  public String id(Elem self) { return this.id; }
  public void id(Elem self, String id) { this.id = id; }

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

  public Map attrs(Elem self)
  {
    Map map = new Map(new MapType(Sys.StrType, Sys.ObjType));
    Iterator it = attrs.entrySet().iterator();
    while (it.hasNext())
    {
      Entry e = (Entry)it.next();
      map.set(e.getKey(), e.getValue().toString());
    }
    return map;
  }

  public Object doGet(Elem self, String name, boolean isTrap)
  {
    if (isTrap) name = fromCamel(name);
    return attrs.get(name);
  }

  public void doSet(Elem self, String name, Object val, boolean isTrap)
  {
    if (isTrap) name = fromCamel(name);
    if (val == null) attrs.remove(name);
    else attrs.put(name, val);
  }

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
// Fields
//////////////////////////////////////////////////////////////////////////

  private static String fromCamel(String s)
  {
    StringBuffer h = new StringBuffer();
    for (int i=0; i<s.length(); i++)
    {
      char ch = s.charAt(i);
      if (ch >= 'A' && ch <= 'Z') h.append('-').append((char)FanInt.lower(ch));
      else h.append(ch);
    }
    return h.toString();
  }

  private String tagName;    // non-null
  private Uri ns;            // null
  private String id = "";    // non-null
  private String text = "";  // non-null
  private Style style;       // null
  private HashMap attrs = new HashMap();

  private Elem parent;       // null
  private ArrayList kids = new ArrayList();
}