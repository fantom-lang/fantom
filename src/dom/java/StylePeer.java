//
// Copyright (c) 2017, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 May 2017  Andy Frank  Creation
//

package fan.dom;

import java.util.ArrayList;
import java.util.HashMap;
import fan.sys.*;
import fanx.interop.*;

public class StylePeer
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  public static StylePeer make(Style fan)
  {
    return DomPeerFactory.factory().makeStyle(fan);
  }

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  public List classes(Style self) { return Interop.toFan(classList); }

  public boolean hasClass(Style self, String name)
  {
    return classList.contains(name);
  }

  // for Elem.setAttr("class", ...) support
  public void _setClass(Style self, String name)
  {
    classList.clear();
    addClass(self, name);
  }

  public Style addClass(Style self, String name)
  {
    // for compatibility with js (pass multiple space separated classes)
    String[] list = name.split("\\s+");
    for (int i=0; i<list.length; i++)
    {
      String n = list[i];
      if (n.length() == 0) continue;
      if (!classList.contains(n)) classList.add(n);
    }
    return self;
  }

  public Style removeClass(Style self, String name)
  {
    int i = classList.indexOf(name);
    if (i >= 0) classList.remove(i);
    return self;
  }

  Style clear(Style self) { throw err(); }

  Object computed(Style self, String name) { throw err(); }

  Object effective(Style self, String name) { throw err(); }

  public Object get(Style self, String name)
  {
    return props.get(name);
  }

  public void setProp(Style self, String name, String val)
  {
    if (val == null) props.remove(name);
    else props.put(name, val);
  }

  private static Err err() { return UnsupportedErr.make(); }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private ArrayList classList = new ArrayList();
  private HashMap props = new HashMap();
}