//
// Copyright (c) 2017, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 May 2017  Andy Frank  Creation
//

package fan.dom;

import fan.sys.*;

public class EventPeer
{
  public static EventPeer make(Event fan)
  {
    return DomPeerFactory.factory().makeEvent(fan);
  }

  static public Event makeMock() { return makeCustom("mock", null); }

  // Init takes "bubbles" and "cancelable" as the DOM does; every
  // other entry is an attribute of the event such as "keyCode",
  // "key", "shiftKey", "button", "relatedTarget" or "detail"
  static public Event makeCustom(String type, Map init)
  {
    Event x = Event.make();
    EventPeer p = x.peer;
    p.type = type;
    if (init != null)
    {
      p.attrs.putAll(init.toJava());
      p.bubbles    = p.flag("bubbles");
      p.cancelable = p.flag("cancelable");
    }
    return x;
  }

  static public Event fromNative(Object event)
  {
    return DomPeerFactory.factory().eventFromNative(event);
  }

  public Object       toNative    (Event self)                          { throw err(); }
  public String       type        (Event self)                          { return type; }
  public DomNode      targetNode  (Event self)                          { return target; }
  public Elem         relatedTarget(Event self)                         { return (Elem)attrs.get("relatedTarget"); }
  public boolean      alt         (Event self)                          { return flag("altKey"); }
  public boolean      ctrl        (Event self)                          { return flag("ctrlKey"); }
  public boolean      shift       (Event self)                          { return flag("shiftKey"); }
  public boolean      meta        (Event self)                          { return flag("metaKey"); }
  public Long         button      (Event self)                          { return (Long)attrs.get("button"); }
  public String       keyChar     (Event self)                          { return (String)attrs.get("key"); }
  public Object       detail      (Event self)                          { return attrs.get("detail"); }
  public Err          err         (Event self)                          { return (Err)attrs.get("error"); }
  public void         preventDefault(Event self)                        { defaultPrevented = true; }
  public void         stop        (Event self)                          { defaultPrevented = true; stopped = true; }
  public void         set         (Event self, String name, Object val) { attrs.put(name, val); }
  public Object       data        (Event self)                          { return attrs.get("data"); }

  public DataTransfer dataTransfer(Event self)
  {
    if (dataTransfer == null) dataTransfer = DataTransfer.make();
    return dataTransfer;
  }

  // a text node target maps to its parent element
  public Elem target(Event self)
  {
    return target instanceof Elem ? (Elem)target : target.parent();
  }

  public Key key(Event self)
  {
    Long code = (Long)attrs.get("keyCode");
    return code == null ? null : Key.fromCode(code.longValue());
  }

  public Object get(Event self, String name, Object def)
  {
    Object val = attrs.get(name);
    return val != null ? val : def;
  }

  private boolean flag(String name) { return Boolean.TRUE.equals(attrs.get(name)); }

// cannot compile against "graphics" pod - see https://fantom.org/forum/topic/2886
// public Point       pagePos     (Event self)                          { throw err(); }
// public Point       delta       (Event self)                          { throw err(); }

  private static Err err() { return UnsupportedErr.make(); }

  String type;                        // non-null
  DomNode target;                     // null until dispatched
  boolean bubbles;
  boolean cancelable;
  boolean defaultPrevented;
  boolean stopped;
  private DataTransfer dataTransfer;
  private java.util.HashMap attrs = new java.util.HashMap();   // Str:Obj
}

